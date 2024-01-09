# frozen_string_literal: true

class Ree::Object
  attr_reader :name, :rpath, :schema_rpath, :package_name, :klass,
              :package_name, :factory, :after_init,
              :class_name, :links, :mount_as, :freeze,
              :errors, :linked_const_list, :compiled_frozen,
              :singleton, :tags

  # @param [Symbol] name Object name
  # @param [String] schema_rpath Object schema path relative to project root dir
  # @param [String] rpath Object source file path relative to project root dir
  def initialize(name, schema_rpath, rpath)
    @name = name
    @schema_rpath = schema_rpath
    @rpath = rpath
    @links = []
    @errors = []
    @loaded = false
    @freeze = true
    @compiled = false
    @singleton = false
    @compiled_frozen = @freeze
    @linked_const_list = []
    @tags = []
  end

  def reset
    @compiled = false
    @singleton = false
    @loaded = false
    @factory = nil
    @after_init = nil
    @freeze = true
    @links = []
    @errors = []
    @linked_const_list = []
  end

  # @param [ArrayOf[String]] list List of imported constants, modules and classes
  # @return [ArrayOf[String]] All imported constants
  def add_const_list(list)
    @linked_const_list += list
    @linked_const_list.uniq
  end

  # @param [Bool]
  def set_as_compiled(frozen)
    @compiled = true
    @compiled_frozen = frozen
  end

  def set_as_not_compiled
    @compiled = false
    @compiled_frozen = @freeze
  end

  def compiled?
    @compiled
  end

  def factory?
    !!@factory
  end

  def after_init?
    !!@after_init
  end

  def set_loaded
    @loaded = true
  end

  def loaded?
    @loaded
  end

  def freeze?
    @freeze
  end

  # @param [Symbol] val Object mount as type (:fn or :bean)
  def set_mount_as(val)
    @mount_as = val; self
  end

  # @param [Bool]
  def set_freeze(val)
    @freeze = val; self
  end

  def set_as_singleton
    @singleton = true; self
  end

  def object?
    @mount_as == :object
  end

  def fn?
    @mount_as == :fn
  end

  # @param [String] rpath Object source file path relative to project root dir
  def set_rpath(val)
    @rpath = val; self
  end

  # @param [String] schema_rpath Object schema path relative to project root dir
  def set_schema_rpath(val)
    @schema_rpath = val; self
  end

  # @param [Class] Object class
  def set_class(klass)
    @klass = klass; @class_name = klass.to_s; self
  end

  # @param [Symbol] Package name
  def set_package(val)
    @package_name = val; self
  end

  # @param [Symbol] Factory method name
  def set_factory(val)
    @factory = val; self
  end

  # @param [Symbol] After init method name
  def set_after_init(val)
    @after_init = val; self
  end

  def add_tags(list)
    @tags += list
    @tags.uniq!
  end
end