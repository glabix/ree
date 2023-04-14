require 'thread'

module ThreadParent
  class Parents

    def initialize(child)
      @child = child
    end

    def [](key)
      if @child.key?(key)
        @child[key]
      elsif @child.parent
        @child.parent.parents[key]
      end
    end
  end
end

class Thread

  alias_method :_initialize, :initialize

  def initialize(*args, &block)
    @_parent = Thread.current
    _initialize(*args, &block)
  end

  def parent
    @_parent
  end

  def parents
    ThreadParent::Parents.new(self)
  end

  def self.parents
    ThreadParent::Parents.new(Thread.current)
  end
end