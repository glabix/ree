class ReeRoda::BuildRoutingTree
  include Ree::FnDSL

  fn :build_routing_tree do
  end

  class RoutingTree
    attr_accessor :children, :value, :depth, :actions
  
    def initialize(value, depth, actions = [])
      @value = value
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
        tree.children.map do |c|
          find_by_value(tree: c, value: value, depth: depth)
        end.flatten.compact.first
      end
    end
  end

  contract(ArrayOf[ReeActions::Action] => Nilor[RoutingTree])
  def call(actions)
    tree = nil
    actions.each do |action|
      splitted = action.path.split("/")
      
      parent = tree
      splitted.each_with_index do |v, j|
        if tree.nil?
          tree = RoutingTree.new(v, j)
          parent = tree
          next
        end

        current = tree.find_by_value(value: v, depth: j)
        if current
          parent = current
          current.actions << action if j == (splitted.length - 1)
          next
        else
          parent = tree.find_by_value(value: splitted[j-1], depth: j-1)
          if parent && !parent.children.find { |c| c.value == v }
            newTree = RoutingTree.new(v, j)
            parent.children << newTree
            parent = newTree

            newTree.actions << action if j == (splitted.length - 1)
          end
        end
      end
    end
    
    tree
  end
end