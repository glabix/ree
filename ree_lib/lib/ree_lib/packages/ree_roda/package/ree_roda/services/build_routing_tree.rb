class ReeRoda::BuildRoutingTree
  include Ree::FnDSL

  fn :build_routing_tree

  class RoutingTree
    attr_accessor :children, :value, :depth, :actions, :parent
  
    def initialize(value, depth, parent = nil, actions = [])
      @value = value
      @depth = depth
      @parent = parent
      @actions = []
      @children = []
    end
  
    def find_by_value(
      tree: self,
      value: nil,
      depth: 0
    )
      return tree if tree.depth == depth && tree.value == value
      if tree.depth < depth
        res = tree.children.map do |c|
          find_by_value(tree: c, value: value, depth: depth)
        end.flatten.compact

        return res.size > 1 ? res : res.first
      end
    end

    def children_have_value?(value)
      !!self.children.find { |c| c.value == value }
    end

    def add_child(value, depth)
      new_child = self.class.new(value, depth, self.value)
      self.children << new_child
      self.children = self.children.sort { _1.value.match?(/\:/) ? 1 : 0 }

      return new_child
    end

    def add_action(action)
      self.actions << action
    end

    def print_tree(tree = self)
      puts "#{get_offset(tree.depth)}#{tree.value} - #{tree.depth}"
      if tree.children.length > 0
        tree.children.each do |child|
          print_tree(child)
        end
      end

      nil
    end

    private

    def get_offset(depth)
      " " * (depth + 1) * 2
    end
  end

  contract(ArrayOf[ReeActions::Action] => Nilor[RoutingTree])
  def call(actions)
    tree = nil
    actions.each do |action|
      splitted = action.path.split("/")

      parentTree = tree
      splitted.each_with_index do |v, j|
        if tree.nil?
          tree = RoutingTree.new(v, j)
          parentTree = tree
          next
        end

        current = parentTree.find_by_value(value: v, depth: j)
        if current
          parentTree = current

          current.add_action(action) if j == (splitted.length - 1)
        else
          if !parentTree.children_have_value?(v)
            newTree = parentTree.add_child(v, j)
            parentTree = newTree
          end

          parentTree.add_action(action) if j == (splitted.length - 1)
        end
      end
    end
    
    tree
  end
end