# frozen_string_literal: true

require 'pathname'
require 'find'

class Ree::PackageFileStructureLoader
  # @param [Nilor[Ree::Package]] existing_package Loaded package
  # @return [Ree::Package]
  def call(existing_package)
    package_dir = if existing_package && existing_package.gem?
      Ree.gem(existing_package.gem_name).dir
    elsif existing_package
      "#{Ree.root_dir}/#{existing_package.dir}"
    else
      Ree.root_dir
    end

    package = existing_package # TODO build package if no existing package?

    package
      .set_schema_version('0')
      .set_schema_rpath(package.entry_rpath)

    object_store = {}
    package.set_schema_loaded
      
    Find.find(package_dir) do |path|
      if path.match(/\A*.rb\Z/)
        file_path = Pathname.new(path)
        object_name = File.basename(path, '.rb')
        rpath = file_path.relative_path_from(Ree.root_dir)

        object = Ree::Object.new(
          object_name.to_sym,
          rpath,
          rpath,
        )

        if object_store.has_key?(object_name)
          raise Ree::Error.new("duplicate object name for '#{object_name}': #{rpath}", :invalid_package_file_structure)
        end
  
        object_store[object_name] = true

        object.set_package(package.name)

        package.set_object(object)
      end
    end

    existing_package
  end
end