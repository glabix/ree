require 'fileutils'

module Ree
  module CLI
    class GeneratePackageSchema
      class << self
        def run(package_name:, project_path:, include_objects: false, silence: false)
          path = Ree.locate_packages_schema(project_path)
          dir = Pathname.new(path).dirname.to_s

          Ree.init(dir)
          Ree.set_dev_mode

          if package_name.strip.empty?
            puts("Generating Package.schema.json for all packages") if !silence
            Ree.generate_schemas_for_all_packages(silence)
            return
          end

          puts("Generating Package.schema.json for :#{package_name} package") if !silence

          package_name = package_name.to_sym

          Ree.container.packages_facade.load_packages_schema
          package = Ree.load_package(package_name)
          Ree.container.packages_facade.write_package_schema(package_name)

          package = Ree.container.packages_facade.get_package(package_name)
          schema_path = Ree::PathHelper.abs_package_schema_path(package)

          if include_objects
            schemas_path = Ree::PathHelper.abs_package_object_schemas_path(package)

            FileUtils.rm_rf(schemas_path)
            FileUtils.mkdir_p(schemas_path)

            package.objects.each do |object|
              Ree.write_object_schema(package.name, object.name)

              path = Ree::PathHelper.abs_object_schema_path(object)

              puts("  #{object.name}: #{path}") if !silence
            end
          end

          puts("output: #{schema_path}") if !silence
          puts("done") if !silence
        end
      end
    end
  end
end
