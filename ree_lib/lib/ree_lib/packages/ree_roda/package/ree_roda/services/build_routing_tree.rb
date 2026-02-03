class ReeRoda::BuildRoutingTree
  include Ree::FnDSL

  fn :build_routing_tree do
    link "ree_routes/route", -> { Route }
  end

  class RoutingTree
    attr_accessor :children, :values, :depth, :routes, :type, :parent

    contract ArrayOf[String], Integer, Or[:param, :string], Nilor[self], ArrayOf[Route] => Any
    def initialize(values, depth, type, parent = nil, routes = [])
      @values = values
      @depth = depth
      @parent = parent
      @type = type
      @routes = []
      @children = []
    end

    contract(Kwargs[
      tree: self,
      value: Nilor[String],
      type: Or[:param, :string],
      depth: Integer] => Or[self, nil, ArrayOf[self]]
    )
    def find_by_value(tree: self, value: nil, type: :param, depth: 0)
      return tree if tree.depth == depth && tree.values.include?(value)

      if tree.depth < depth
        res = tree
          .children
          .map { find_by_value(tree: _1, value: value, type: type, depth: depth) }
          .flatten
          .compact

        res.size > 1 ? res : res.first
      end
    end

    contract String => Bool
    def any_child_has_value?(value)
      !!self.children.find { |c| c.values.include?(value) }
    end

    contract String, Integer, Or[:param, :string] => self
    def add_child(value, depth, type)
      new_child = self.class.new([value], depth, type, self)

      self.children << new_child
      self.children = self.children.sort { _1.values[0].match?(/\:/) ? 1 : 0 }

      return new_child
    end

    contract Route => nil
    def add_route(route)
      self.routes << route; nil
    end

    def print_tree(tree = self)
      if tree.is_a?(Array)
        puts "Multiple trees:"
        tree.each_with_index do |t, i|
          puts "\nTree #{i + 1}:"
          print_tree(t)
        end
        return nil
      end

      puts "#{get_offset(tree.depth)}#{tree.values.inspect} - depth: #{tree.depth}, type: #{tree.type}"

      if tree.routes.any?
        tree.routes.each do |route|
          puts "#{get_offset(tree.depth + 1)}- #{route.request_method} #{route.path}"
          puts "#{get_offset(tree.depth + 2)}  summary: #{route.summary}"
          puts "#{get_offset(tree.depth + 2)}  override: #{route.override ? 'YES' : 'NO'}"
        end
      end

      if tree.children.length > 0
        tree.children.each do |child|
          print_tree(child)
        end
      end

      nil
    end

    def print_proc_tree(tree = self, is_root_array: false)
      if tree.is_a?(Array)
        puts "Multiple root trees found:"
        tree.each_with_index do |t, i|
          puts "\nTree #{i + 1}:"
          print_proc_tree(t)
        end
        return nil
      end

      if tree.depth == 0
        param_value = tree.values[0].start_with?(":") ? String : "\"#{tree.values[0]}\""

        puts "r.on #{param_value} do"

        tree.children.each do |child|
          print_proc_tree(child)
        end

        if tree.routes.any?
          puts "  r.is do"
          tree.routes.each do |route|
            puts "    r.#{route.request_method} do"
            if route.override
              puts "      # OVERRIDE: custom logic"
              puts "      # Summary: #{route.summary}"
            else
              puts "      # Action: #{route.action&.name}"
              puts "      # Serializer: #{route.serializer&.name}" if route.serializer
              puts "      # Warden scope: #{route.warden_scope}"
            end
            puts "    end"
          end
          puts "  end"
        end

        puts "end"

      else
        has_arbitrary_param = tree.values[0].start_with?(":")
        param_value = has_arbitrary_param ? String : "\"#{tree.values[0]}\""

        indent = "  " * tree.depth

        if tree.children.length > 0 || tree.routes.length > 0
          puts "#{indent}r.on #{param_value} do"


          tree.children.each do |child|
            print_proc_tree(child)
          end

          if tree.routes.any?
            puts "#{indent}  r.is do"
            tree.routes.each do |route|
              puts "#{indent}    r.#{route.request_method} do"
              if route.override
                puts "#{indent}      # OVERRIDE: custom logic"
                puts "#{indent}      # Summary: #{route.summary}"
              else
                puts "#{indent}      # Action: #{route.action&.name}"
                puts "#{indent}      # Serializer: #{route.serializer&.name}" if route.serializer
                puts "#{indent}      # Warden scope: #{route.warden_scope}"
              end
              puts "#{indent}    end"
            end
            puts "#{indent}  end"
          end

          puts "#{indent}end"
        end
      end

      nil
    end

    private

    def get_offset(depth)
      " " * (depth + 1) * 2
    end
  end

  contract(ArrayOf[ReeRoutes::Route] => ArrayOf[RoutingTree])
  def call(routes)
    trees = []

    routes.each do |route|
      splitted = route.path.split("/").reject(&:empty?)
      matched_tree = nil

      root_part = splitted[0]

      # find tree for root segment
      trees.each do |tree|
        if tree.values.include?(root_part)
          matched_tree = tree
          break
        end
      end

      if matched_tree.nil?
        # create new tree for root
        matched_tree = RoutingTree.new([root_part], 0, :string)
        trees << matched_tree
      end

      parent_tree = matched_tree

      # process other parts
      splitted[1..-1].each_with_index do |v, i|
        current = parent_tree.find_by_value(value: v, depth: i+1)

        if current
          parent_tree = current
        else
          # check if we can add it to existing param node
          if parent_tree.children.any? { |c| c.type == :param } && v.start_with?(":")
            param_child = parent_tree.children.find { |c| c.type == :param }
            param_child.values << v if !param_child.values.include?(v)
            parent_tree = param_child
          else
            new_tree = parent_tree.add_child(v, i+1, v.start_with?(":") ? :param : :string)
            parent_tree = new_tree
          end
        end
      end

      parent_tree.add_route(route)
    end

    trees
  end
end
