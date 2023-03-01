module Ree
  module CLI
    class IndexProject
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
              gem_package_hsh[:schema_rpath] = package.schema_rpath
              gem_package_hsh[:entry_rpath] = package.entry_rpath
              gem_package_hsh[:objects] = package.objects.map {
                {
                  name: _1.name,
                  schema_rpath: _1.schema_rpath,
                  file_rpath: _1.rpath,
                  mount_as: _1.mount_as,
                  methods: Ree::CLI::IndexPackage.send(:map_fn_methods, _1),
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

            facade.load_entire_package(package.name)

            package_hsh = Ree::CLI::IndexPackage.send(:index_package_entry, package)

            index_hash[:packages_schema][:packages] << package_hsh

            index_hash = index_public_methods_for_package_classes(package, index_hash)
          end

          if facade.get_package(:ree_errors, false)
            index_hash = index_exceptions(facade.get_package(:ree_errors), index_hash)
          end

          JSON.pretty_generate(index_hash)
        end

        private

        def index_public_methods_for_package_classes(package, index_hash)
          package.objects.each do |obj|
            klass = obj.klass
            klass_name = demodulize(klass.to_s)
            obj_name = obj.name.to_s
            rpath = obj.rpath

            if obj.tags.include?("enum")
              hsh = index_class(klass, rpath, package.name)
              index_hash[:classes][klass_name] ||= []
              index_hash[:classes][klass_name] << hsh
              index_hash[:objects][obj_name] ||= []
              index_hash[:objects][obj_name] << hsh
            elsif obj.tags.include?("dao")
              hsh = index_dao(klass, rpath, package.name)
              index_hash[:objects][obj_name] ||= []
              index_hash[:objects][obj_name] << hsh
            elsif obj.tags.include?("object")
              hsh = index_class(klass, rpath, package.name)
              index_hash[:objects][obj_name] ||= []
              index_hash[:objects][obj_name] << hsh
            end
          end

          recursively_index_module(package.module, index_hash, package, {})

          index_hash
        end

        def recursively_index_module(mod, index_hsh, package, mod_index)
          return if !mod.is_a?(Module)
          return if mod_index[mod]

          mod_index[mod] = true

          mod.constants.each do |const_name|
            const = mod.const_get(const_name)

            recursively_index_module(const, index_hsh, package, mod_index)

            next if !const.is_a?(Class)
            next if package.objects.any? { |o| o.klass == const }
            next if index_hsh[:classes].has_key?(demodulize(const.name))

            const_abs_path = mod.const_source_location(const.name).first
            next if !const_abs_path

            rpath = Pathname.new(const_abs_path).relative_path_from(Ree.root_dir).to_s
            hsh = index_class(const, rpath, package.name)
            class_name = demodulize(const.name)

            index_hsh[:classes][class_name] ||= []
            index_hsh[:classes][class_name] << hsh
          end
        end

        def index_class(klass, rpath, package_name)
          all_methods = klass.public_instance_methods(false)
          orig_methods = all_methods.grep(/original/)

          methods = (all_methods - orig_methods) # remove aliases defined by contracts
            .map { |m|
              orig_method_name = orig_methods.find { |om| om.match(/original_#{Regexp.escape(m.name)}_[0-9a-fA-F]+/) }
              orig_method = orig_method_name ? klass.public_instance_method(orig_method_name) : nil

              {
                name: m,
                parameters: orig_method&.parameters&.map { |param| { name: param.last, required: param.first } },
                location: orig_method&.source_location&.last,
              }
            }

          {
            path: rpath,
            package: package_name,
            methods: methods
          }
        end

        def index_dao(klass, rpath, package_name)
          filters = (klass.instance_variable_get(:@filters) || []).map do
            {
              name: _1.name,
              parameters: _1.proc.parameters.map { |param|
                {name: param.last, required: param.first}
              },
              location: _1.proc&.source_location&.last
            }
          end

          {
            path: rpath,
            package: package_name,
            methods: filters
          }
        end

        def index_exceptions(errors_package, index_hash)
          errors_package.objects.each do |obj|
            const_name = demodulize(obj.class_name)
            file_name = File.join(
              Ree::PathHelper.abs_package_module_dir(errors_package),
              obj.name.to_s + ".rb"
            )

            hsh = {
              path: file_name,
              package: errors_package.name,
              methods: []
            }

            index_hash[:classes][const_name] ||= []
            index_hash[:classes][const_name] << hsh
          end

          index_hash
        end

        def demodulize(str)
          str.split("::").last
        end
      end
    end
  end
end
