# frozen_string_literal: true

class Ree::PackagesFacade
  include Ree::Args

  attr_reader :packages_store, :package_loader

  def initialize
    load_packages_schema
    @package_loader = Ree::PackageLoader.new
  end

  class << self
    def write_packages_schema
      Ree.logger.debug("write_packages_schema")
      packages_schema = Ree::PackagesSchemaBuilder.new.call

      json = JSON.pretty_generate(packages_schema)

      File.write(
        File.join(Ree.root_dir, Ree::PACKAGES_SCHEMA_FILE),
        json,
        mode: 'w'
      )

      json
    end
  end

  # @param [Symbol] package_name
  # @return [Ree::Package]
  def get_loaded_package(package_name)
    package = get_package(package_name)
    return package if package.schema_loaded?

    read_package_structure(package_name)

    package
  end

  # @param [Symbol] package_name
  # @param [Symbol] object_name
  # @return [Ree::Object]
  def get_object(package_name, object_name)
    package = get_loaded_package(package_name)
    object = package.get_object(object_name)

    object
  end

  def has_object?(package_name, object_name)
    package = get_loaded_package(package_name)
    object = package.get_object(object_name)

    !object.nil?
  end

  # @param [Symbol] package_name
  # @return nil
  def load_package_entry(package_name)
    package = @packages_store.get(package_name)

    if package.nil?
      raise Ree::Error.new("package :#{package_name} not found in Packages.schema.json")
    end

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
    object = get_object(package_name, object_name)

    unless object
      pp package
      pp package.objects
      pp package.instance_varaible_get(:@objects_store)

      raise Ree::Error.new("object :#{object_name} from :#{package_name} was not found")
    end

    return object if object.loaded?

    Ree.logger.debug("load_package_object(:#{package_name}, :#{object_name})")

    if object.rpath
      object_path = Ree::PathHelper.abs_object_path(object)
      load_file(object_path, package_name)
    end

    object
  end

  # @param [Symbol] package_name
  # @return [Ree::Package]
  def read_package_structure(package_name)
    package = get_package(package_name)

    @loaded_schemas ||= {}
    return @loaded_schemas[package_name] if @loaded_schemas[package_name]

    Ree.logger.debug("read_package_file_structure(:#{package_name})")
    package = get_package(package_name)

    if !package.dir
      package.set_schema_loaded
      return package
    end

    Ree.logger.debug("read_package_file_structure package #{package})")

    @loaded_schemas[package_name] = Ree::PackageFileStructureLoader.new.call(package)
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
  # @return [Bool]
  def has_package?(package_name)
    check_arg(package_name, :package_name, Symbol)
    !!@packages_store.get(package_name)
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