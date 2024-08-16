class ReeDto::CollectionFilter
  include Ree::Contracts::Core
  include Ree::Contracts::ArgContracts
  include Enumerable
  extend Forwardable

  InvalidFilterItemErr = Class.new(ArgumentError)

  def_delegators *([:all] + Array.public_instance_methods - Object.public_instance_methods)

  contract Any, Symbol, Proc => Any
  def initialize(collection, name, filter_proc)
    @collection = collection
    @name = name
    @filter_proc = filter_proc
  end

  contract Optblock => Any
  def each(&block)
    @collection.select(&@filter_proc).each(&block)
  end

  def all
    @collection.select(&@filter_proc)
  end

  contract Any => Any
  def add(item)
    check_item(item)
    @collection.add(item)
  end

  def inspect
    to_a.inspect
  end

  contract Any => Any
  def remove(item)
    check_item(item)
    @collection.remove(item)
  end

  alias :<< :add
  alias :push :add

  private

  def check_item(item)
    if !@filter_proc.call(item)
      raise InvalidFilterItemErr.new(
        "invalid item for #{@collection.parent_class}##{@name} filter"
      )
    end
  end
end
