require 'fileutils'

module Ree
  module CLI
    class DeleteObjectSchema
      class << self
        def run(object_path:, project_path:, silence: false)
          ENV['REE_SKIP_ENV_VARS_CHECK'] = 'true'

          path = Ree.locate_packages_schema(project_path)
          dir = Pathname.new(path).dirname.to_s

          Ree.init(dir)

          object_name = object_path.split('/')[-1].split('.').first.to_sym

          puts("Deleting old #{object_name}.schema.json") if !silence

          schema_path = Ree::PathHelper.object_schema_rpath(object_path)
          abs_schema_path = File.join(dir, schema_path)

          if File.exist?(abs_schema_path)
            FileUtils.rm(abs_schema_path)

            facade = Ree.container.packages_facade
            package_name = Ree::PathHelper.package_name_from_dir(File.dirname(object_path))
            if package_name
              package_name = package_name.to_sym
              Ree.load_package(package_name)
              package = facade.get_loaded_package(package_name)
              package.remove_object(object_name)
              facade.dump_package_schema(package_name)
            end

            puts(" #{schema_path}: is deleted") if !silence
          end

          puts("done") if !silence
        end
      end
    end
  end
end
