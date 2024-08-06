require 'fileutils'

module Ree
  module CLI
    class GeneratePackageSchema
      class << self
        def run(package_name:, project_path:, silence: false)
          ENV['REE_SKIP_ENV_VARS_CHECK'] = 'true'

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

          facade = Ree.container.packages_facade
          facade.load_packages_schema
          facade.load_entire_package(package_name)
          facade.write_package_schema(package_name)

          package = facade.get_package(package_name)
          schema_path = Ree::PathHelper.abs_package_schema_path(package)

          puts("output: #{schema_path}") if !silence
          puts("done") if !silence
        end
      end
    end
  end
end
