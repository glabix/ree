require 'json'

module Ree
  module CLI
    class IndexPackage
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
          hsh = index_package_files(package, dir, hsh)

          JSON.pretty_generate(hsh)
        end

        private

        def index_package_entry(package)
          package_hsh = {}
          package_hsh[:name] = package.name
          package_hsh[:schema_rpath] = package.schema_rpath
          package_hsh[:entry_rpath] = package.entry_rpath
          package_hsh[:tags] = package.tags
          package_hsh[:objects] = package.objects.map {
            {
              name: _1.name,
              schema_rpath: _1.schema_rpath,
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

          package_hsh
        end

        def map_fn_methods(object)
          if !object.fn?
            return []
          end
  
          klass = object.klass
      
          method_decorator = Ree::Contracts.get_method_decorator(
            klass, :call, scope: :instance
          )
      
          begin
            if method_decorator.nil?
              parameters = klass.instance_method(:call).parameters
      
              args = parameters.inject({}) do |res, param|
                res[param.last] = Ree::Contracts::CalledArgsValidator::Arg.new(
                  param.last, param.first, nil, nil
                )
      
                res
              end
            else
              parameters = method_decorator.args.params
              args = method_decorator.args.get_args
            end
          rescue NameError
            raise Ree::Error.new("method call is not defined for #{klass}")
          end
      
          arg_list = parameters.map do |param|
            arg = args[param.last]
            validator = arg.validator
            arg_type = arg.type
      
            type = if validator
              validator.to_s
            else
              if arg_type == :block
                "Block"
              else
                "Any"
              end
            end
      
            {
              Ree::ObjectSchema::Methods::Args::ARG => arg.name,
              Ree::ObjectSchema::Methods::Args::TYPE => type
            }
          end
      
          [
            {
              Ree::ObjectSchema::Methods::DOC => method_decorator&.doc || "",
              Ree::ObjectSchema::Methods::THROWS => method_decorator&.errors&.map { _1.name } || [],
              Ree::ObjectSchema::Methods::RETURN => method_decorator&.contract_definition&.return_contract || "Any",
              Ree::ObjectSchema::Methods::ARGS => arg_list
            }
          ]
        end

        def index_package_files(package, dir, index_hash)
          Ree::CLI::IndexProject.send(:index_package_files, package, dir, index_hash)
        end
      end
    end
  end
end
