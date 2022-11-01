# frozen_string_literal  = true

require 'set'
require 'pathname'

class Ree::PackageLoader
  def initialize(packages_store)
    @packages_store = packages_store
    @loaded_paths = {}
    @loaded_packages = {}
  end

  def reset
    @loaded_paths = {}
  end

  # @param [Symbol] name Package name
  def call(name)
    return @loaded_packages[name] if @loaded_packages.has_key?(name)

    Ree.logger.debug("full_package_load(:#{name})")
    recursively_load_package(name, Hash.new(false))
    @loaded_packages[name]
  end

  def load_file(path, package_name)
    @loaded_paths[package_name] ||= {}
    return if @loaded_paths[package_name][path]
    @loaded_paths[package_name][path] = true

    Ree.logger.debug("load_file(:#{package_name}, '#{path}')")
    Kernel.require(path)
  end

  private

  def recursively_load_package(name, loaded_packages)
    @loaded_packages[name] = true
    package = @packages_store.get(name)

    if !package
      raise Ree::Error.new(
        "Package :#{name} was not found. Did you mistype the name? Run `ree gen.packages_json` to update Packages.schema.json",
        :invalid_package_name
      )
    end

    if package.dir.nil?
      package.set_schema_loaded
      return package
    end

    not_loaded = Set.new(
      [name, package.deps.map(&:name)]
        .uniq
        .select { |pn| !loaded_packages[pn] }
    )

    if not_loaded.include?(name)
      load_file(
        Ree::PathHelper.abs_package_entry_path(package), name
      )

      Dir[File.join(Ree::PathHelper.abs_package_module_dir(package), '**/*.rb')].each do |path|
        load_file(path, name)
      end

      loaded_packages[name] = true
    end

    if !ENV.has_key?('REE_SKIP_ENV_VARS_CHECK')
      package.env_vars.each do |env_var|
        if !ENV.has_key?(env_var.name)
          msg = <<~DOC
            package: :#{package.name}
            path: #{File.join(Ree::PathHelper.project_root_dir(package), package.entry_rpath)}
            error: Package :#{name} requires env var '#{env_var.name}' to be set
          DOC

          raise Ree::Error.new(msg, :env_var_not_set)
        end
      end
    end

    package.deps.each do |dep|
      if !loaded_packages[dep.name]
        recursively_load_package(dep.name, loaded_packages)
      end
    end

    package.set_schema_loaded

    @loaded_packages[name] = package
  end
end