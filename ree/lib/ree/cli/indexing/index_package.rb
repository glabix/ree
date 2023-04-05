require 'json'

module Ree
  module CLI
    module Indexing
      class IndexPackage
        include Indexing

        class << self
          def run(package_name:, project_path:)
            ENV['REE_SKIP_ENV_VARS_CHECK'] = 'true'
  
            path = Ree.locate_packages_schema(project_path)
            dir = Pathname.new(path).dirname.to_s
  
            Ree.init(dir)
  
            facade = Ree.container.packages_facade
  
            hsh = {}
            hsh[:package_schema] = {}
            hsh[:classes] = {}
            hsh[:objects] = {}
  
            package_name = package_name.to_sym
            facade.load_entire_package(package_name)
            package = facade.get_loaded_package(package_name)
            package_hsh = index_package_entry(package)
  
            hsh[:package_schema] = package_hsh
            hsh = index_public_methods_for_package_classes(package, hsh)
  
            JSON.pretty_generate(hsh)
          end
        end
      end
    end
  end
end
