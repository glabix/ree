# frozen_string_literal: true

class Ree::BuildPackageDsl
  include Ree::Args

  attr_reader :package

  # @param [Ree::PackagesFacade] packages_facade
  # @param [Module] mod
  # @param [Nilor[String]] path
  def initialize(packages_facade, mod)
    @packages_facade = packages_facade
    @package = register_package(mod)
  end

  # @param [ArrayOf[String]] lists
  def tags(list)
    list.each do |tag|
      check_arg(tag, :tag, String)
    end

    list += [@package.name.to_s]
    list.uniq

    @package.set_tags(list)
  end

  # @param [Symbol] depends_on
  def depends_on(depends_on)
    check_arg(depends_on, :depends_on, Symbol)

    if depends_on == @package.name
      raise_error("A package cannot depend on itself")
    end

    if @package.get_dep(depends_on)
      raise_error("Dependent package :#{depends_on} already added for package :#{@package.name}")
    end

    package_dep = @package.set_dep(
      Ree::PackageDep.new(depends_on)
    )

    dep_package = begin
      @packages_facade.get_package(depends_on)
    rescue Ree::Error
      raise_error("Dependent package :#{depends_on} was not found in #{Ree::PACKAGES_SCHEMA_FILE}. Run `ree gen.packages_json` to update schema or fix package name")
    end

    package_dep
  end

  def load_dependent_packages
    @package.deps.each do |dep|
      @packages_facade.load_package_entry(dep.name)
    end
  end

  # @param [Proc] block
  def default_links(&block)
    raise Ree::Error.new("block missing") if !block_given?

    @package.set_default_links(&block)
  end

  # @param [String] var_name
  # @param [Nilor[String]] doc
  def env_var(var_name, doc: nil)
    check_arg(var_name, :env_var, String)
    check_arg(doc, :doc, String) if doc

    if @package.get_env_var(var_name)
      raise_error("Duplicate env var '#{var_name}'")
    end

    @package.set_env_var(
      Ree::PackageEnvVar.new(
        var_name, doc
      )
    )
  end

  # @param [HashOf[Symbol, ArrayOf[Symbol]]] opts
  def preload(opts)
    check_arg(opts, :opts, Hash)

    opts.each do |env, list|
      check_arg(list, :object_list, Array)

      list.each do |object_name|
        check_arg(object_name, :object_name, Symbol)
      end
    end

    @package.set_preload(opts)
  end

  private

  def check_module(mod)
    check_arg(mod, :module_name, Module)
    module_name = mod.to_s
    list = module_name.split('::')

    if list.size != 1
      raise Ree::Error.new("depends_on should be defined for top level modules only", :invalid_dsl_usage)
    end
  end

  def register_package(mod)
    check_module(mod)
    check_arg(mod, :module, Module)

    if mod.name.nil?
      raise Ree::Error.new("package decorator should be applied to a named module", :invalid_dsl_usage)
    end

    path = Object.const_source_location(mod.name)[0].split(':').first
    module_name = mod.to_s
    list = module_name.split('::')

    if list.size != 1
      raise Ree::Error.new("package should be defined for top level modules only", :invalid_dsl_usage)
    end

    name_from_path = File.basename(path, ".*").to_sym
    name = Ree::StringUtils.underscore(list[0]).to_sym

    if !Ree.irb_mode? && name != name_from_path
      raise Ree::Error.new("Package module '#{module_name}' does not correspond to package name '#{name}'. Fix file name or module name.")
    end

    package = @packages_facade.get_package(name, false)

    if package.nil?
      package = Ree::Package.new(Ree::VERSION, name, nil, nil, nil)
      @packages_facade.store_package(package)
    end

    package.set_module(mod)
    package.set_tags([name])

    package.reset
    package.set_entry_loaded
    package.set_loaded

    package
  end

  def raise_error(text, code = :invalid_dsl_usage)
    msg = <<~DOC
      package: :#{@package.name}
      path: #{File.join(Ree.root_dir, @package.entry_rpath)}
      error: #{text}
    DOC

    raise Ree::Error.new(msg, code)
  end
end