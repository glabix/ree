# frozen_string_literal: true

require 'pathname'

class Ree::PackageFileStructureLoader
  PACKAGE_FOLDER = 'package'

  # @param [Ree::Package] package Loaded package
  # @return [Ree::Package]
  def call(package)
    package_dir = if package && package.gem?
      File.join(Ree.gem(package.gem_name).dir, package.dir)
    else
      File.join(Ree.root_dir, package.dir)
    end

    root_dir = if package.gem?
      Ree.gem(package.gem_name).dir
    else
      Ree.root_dir
    end

    object_store = {}
    package.set_schema_loaded
   
    files_dir = File.join(package_dir, PACKAGE_FOLDER)
    Dir[File.join(files_dir, '**', '*.rb')].each do |path|
      file_path = Pathname.new(path)
      object_name = File.basename(path, '.rb')
      rpath = file_path.relative_path_from(root_dir)

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

    package
  end
end