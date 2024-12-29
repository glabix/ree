require 'json'

module Ree
  module CLI
    module Indexing
      class IndexFile
        include Indexing

        class << self
          def run(file_path:, project_path:)
            ENV['REE_SKIP_ENV_VARS_CHECK'] = 'true'
  
            path = Ree.locate_packages_schema(project_path)
            dir = Pathname.new(path).dirname.to_s
  
            Ree.init(dir)
  
            file_path = File.join(dir, file_path)
  
            current_package_schema = self.find_package(File.dirname(file_path))
  
            return '{}' unless current_package_schema
  
            package_schema = JSON.load_file(current_package_schema)
            current_package_name = package_schema["name"].to_sym
  
            facade = Ree.container.packages_facade
            Ree.load_package(current_package_name)
  
            package = facade.get_package(current_package_name)
  
            files = Dir[
              File.join(
                Ree::PathHelper.abs_package_module_dir(package), '**/*.rb'
              )
            ]
  
            return {} if !files.include?(file_path)
  
            objects_class_names = package.objects.map(&:class_name)
            file_name_const_string = Ree::StringUtils.camelize(file_path.split('/')[-1].split('.rb')[0])
            const_string_with_module = "#{package.module}::#{file_name_const_string}"
  
            return {} if objects_class_names.include?(const_string_with_module) # skip objects
  
            klass = Object.const_get(const_string_with_module)
  
            methods = klass
              .public_instance_methods(false)
              .reject { _1.match?(/original/) } # remove aliases defined by contracts
              .map {
                {
                  name: _1,
                  location: klass.public_instance_method(_1).source_location&.last,
                }
              }
  
            hsh = {
              path: file_path,
              package: current_package_name,
              methods: methods
            }
  
            JSON.pretty_generate({ file_name_const_string => hsh })
          end
  
          def find_package(dir)
            if dir == '/'
              return nil
            end
  
            find_package(File.expand_path('..', dir))
          end
        end
      end
    end
  end
end
