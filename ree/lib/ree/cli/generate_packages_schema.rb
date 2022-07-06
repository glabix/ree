module Ree
  module CLI
    class GeneratePackagesSchema
      class << self
        def run(project_path)
          Ree.init(project_path)

          puts("Generating Packages.schema.json")
          Ree::PackagesFacade.write_packages_schema

          puts("output: #{Ree.packages_schema_path}")
          puts("done")
        end
      end
    end
  end
end
