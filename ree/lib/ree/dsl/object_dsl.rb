# frozen_string_literal: true

require 'pathname'

class Ree::ObjectDsl
  include Ree::Args

  attr_reader :package, :object

  # @param [Ree::PackagesFacade] packages_facade
  # @param [Class] klass
  # @param [Symbol] name
  # @param [Nilor[String]] abs_path
  # @param [Symbol] mount_as
  def initialize(packages_facade, klass, name, mount_as)
    @packages_facade = packages_facade

    @object = register_object(
      klass, name, mount_as,
    )

    @package = @packages_facade.get_loaded_package(@object.package_name)

    if @package.default_links
      instance_exec(&@package.default_links)
    end
  end

  # Proxy method for link_object & link_file
  # 
  def link(*args, **kwargs)
    if args.first.is_a?(Symbol)
      if args.size > 1
        link_multiple_objects(args, **kwargs)
      else
        link_object(*args, **kwargs)
      end
    elsif args.first.is_a?(String)
      link_file(args[0], args[1])
    else
      raise_error("Invalid link DSL usage. Args should be Hash or String")
    end
  end

  def tags(list)
    @object.add_tags(list)
  end

  def import(*args, **kwargs)
    if args.first.is_a?(Symbol) # import from ree object
      _import_from_object(*args, **kwargs)
    else
      _import_object_consts(*args, **kwargs)
    end
  end

  # @param [Symbol] object_name
  # @param [Nilor[Symbol]] as
  # @param [Nilor[Symbol]] from
  # @param [Nilor[Proc]] import
  # @param [Or[:object, :class, :both]] import
  def link_object(object_name, as: nil, from: nil, import: nil, target: nil)
    check_arg(object_name, :object_name, Symbol)
    check_arg(as, :as, Symbol) if as
    check_arg(from, :from, Symbol) if from
    check_arg(import, :import, Proc) if import
    check_target(target) if target

    link_package_name = from.nil? ? @object.package_name : from
    link_object_name = object_name
    link_as = as ? as : object_name

    check_package_dependency_added(link_package_name)

    const_list = if import
      Ree::LinkImportBuilder
        .new(@packages_facade)
        .build(
          @object.klass,
          link_package_name,
          link_object_name,
          import
        )
    end

    link = Ree::ObjectLink.new(
      link_object_name, link_package_name, link_as, target
    )

    if const_list
      link.set_constants(const_list)
      @object.add_const_list(const_list)
    end

    @object.links.push(link)
    Ree.logger.debug("  #{@object.klass}.link(:#{link_object_name}, from: #{link_package_name}, as: #{link_as})")

    @packages_facade.load_package_object(link_package_name, link_object_name)
  end

  # @param [ArrayOf[Symbol]] object_names
  # @param [Hash] kwargs
  def link_multiple_objects(object_names, **kwargs)
    check_arg(kwargs[:from], :from, Symbol) if kwargs[:from]

    if kwargs.reject{ |k, _v| k == :from }.size > 0
      raise Ree::Error.new("options #{kwargs.reject{ |k, _v| k == :from }.keys} are not allowed for multi-object links", :invalid_link_option)
    end

    object_names.each do |object_name|
      link_object(object_name, from: kwargs[:from])
    end
  end

  # @param [Symbol] target (:object, :class, :both, default: :object)
  def target(val)
    check_arg(val, :target, Symbol)
    check_target(val)

    @object.set_target(val)
  end

  def with_caller
    @object.set_freeze(false)

    if @object.singleton?
      raise_error("`with_caller` is not available for singletons")
    end

    if @object.factory?
      raise_error("`with_caller` is not available for factory beans")
    end

    @object.set_as_with_caller
  end

  # @param [Symbol] method_name
  def factory(method_name)
    if !@object.object?
      raise_error("Factory methods only available for beans")
    end

    if @object.after_init
      raise_error("Factory beans do not support after_init DSL")
    end

    if @object.with_caller?
      raise_error("Factory beans do not support with_caller DSL")
    end

    check_arg(method_name, :method_name, Symbol)
    @object.set_factory(method_name)
  end

  def singleton
    if @object.with_caller?
      raise_error("`singleton` should not be combined with `with_caller`")
    end

    @object.set_as_singleton
  end

  # @param [Symbol] method_name
  def after_init(method_name)
    if @object.factory?
      raise_error("Factory beans do not support after_init DSL")
    end

    check_arg(method_name, :method_name, Symbol)
    @object.set_after_init(method_name)
  end

  def benchmark(once: false, deep: true, hide_ree_lib: true, output: -> (res) { $stdout.puts(res) })
    if !@object.fn?
      raise_error("`benchmark` is only available for fn objects")
    end

    check_bool(once, :once)
    check_bool(deep, :deep)
    check_bool(hide_ree_lib, :hide_ree_lib)

    config = { once: once, deep: deep, hide_ree_lib: hide_ree_lib, output: output }
    @object.set_benchmark_config(config)

    @object.klass.instance_variable_set(:@__ree_benchmark_config, config)
  end

  # @param [Bool] flag
  def freeze(flag)
    if @object.with_caller? && flag
      raise_error("`freeze` should not be combined with `with_caller`")
    end

    check_bool(flag, :flag)
    @object.set_freeze(flag)
  end

  # @param [String] path Relative package file path ('accounts/entities/user')
  # @param [Proc] proc Import constants proc
  def link_file(path, import_proc = nil)
    check_arg(import_proc, :import, Proc) if import_proc

    list = path.split('/')
    package_name = File.basename(list[0], ".*").to_sym

    check_package_dependency_added(package_name)

    @packages_facade.load_package_entry(package_name)
    package = @packages_facade.get_loaded_package(package_name)

    file_path = File.join(
      Ree::PathHelper.abs_package_dir(package),
      Ree::PACKAGE, path
    )

    if !File.exist?(file_path)
      file_path = "#{file_path}.rb"

      if !File.exist?(file_path)
        raise_error("Unable to link '#{path}'. File not found #{file_path}")
      end
    end

    @packages_facade.load_file(file_path, package.name)

    const_list = path.split('/').map { |_| Ree::StringUtils.camelize(_) }
    const_short = [const_list[0], const_list.last].join("::")
    const_long = const_list.join("::")

    file_const = if Object.const_defined?(const_long)
      Object.const_get(const_long)
    elsif Object.const_defined?(const_short)
      Object.const_get(const_short)
    else
      raise_error("Unable to link '#{path}'. #{const_long} or #{const_short} was not defined in #{file_path}")
    end

    const_list = if import_proc
      Ree::LinkImportBuilder
        .new(@packages_facade)
        .build_for_const(
          @object.klass,
          file_const,
          import_proc
        )
    end

    if const_list
      @object.add_const_list(const_list.map(&:name))
    end

    file_const
  end

  private

  MOUNT_AS = [:fn, :object]

  def register_object(object_name, klass, mount_as)
    check_arg(object_name, :object_name, Symbol)
    check_arg(klass, :klass, Class)
    check_arg(mount_as, :mount_as, Symbol)

    if klass.name.nil?
      raise Ree::Error.new("Anonymous classes are not supported", :invalid_dsl_usage)
    end

    path = Object.const_source_location(klass.name)[0].split(':').first

    if !MOUNT_AS.include?(mount_as)
      raise Ree::Error.new("Mount as should be one of #{MOUNT_AS.inspect}", :invalid_dsl_usage)
    end

    if !Ree.irb_mode?
      object_name_from_path = if File.exist?(path)
        File.basename(path, ".*").to_sym
      end

      if object_name_from_path && object_name != object_name_from_path
        raise Ree::Error.new("Object name does not correspond to a file name (#{object_name}, #{object_name_from_path}.rb). Fix object name or rename object file", :invalid_dsl_usage)
      end
    end

    class_name = klass.to_s
    list = class_name.split('::')

    if list.size > 3
      raise Ree::Error.new("Objects should be declared inside parent modules or inside there submodules", :invalid_dsl_usage)
    end

    package_name = if list.size == 1
      raise Ree::Error.new("Object declarations should only appear for classes declared inside modules", :invalid_dsl_usage)
    else
      Ree::StringUtils.underscore(list[0]).to_sym
    end

    auto_object_name = Ree::StringUtils.underscore(list.last).to_sym

    if auto_object_name != object_name
      raise Ree::Error.new(":#{object_name} does not correspond to class name #{list.last}. Change object name to '#{auto_object_name}' or change name of the class", :invalid_dsl_usage)
    end

    package = @packages_facade.get_loaded_package(package_name)
    object = package.get_object(object_name)

    object_rpath = if !Ree.irb_mode?
      Pathname
        .new(path)
        .relative_path_from(Pathname.new(Ree::PathHelper.project_root_dir(package)))
        .to_s
    end

    schema_rpath = if !Ree.irb_mode?
      Ree::PathHelper.object_schema_rpath(object_rpath)
    end

    if !object
      object = Ree::Object.new(
        object_name,
        schema_rpath,
        object_rpath,
      )
    else
      object
        .set_rpath(object_rpath)
        .set_schema_rpath(schema_rpath)
    end

    object.reset

    object
      .set_mount_as(mount_as)
      .set_class(klass)
      .set_package(package.name)
      .set_rpath(object_rpath)

    if mount_as == :fn
      klass.instance_variable_set(:@__ree_package_name, package.name)
      klass.instance_variable_set(:@__ree_object_name, object_name)
    end

    package.set_object(object)
    object.set_loaded

    object
  end

  def check_package_dependency_added(package_name)
    @packages_facade.load_package_entry(package_name)
    return if package_name == @package.name

    dep_package = @package.deps.detect do |d|
      d.name == package_name
    end

    if dep_package.nil?
      raise_error("Package :#{package_name} is not added as dependency for :#{@object.package_name} package\npackage path: #{File.join(Ree.root_dir, @package.entry_rpath)}")
    end
  end

  def check_target(val)
    if ![:object, :class, :both].include?(val)
      raise Ree::Error.new("target should be one of [:object, :class, :both]", :invalid_dsl_usage)
    end
  end

  def raise_error(text, code = :invalid_dsl_usage)
    msg = <<~DOC
      object: :#{@object.name}
      path: #{Ree::PathHelper.abs_object_path(@object)}
      error: #{text}
    DOC

    raise Ree::Error.new(msg, code)
  end

  def _import_object_consts(import_proc, from: nil)
    check_arg(from, :from, Symbol) if from

    link_package_name = from.nil? ? @object.package_name : from

    Ree::LinkImportBuilder.new(@packages_facade).build_for_objects(
      @object.klass, link_package_name, import_proc
    )
  end

  def _import_from_object(object_name, import_proc, from: nil)
    check_arg(from, :from, Symbol) if from

    link_package_name = from.nil? ? @object.package_name : from

    Ree::LinkImportBuilder.new(@packages_facade).build(
      @object.klass, link_package_name, object_name, import_proc
    )
  end
end