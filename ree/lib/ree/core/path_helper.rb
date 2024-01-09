# frozen_string_literal: true

require 'pathname'

class Ree::PathHelper
  SCHEMAS_FOLDER = 'schemas'

  class << self
    # @param [Ree::Object] object
    # @return [String] Absolute object file path
    def abs_object_path(object)
      package = Ree.container.packages_facade.get_package(object.package_name)
      File.join(project_root_dir(package), object.rpath)
    end

    # @param [Ree::Object] object
    # @return [String] Absolute object schema path
    def abs_object_schema_path(object)
      package = Ree.container.packages_facade.get_package(object.package_name)
      File.join(project_root_dir(package), object.schema_rpath)
    end

    # @param [String] schema_path Relative path of an object schema (ex. bc/accounts/schemas/accounts/object.schema.json)
    # @return [String] Relative path to a object source file (ex. bc/accounts/object.rb)
    def object_rpath(schema_rpath)
      nodes = schema_rpath.split('/')
      index = nodes.index(SCHEMAS_FOLDER)
      nodes[index] = Ree::PACKAGE
      object_name = nodes[-1].split('.').first
      filename = "#{object_name}.rb"
      nodes[-1] = filename
      nodes.join('/')
    end

    # @param [String] object_rpath Relative path of an object (bc/accounts/package/accounts/object.rb)
    # @return [String] Relative path of a object schema (ex. bc/accounts/schemas/accounts/object.schema.json)
    def object_schema_rpath(object_rpath)
      nodes = object_rpath.split('/')
      index = nodes.index(Ree::PACKAGE)
      nodes[index] = Ree::SCHEMAS
      filename = File.basename(nodes[-1], '.*')
      schema_name = "#{filename}.#{Ree::SCHEMA}.json"
      nodes[-1] = schema_name
      nodes.join('/')
    end

    # @param [String] schema_path Absolute or relative path of a package schema (bc/accounts/package/accounts/Package.json)
    # @return [String] Absolute or relative path of a package entry file (ex. bc/accounts/schemas/accounts.rb)
    def package_entry_path(schema_path)
      dir = Pathname.new(schema_path).dirname.to_s
      name = dir.split('/').last
      File.join(dir, "#{Ree::PACKAGE}/#{name}.rb")
    end

    # @param [String] directory inside package
    # @return [String] name of package
    def package_name_from_dir(dir)
      package_schema = File.join(dir, Ree::PACKAGE_SCHEMA_FILE)

      if File.exist?(package_schema)
        return package_schema.split('/')[-2]
      end

      if dir == '/'
        return nil
      end

      package_name_from_dir(File.expand_path('..', dir))
    end

    # @param [Ree::Package] package Package schema
    # @return [String] Absolute package entry path (ex. /data/project/bc/accounts/package/accounts.rb)
    def abs_package_entry_path(package)
      File.join(project_root_dir(package), package.entry_rpath)
    end

    # @param [Ree::Package] package Package schema
    # @return [String] Absolute package folder path (ex. /data/project/bc/accounts/package/accounts)
    def abs_package_module_dir(package)
      File.join(
        project_root_dir(package), package.dir, Ree::PACKAGE, package.name.to_s
      )
    end

    # @param [Ree::Package] package Package schema
    # @return [String] Absolute package schemas folder path (ex. /data/project/bc/accounts/schemas)
    def abs_package_schemas_dir(package)
      File.join(
        project_root_dir(package), package.dir, Ree::SCHEMAS
      )
    end

    # @param [Ree::Package] package Package schema
    # @return [String] Absolute package schema path
    def abs_package_schema_path(package)
      File.join(project_root_dir(package), package.schema_rpath)
    end

    # @param [Ree::Package] package Package schema
    # @return [String] Absolute package folder path (ex. /data/project/bc/accounts)
    def abs_package_dir(package)
      File.join(project_root_dir(package), package.dir)
    end

    # @param [Ree::Package] package Package schema
    # @param [String] absolute file path
    # @return [String] File path relative to package (ex. accounts/entities/user.rb)
    def package_relative_path(package, path)
      Pathname
        .new(path)
        .relative_path_from(File.join(Ree.root_dir, package.dir, Ree::PACKAGE))
        .to_s
    end

    def project_root_dir(package)
      if package.gem?
        Ree.gem(package.gem_name).dir
      else
        Ree.root_dir
      end
    end
  end
end