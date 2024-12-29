module Ree
  module CLI
    module Indexing
      class IndexProject
        include Indexing

        class << self
          def run(project_path:)
            ENV['REE_SKIP_ENV_VARS_CHECK'] = 'true'
  
            path = Ree.locate_packages_schema(project_path)
            dir = Pathname.new(path).dirname.to_s
  
            Ree.init(dir)
  
            index_hash = {}
            # completion/etc data
            index_hash[:classes] = {}
            index_hash[:objects] = {}
  
            # schema data
            index_hash[:packages_schema] = {}
            index_hash[:packages_schema][:packages] = []
            index_hash[:packages_schema][:gem_packages] = []
  
            facade = Ree.container.packages_facade
  
            facade.packages_store.packages.each do |package|
              if package.gem?
                gem_package_hsh = {}
                gem_package_hsh[:name] = package.name
                gem_package_hsh[:gem] = package.gem_name
                gem_package_hsh[:entry_rpath] = package.entry_rpath
                gem_package_hsh[:objects] = package.objects.map {
                  {
                    name: _1.name,
                    file_rpath: _1.rpath,
                    mount_as: _1.mount_as,
                    methods: map_fn_methods(_1),
                    links: _1.links.sort_by(&:object_name).map { |link|
                      {
                        Ree::ObjectSchema::Links::TARGET => link.object_name,
                        Ree::ObjectSchema::Links::PACKAGE_NAME => link.package_name,
                        Ree::ObjectSchema::Links::AS => link.as,
                        Ree::ObjectSchema::Links::IMPORTS => link.constants
                      }
                    }
                  }
                }
  
                index_hash[:packages_schema][:gem_packages] << gem_package_hsh
  
                next
              end
  
              next if package.dir.nil?
  
              facade.read_package_structure(package.name)
  
              package_hsh = index_package_entry(package)
  
              index_hash[:packages_schema][:packages] << package_hsh
  
              index_hash = index_public_methods_for_package_classes(package, index_hash)
            end
  
            if facade.get_package(:ree_errors, false)
              index_hash = index_exceptions(facade.get_package(:ree_errors), index_hash)
            end
  
            JSON.pretty_generate(index_hash)
          end
        end
      end
    end
  end
end
