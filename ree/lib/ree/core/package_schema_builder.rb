# frozen_string_literal  = true

require 'pathname'
require 'json'

class Ree::PackageSchemaBuilder
  Schema = Ree::PackageSchema

  # @param [Ree::Package] package
  # @return [Hash]
  def call(package)
    Ree.logger.debug("generating package schema for '#{package.name}' package")

    if !package.loaded?
      raise Ree::Error.new("package schema should be loaded", :invalid_schema)
    end
    
    data = {
      Schema::SCHEMA_TYPE => Schema::PACKAGE,
      Schema::SCHEMA_VERSION => Schema::SCHEMA_VERSION_NUMBER,
      Schema::NAME => package.name,
      Schema::ENTRY_PATH => package.entry_rpath,
      Schema::TAGS => package.tags,
      Schema::DEPENDS_ON => package.deps.sort_by(&:name).map { |dep|
        {
          Schema::DependsOn::NAME => dep.name,
        }
      },
      Schema::ENV_VARS => package.env_vars.sort_by(&:name).map { |var|
        {
          Schema::EnvVars::NAME => var.name,
          Schema::EnvVars::DOC => var.doc,
        }
      },
      Schema::OBJECTS => package.objects.select { !_1.rpath.nil? }.sort_by(&:name).map { |object|
        {
          Schema::Objects::NAME => object.name,
          Schema::Objects::SCHEMA => object.schema_rpath,
          Schema::Objects::TAGS => object.tags
        }
      }
    }

    data
  end
end