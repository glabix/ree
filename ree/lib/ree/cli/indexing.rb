module Ree
  module CLI
    module Indexing
      autoload :IndexProject, 'ree/cli/indexing/index_project'
      autoload :IndexFile, 'ree/cli/indexing/index_file'
      autoload :IndexPackage, 'ree/cli/indexing/index_package'

      def self.included(base)
        base.extend(ClassMethods)
      end
      module ClassMethods
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

          object_is_action = object.tags.include?("action")
          action_caster = object.klass.const_get(:ActionCaster) if object.klass.const_defined?(:ActionCaster)

          method_name = object_is_action ? :__original_call : :call
          method_decorator = Ree::Contracts.get_method_decorator(
            klass, method_name, scope: :instance
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

            type = if object_is_action && action_caster && arg.name == :attrs
              map_mapper_fields(action_caster.fields).to_s.gsub(/\\*\"/, "").gsub(/\=\>/, ' => ')
            else
              if validator
                validator.to_s
              else
                arg_type == :block ? "Block" : "Any"
              end
            end

            {
              Ree::ObjectSchema::Methods::Args::ARG => arg.name,
              Ree::ObjectSchema::Methods::Args::ARG_TYPE => arg.type,
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

        private

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

              const_abs_path = mod.const_source_location(const.name)&.first
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

        def map_mapper_fields(fields, acc = {})
          fields.keys.each do |key|
            acc_key = fields[key].optional ? "#{key}?".to_sym : key
            acc[acc_key] = map_field(fields[key], {})
          end

          acc
        end

        def map_field(field, acc = {})
          if field.type.fields != {}
            map_mapper_fields(field.type.fields, acc)
          else
            type_klass = field.type.type.class
            type = demodulize(type_klass)

            case
            when type == "Array"
              subject_type = field.type.type.subject.type
              if subject_type.fields != {}
                "ArrayOf[#{map_mapper_fields(field.type.type.subject.type.fields)}]"
              else
                "ArrayOf[#{demodulize(field.type.type.subject.type.type.class)}]"
              end
            when %w(Any Bool DateTime Date Float Integer String Time).include?(type)
              field.null ? "Nilor[#{type}]" : type
            else
              field_type = field.type.type
              field_type.instance_variables.length > 0 ? field_type.instance_variable_get(field_type.instance_variables.first)&.to_s : type
            end
          end
        end

        def demodulize(klass)
          klass.to_s.split("::").last
        end
      end
    end
  end
end
