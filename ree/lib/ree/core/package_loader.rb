# frozen_string_literal: true

require 'set'
require 'pathname'

class Ree::PackageLoader
  include Ree::Args

  def initialize(packages_store)
    @loaded_paths = {}
    @loaded_packages = {}
    @packages_store = packages_store
  end

  def load_entire_package(package_name)
    return if @loaded_packages[package_name]

    package = get_loaded_package(package_name)

    return unless package
    
    package.objects.each do |package_object|
      object_path = Ree::PathHelper.abs_object_path(package_object)

      load_file(object_path, package.name)
    end

    @loaded_packages[package.name] = true

    package.deps.each do |dep|
      load_entire_package(dep.name)
    end 
  end

  def get_loaded_package(package_name)
    package = get_package(package_name)
    load_package_entry(package_name)
    
    return package if package.schema_loaded?

    read_package_structure(package_name)

    package
  end

  def get_package(package_name, raise_if_missing = true)
    check_arg(package_name, :package_name, Symbol)
    package = @packages_store.get(package_name)

    if !package && raise_if_missing
      raise Ree::Error.new("Package :#{package_name} is not found in Packages.schema.json. Run `ree gen.packages_json` to update schema.", :package_schema_not_found)
    end

    package
  end

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

  def read_package_structure(package_name)
    package = get_package(package_name)

    Ree.logger.debug("read_package_file_structure(:#{package_name})")
    package = get_package(package_name)

    if !package.dir
      package.set_schema_loaded
      return package
    end

    Ree::PackageFileStructureLoader.new.call(package)
  end

  def reset
    @loaded_paths = {}
  end

  def load_file(path, package_name)
    @loaded_paths[package_name] ||= {}
    return if @loaded_paths[package_name][path]
    @loaded_paths[package_name][path] = true

    Ree.logger.debug("load_file(:#{package_name}, '#{path}')")
    Kernel.require(path)
  end
end

