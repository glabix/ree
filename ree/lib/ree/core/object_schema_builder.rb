# frozen_string_literal  = true

class Ree::ObjectSchemaBuilder
  Schema = Ree::ObjectSchema

  # @param [Ree::Object] object
  # @return [Hash]
  def call(object)
    Ree.logger.debug("generating object schema for '#{object.name}' package")

    if !object.loaded?
      raise Ree::Error.new("object `#{object.name}` from package `#{object.package_name}` is not loaded", :invalid_schema)
    end

    data = {
      Schema::SCHEMA_TYPE => Schema::OBJECT,
      Schema::SCHEMA_VERSION => Schema::SCHEMA_VERSION_NUMBER,
      Schema::NAME => object.name,
      Schema::PATH => object.rpath,
      Schema::MOUNT_AS => object.mount_as,
      Schema::CLASS => object.klass.name,
      Schema::FACTORY => object.factory,
      Schema::METHODS => map_object_methods(object),
      Schema::LINKS => object.links.sort_by(&:object_name).map { |link|
        {
          Schema::Links::TARGET => link.object_name,
          Schema::Links::PACKAGE_NAME => link.package_name,
          Schema::Links::AS => link.as,
          Schema::Links::IMPORTS => link.constants
        }
      }
    }

    data
  end

  private

  Arg = Ree::Contracts::CalledArgsValidator::Arg

  def map_object_methods(object)
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
          res[param.last] = Arg.new(
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
        Schema::Methods::Args::ARG => arg.name,
        Schema::Methods::Args::ARG_TYPE => arg.name,
        Schema::Methods::Args::TYPE => type
      }
    end

    [
      {
        Schema::Methods::DOC => method_decorator&.doc || "",
        Schema::Methods::THROWS => method_decorator&.errors&.map { _1.name } || [],
        Schema::Methods::RETURN => method_decorator&.contract_definition&.return_contract || "Any",
        Schema::Methods::ARGS => arg_list
      }
    ]
  end
end
