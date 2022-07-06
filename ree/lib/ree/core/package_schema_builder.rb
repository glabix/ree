# frozen_string_literal  = true

require 'pathname'
require 'json'

class Ree::PackageSchemaBuilder
  Schema = Ree::PackageSchema

  # @param [Ree::Package] package
  # @param [String] - abs_path Absolute path to Package.schema.json file (ex. /project/bc/accounts/Package.schema.json)
  # @return [nil]
  def call(package, abs_path)
    Ree.logger.debug("generating package schema for '#{package.name}' package")

    if !File.exists?(abs_path)
      raise Ree::Error.new("File does not exist: #{abs_path}", :invalid_path)
    end

    if !package.loaded?
      raise Ree::Error.new("package schema should be loaded", :invalid_schema)
    end
    
    data = {
      Schema::SCHEMA_TYPE => Schema::PACKAGE,
      Schema::REE_VERSION => Ree::VERSION,
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
        }
      }
    }

    json = JSON.pretty_generate(data)

    File.write(abs_path, json, mode: 'w')
    nil
  end
end