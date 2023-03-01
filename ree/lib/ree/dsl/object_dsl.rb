# frozen_string_literal  = true

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
  def link(*args, **kwargs)
    if args.first.is_a?(Symbol)
      link_object(*args, **kwargs)
    elsif args.first.is_a?(String)
      link_file(args[0], args[1])
    else
      raise_error("Invalid link DSL usage. Args should be Hash or String")
    end
  end

  def tags(list)
    @object.add_tags(list)
  end

  # @param [Symbol] object_name
  # @param [Nilor[Symbol]] as
  # @param [Nilor[Symbol]] from
  # @param [Nilor[Proc]] import
  def link_object(object_name, as: nil, from: nil, import: nil)
    check_arg(object_name, :object_name, Symbol)
    check_arg(as, :as, Symbol) if as
    check_arg(from, :from, Symbol) if from
    check_arg(import, :import, Proc) if import

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
      link_object_name, link_package_name, link_as
    )

    if const_list
      link.set_constants(const_list)
      @object.add_const_list(const_list)
    end

    @object.links.push(link)
    Ree.logger.debug("  #{@object.klass}.link(:#{link_object_name}, from: #{link_package_name}, as: #{link_as})")

    @packages_facade.load_package_object(link_package_name, link_object_name)
  end

  # @param [Symbol] method_name
  def factory(method_name)
    if !@object.object?
      raise_error("Factory methods only available for beans")
    end

    if @object.after_init
      raise_error("Factory beans do not support after_init DSL")
    end

    check_arg(method_name, :method_name, Symbol)
    @object.set_factory(method_name)
  end

  def singleton
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

  # @param [Bool] flag
  def freeze(flag)
    check_bool(flag, :flag)
    @object.set_freeze(flag)
  end

  # @param [Nilor[Symbol]] code Global error code
  # @param [Proc] proc Error DSL proc
  def def_error(code = nil, &proc)
    check_arg(code, :code, Symbol) if code

    if !block_given?
      raise_error("def_error should accept block with error class definition")
    end

    if code && !Ree.error_types.include?(code)
      raise_error("Invalid error code :#{code}. Did you forget to setup it with Ree.add_error_types(*args)?")
    end

    class_name = begin
      Ree::ErrorBuilder
        .new(@packages_facade)
        .build(
          @object,
          code,
          &proc
        )
    rescue Ree::Error
      raise_error("invalid def_error usage. Valid examples: def_error { InvalidDomainErr } or def_error(:validation) { EmailTakenErr['email taken'] }")
    end

    @object.add_const_list([class_name])

    @object.errors.push(
      Ree::ObjectError.new(
        class_name
      )
    )
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

    object_name_from_path = if File.exist?(path) && !Ree.irb_mode?
      File.basename(path, ".*").to_sym
    end

    if !Ree.irb_mode? && object_name_from_path && object_name != object_name_from_path
      raise Ree::Error.new("Object name does not correspond to a file name (#{object_name}, #{object_name_from_path}.rb). Fix object name or rename object file", :invalid_dsl_usage)
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

    package.set_object(object)
    object.set_loaded

    object
  end

  private

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

  def raise_error(text, code = :invalid_dsl_usage)
    msg = <<~DOC
      object: :#{@object.name}
      path: #{Ree::PathHelper.abs_object_path(@object)}
      error: #{text}
    DOC

    raise Ree::Error.new(msg, code)
  end
end