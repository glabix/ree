# frozen_string_literal: true

class Ree::ImportDsl
  def initialize
    setup_removed_constants
  end

  def execute(klass, proc)
    patch_const_missing
    
    class_constant = self.class.instance_exec(&proc)

    [
      extract_constants(class_constant),
      get_removed_constants
    ]
  rescue Ree::ImportDsl::UnlinkConstError => e
    retry_after = remove_or_assign_const(klass, e.const)
    retry if retry_after
  rescue NoMethodError => e
    if e.name == :& || e.name == :as
      retry_after = remove_or_assign_const(klass, e.receiver)
      retry if retry_after
    else
      raise e
    end
  rescue NameError => e
    proc
      .binding
      .eval("#{e.name} = Ree::ImportDsl::ConstantContextBuilder.get_context('#{e.name}')")

    retry
  ensure
    cancel_patch_const_missing
  end

  def patch_const_missing
    return if @_original_const_missing
    @_original_const_missing = Module.instance_method(:const_missing)
    Module.define_method(:const_missing){ |const_name| raise NameError.new("class not found #{const_name.to_s}", const_name) }
  end

  def cancel_patch_const_missing
    Module.define_method(:const_missing, @_original_const_missing)
    @_original_const_missing = nil
  end
  
  private def extract_constants(class_constant)
    [class_constant] + class_constant.constants
  end

  private def setup_removed_constants
    self.class.instance_variable_set(:@removed_constants, [])
  end

  private def get_removed_constants
    self.class.instance_variable_get(:@removed_constants)
  end

  class RemovedConstant
    attr_reader :name, :const

    def initialize(name, const)
      @name = name
      @const = const
    end
  end

  class UnlinkConstError < StandardError
    attr_reader :const

    def initialize(const)
      @const = const
    end
  end

  class ConstantContextBuilder
    def self.get_context(name, module_name = nil)
      context = Class.new(ConstantContext)
      context.instance_variable_set(:@name, name)     
      context.instance_variable_set(:@module_name, module_name)     
      context.instance_variable_set(:@as, nil)     
      context.instance_variable_set(:@constants, [])     
      context    
    end
  end

  class ConstantContext
    class << self
      def const_missing(const_name)
        ConstantContextBuilder.get_context(const_name, name)
      end

      def name
        @name
      end

      def module_name
        @module_name
      end

      def get_as
        @as
      end

      def constants
        @constants
      end

      def as(obj)
        if !obj.is_a?(Class)
          raise Ree::ImportDsl::UnlinkConstError.new(obj)
        end

        @as = if has_context_ancestor?(obj)
          obj
        else
          ConstantContextBuilder.get_context(obj.to_s.split("::").last)
        end

        self
      end

      def &(obj)
        if !obj.is_a?(Class)
          raise Ree::ImportDsl::UnlinkConstError.new(obj)
        end

        new_obj = if has_context_ancestor?(obj)
          obj
        else
          ConstantContextBuilder.get_context(obj.to_s.split("::").last)
        end

        return self if @constants.detect { |_| _.name == new_obj.name }
        @constants.push(new_obj)

        self
      end

      def has_context_ancestor?(obj)
        return false unless obj.is_a?(Class)
        obj.ancestors.include?(ConstantContext)
      end
    end
  end 

  private

  def remove_or_assign_const(klass, constant)
    retry_after = false

    klass.constants.each do |const_sym|
      const = klass.const_get(const_sym)
      next if ConstantContext.has_context_ancestor?(const)

      if constant.is_a?(Class) || constant.is_a?(Module)
        if (const.is_a?(Class) || const.is_a?(Module)) && const.name == constant.name
          klass.send(:remove_const, const_sym)
          store_removed_constant(const_sym, constant)

          retry_after = true
          break
        end
      elsif const == constant
        klass.send(:remove_const, const_sym)
        store_removed_constant(const_sym, constant)

        retry_after = true
        break
      end
    end

    return true if retry_after

    const_name = if constant.is_a?(String)
      constant.to_sym
    elsif constant.is_a?(Class) || constant.is_a?(Module)
      constant.name
    else
      raise ArgumentError.new("unknown constant: #{constant.inspect}")
    end

    if parent_constant?(klass, const_name)
      klass.const_set(const_name, ConstantContextBuilder.get_context(const_name.to_s))
      retry_after = true
    end

    retry_after
  end

  private

  def store_removed_constant(name, constant)
    return if ConstantContext.has_context_ancestor?(constant)
    get_removed_constants << RemovedConstant.new(name, constant.dup)
  end

  def parent_constant?(klass, const_name)
    modules = klass.to_s.split("::")[0..-2]

    result = modules.each_with_index.any? do |mod, index|
      mod = Object.const_get(modules[0..index].join("::"))
      mod.constants.include?(const_name)
    end

    result || acnchestor_constant?(klass, const_name)
  end

  def acnchestor_constant?(klass, const_name)
    return false if klass.ancestors.include?(klass) && klass.ancestors.size == 1

    klass.ancestors.any? do |anchestor|
      next if anchestor == klass
      anchestor.constants.include?(const_name) || acnchestor_constant?(anchestor, const_name)
    end
  end
end
