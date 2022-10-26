require 'fileutils'

module Ree
  module CLI
    class GenerateObjectSchema
      class << self
        def run(package_name:, object_path:, project_path:, silence: false)
          ENV['REE_SKIP_ENV_VARS_CHECK'] = 'true'

          path = Ree.locate_packages_schema(project_path)
          dir = Pathname.new(path).dirname.to_s

          Ree.init(dir)

          package_name = package_name.to_sym
          object_name = object_path.split('/')[-1].split('.').first.to_sym

          puts("Generating #{object_name}.schema.json in #{package_name} package") if !silence

          facade = Ree.container.packages_facade
          Ree.load_package(package_name)

          package = facade.get_package(package_name)

          if facade.has_object?(package_name, object_name)
            object = facade.load_package_object(package_name, object_name)
            Ree.write_object_schema(package.name, object.name)
          else
            file_path = File.join(dir, object_path)

            if File.exists?(file_path)
              facade.load_file(file_path, package_name)
              facade.dump_package_schema(package_name)

              if facade.has_object?(package_name, object_name)
                Ree.write_object_schema(package_name, object_name)
                facade.write_package_schema(package_name)
              end
            else
              raise Ree::Error.new("package file not found: #{file_path}")
            end
          end

          puts("done") if !silence
        end
      end
    end
  end
end
