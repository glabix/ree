# frozen_string_literal: true

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
    @package_loader.get_loaded_package(package_name)
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
    @package_loader.load_package_entry(package_name)
  end


  # @param [Symbol] package_name
  # @param [Symbol] object_name
  # @return [Ree::Object]
  def load_package_object(package_name, object_name)
    package = get_loaded_package(package_name)
    object = get_object(package_name, object_name)

    unless object
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
    @package_loader.read_package_structure(package_name)
  end

  # @param [Symbol] package_name
  # @return [Ree::Package]
  def load_entire_package(package_name)
    @package_loader.load_entire_package(package_name)
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
    @package_loader.get_package(package_name, raise_if_missing)
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