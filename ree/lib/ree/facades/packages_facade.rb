# frozen_string_literal  = true

class Ree::PackagesFacade
  include Ree::Args

  attr_reader :packages_store, :package_loader

  def initialize
    load_packages_schema
    @package_loader = Ree::PackageLoader.new(@packages_store)
  end

  class << self
    def write_packages_schema
      Ree.logger.debug("write_packages_schema")
      Ree::PackagesSchemaBuilder.new.call
    end
  end

  def perf_mode?(package)
    package.gem? ? true : Ree.performance_mode?
  end

  # @param [Symbol] package_name
  # @return [Ree::Package]
  def get_loaded_package(package_name)
    package = get_package(package_name)
    return package if package.schema_loaded?

    if perf_mode?(package)
      read_package_schema_json(package_name)
    else
      load_entire_package(package_name)
    end

    package
  end

  # @param [Symbol] package_name
  # @param [Symbol] object_name
  # @return [Ree::Object]
  def get_object(package_name, object_name)
    package = get_loaded_package(package_name)
    object = package.get_object(object_name)

    if !object && perf_mode?(package)
      raise Ree::Error.new("Bean :#{object_name} for package :#{package_name} not found")
    end

    object
  end

  # @param [Symbol] package_name
  # @return nil
  def write_package_schema(package_name)
    Ree.logger.debug("write_package_schema(:#{package_name})")

    load_entire_package(package_name)
    package = get_package(package_name)

    if package.dir
      schema_path = Ree::PathHelper.abs_package_schema_path(package)
      Ree::PackageSchemaBuilder.new.call(package, schema_path)
    end
  end

  # @param [Symbol] package_name
  # @param [Symbol] object_name
  # @return [String]
  def write_object_schema(package_name, object_name)
    Ree.logger.debug("write_object_schema(package_name: #{package_name}, object_name: #{object_name})")
    object = get_object(package_name, object_name)

    if !object || (object && !object&.schema_rpath)
      raise Ree::Error.new("Object :#{object_name} schema path not found")
    end

    schema_path = Ree::PathHelper.abs_object_schema_path(object)

    Ree::ObjectSchemaBuilder.new.call(object, schema_path)
  end

  # @param [Symbol] package_name
  # @return nil
  def load_package_entry(package_name)
    package = @packages_store.get(package_name)
    return if package.loaded?

    Ree.logger.debug("load_package_entry(:#{package_name})")

    load_file(
      Ree::PathHelper.abs_package_entry_path(package),
      package_name
    )
  end

  # @param [Symbol] package_name
  # @param [Symbol] object_name
  # @return [Ree::Object]
  def load_package_object(package_name, object_name)
    package = get_loaded_package(package_name)
    load_package_entry(package_name)

    object = get_object(package_name, object_name)
    return object if object && object.loaded?

    if !object && !perf_mode?(package)
      Dir[
        File.join(
          Ree::PathHelper.abs_package_module_dir(package),
          "**/#{object_name}.rb"
        )
      ].each do |path|
        load_file(path, package_name)
      end

      object = get_object(package_name, object_name)
    end

    if !object
      raise Ree::Error.new("object :#{object_name} from :#{package_name} was not found")
    end

    Ree.logger.debug("load_package_object(:#{package_name}, :#{object_name})")

    if object.rpath
      object_path = Ree::PathHelper.abs_object_path(object)
      load_file(object_path, package_name)
    end

    object
  end

  # @param [Symbol] package_name
  # @return [Ree::Package]
  def load_entire_package(package_name)
    @package_loader.call(package_name)
  end

  # @param [Symbol] package_name
  # @return [Ree::Package]
  def read_package_schema_json(package_name)
    @loaded_schemas ||= {}
    return @loaded_schemas[package_name] if @loaded_schemas[package_name]

    Ree.logger.debug("read_package_schema_json(:#{package_name})")
    package = get_package(package_name)

    if !package.dir
      package.set_schema_loaded
      return package
    end

    schema_path = Ree::PathHelper.abs_package_schema_path(package)
    @loaded_schemas[package_name] = Ree::PackageSchemaLoader.new.call(schema_path, package)
  end

  # @return [Ree::PackagesStore]
  def load_packages_schema
    Ree.logger.debug("load_packages_schema: #{self.object_id}")
    @packages_store = Ree::PackagesSchemaLoader.new.call(Ree.packages_schema_path, @packages_store)

    Ree.gems.each do |gem|
      Ree::PackagesSchemaLoader.new.call(
        gem.packages_schema_path, @packages_store, gem.name
      )
    end

    @packages_store
  end

  # @param [Symbol] package_name
  # @return [Ree::Package]
  def get_package(package_name, raise_if_missing = true)
    check_arg(package_name, :package_name, Symbol)
    package = @packages_store.get(package_name)

    if !package && raise_if_missing
      raise Ree::Error.new("Package :#{package_name} is not found in Packages.schema.json. Run `ree gen.packages_json` to update schema.", :package_schema_not_found)
    end

    package
  end

  # @param [Ree::Package] package
  # @return [Ree::Package]
  def store_package(package)
    @packages_store.add_package(package)
  end

  # @param [String] path
  # @param [Symbol] package_name
  # @return [nil]
  def load_file(path, package_name)
    @package_loader.load_file(path, package_name)
  end
end