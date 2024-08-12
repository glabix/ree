require_relative "./collection_filter"

class ReeDto::DtoCollection
  include Enumerable

  LoadError = Class.new(ArgumentError)

  attr_reader :name, :contract, :parent_class

  contract Symbol, Any, Any => Any
  def initialize(name, contract, parent_class)
    @parent_class = parent_class
    @contract = contract
    @name = name
    @list = []
  end

  contract Optblock => Any
  def each(&block)
    @list.each(&block)
  end

  contract None => Integer
  def size
    @list.size
  end

  class << self
    def filter(name, filter_proc)
      define_method name do
        ReeDto::CollectionFilter.new(self, name, filter_proc)
      end
    end
  end
end