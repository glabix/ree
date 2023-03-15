class ReeRoda::BuildRoutingTree
  include Ree::FnDSL

  fn :build_routing_tree do
  end

  class RoutingTree
    attr_accessor :children, :value, :depth, :actions, :parent
  
    def initialize(value, depth, parent = nil, actions = [])
      @value = value
      @parent = parent
      @depth = depth
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
  end

  contract(ArrayOf[ReeActions::Action] => Nilor[RoutingTree])
  def call(actions)
    tree = nil
    actions.each do |action|
      splitted = action.path.split("/")

      splitted.each_with_index do |v, j|
        if tree.nil?
          tree = RoutingTree.new(v, j)
          next
        end

        current = tree.find_by_value(value: v, depth: j)
        if current
          parent = tree.find_by_value(value: splitted[j-1], depth: j-1)
          if parent && !parent.children_have_value?(v)
            newTree = parent.add_child(v, j)
            newTree.actions << action if j == (splitted.length - 1)
            next
          end

          current.add_action(action) if j == (splitted.length - 1)
        else
          parent = tree.find_by_value(value: splitted[j-1], depth: j-1)
          if parent && !parent.children_have_value?(v)
            newTree = parent.add_child(v, j)
            newTree.add_action(action) if j == (splitted.length - 1)
          end
        end
      end
    end
    
    tree
  end
end