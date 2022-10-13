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
          Ree.set_dev_mode

          package_name = package_name.to_sym
          object_name = object_path.split('/')[-1].split('.').first.to_sym

          puts("Generating #{object_name}.schema.json in #{package_name} package") if !silence

          package = Ree.load_package(package_name)
          object = Ree.container.packages_facade.load_package_object(package_name, object_name)

          Ree.write_object_schema(package.name, object.name)

          obj_path = Ree::PathHelper.abs_object_schema_path(object)

          puts(" #{object.name}: #{obj_path}") if !silence

          puts("done") if !silence
        end
      end
    end
  end
end
