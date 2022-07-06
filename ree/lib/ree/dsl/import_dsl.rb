# frozen_string_literal  = true

class Ree::ImportDsl
  def execute(klass, proc)
    self.class.instance_exec(&proc)
  rescue Ree::ImportDsl::UnlinkConstError => e
    const_removed = remove_const(klass, e.const)

    retry if const_removed
  rescue NoMethodError => e
    if e.name == :&
      const_removed = remove_const(klass, e.receiver)

      if const_removed
        retry
      else
        raise Ree::Error.new("'#{e.receiver}' already linked or defined in '#{klass}'", :invalid_dsl_usage)
      end
    else
      raise e
    end
  rescue NameError => e
    proc
      .binding
      .eval("#{e.name} = Ree::ImportDsl::ClassConstant.new('#{e.name}')")

    retry
  end

  class UnlinkConstError < StandardError
    attr_reader :const
    
    def initialize(const)
      @const = const
    end
  end

  class ClassConstant
    attr_reader :name, :constants

    def initialize(name)
      @name = name
      @as = nil
      @constants = []
    end

    def &(obj)
      if !obj.is_a?(ClassConstant)
        raise Ree::ImportDsl::UnlinkConstError.new(obj)
      end

      new_obj = if obj.is_a?(Class)
        ClassConstant.new(obj.to_s.split("::").last)
      else
        obj
      end

      return self if @constants.detect { |_| _.name == new_obj.name }
      @constants.push(new_obj)

      self
    end

    def get_as
      @as
    end

    def as(obj)
      if !obj.is_a?(ClassConstant)
        raise Ree::ImportDsl::UnlinkConstError.new(obj)
      end

      @as = if obj.is_a?(Class)
        ClassConstant.new(obj.to_s.split("::").last)
      else
        obj
      end

      self
    end
  end

  private

  def remove_const(klass, constant)
    const_removed = false

    klass.constants.each do |const_sym|
      const = klass.const_get(const_sym)

      if constant.is_a?(Class) || constant.is_a?(Module)
        if (const.is_a?(Class) || const.is_a?(Module)) && const.name == constant.name
          klass.send(:remove_const, const_sym)
          const_removed = true
          break
        end
      elsif const == constant
        klass.send(:remove_const, const_sym)
        const_removed = true
        break
      end
    end

    const_removed
  end
end
