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
      puts "#{get_offset(tree.depth)}#{tree.values.inspect} - #{tree.depth}"

      if tree.children.length > 0
        tree.children.each do |child|
          print_tree(child)
        end
      end

      nil
    end

    def print_proc_tree(tree = self)
      param_value = tree.values[0].start_with?(":") ? String : "\"#{tree.values[0]}\""

      if tree.routes.length == 0
        if tree.children.length > 0
          puts "#{get_offset(tree.depth)}r.on #{param_value} do"

          tree.children.each do |child|
            print_proc_tree(child)
          end

          puts "#{get_offset(tree.depth)}end"
        end

        nil
      else
        if tree.children.length > 0
          puts "#{get_offset(tree.depth)}r.on #{param_value} do"

          tree.children.each do |child|
            print_proc_tree(child)
          end

          tree.routes.each do |route|
            puts "#{get_offset(tree.depth + 1)}r.#{route.request_method} do"
            puts "#{get_offset(tree.depth + 1)}end"
          end

          puts "#{get_offset(tree.depth)}end"
        else
          puts "#{get_offset(tree.depth)}r.is #{param_value} do"

          tree.routes.each do |route|
            puts "#{get_offset(tree.depth + 1)}r.#{route.request_method} do"
            puts "#{get_offset(tree.depth + 1)}end"
          end

          puts "#{get_offset(tree.depth)}end"
        end
      end

      nil
    end

    private

    def get_offset(depth)
      " " * (depth + 1) * 2
    end
  end

  contract(ArrayOf[ReeRoutes::Route] => Nilor[RoutingTree])
  def call(routes)
    tree = nil

    routes.each do |route|
      splitted = route.path.split("/")
      parent_tree = tree

      splitted.each_with_index do |v, j|
        if tree.nil?
          tree = RoutingTree.new([v], j, :string)
          parent_tree = tree
          next
        end

        current = parent_tree.find_by_value(value: v, depth: j)

        if current
          parent_tree = current
          current.add_route(route) if j == (splitted.length - 1)
        else
          if !parent_tree.any_child_has_value?(v)
            if parent_tree.children.any? { |c| c.type == :param } && v.start_with?(":")
              param_child = parent_tree.children.find { |c| c.type == :param }
              param_child.values << v if !param_child.values.include?(v)
              param_child.add_route(route) if j == (splitted.length - 1)
              parent_tree = param_child

              next
            end

            new_tree = parent_tree.add_child(v, j, v.start_with?(":") ? :param : :string)
            parent_tree = new_tree
          end

          parent_tree.add_route(route) if j == (splitted.length - 1)
        end
      end
    end

    tree
  end
end