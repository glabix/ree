# frozen_string_literal: true

require 'set'
require 'pathname'

class Ree::PackageLoader
  def initialize()
    @loaded_paths = {}
    @loaded_packages = {}
  end

  def call(package)
    return if @loaded_packages[package.name]

    package_dir = Ree::PathHelper.abs_package_module_dir(package)

    package.objects.each do |package_object|
      object_path = Ree::PathHelper.abs_object_path(package_object)

      load_file(object_path, package.name)
    end

    @loaded_packages[package.name] = true

    package.deps.each do |dep|
      call(dep)
    end 
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
