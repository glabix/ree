# frozen_string_literal: true

require 'json'
require 'pathname'

class Ree::PackageSchemaLoader
  # Sample Package.schema.json
  # {
  #   "schema_type": "package",
  #   "schema_version": "1.2.3",
  #   "name": "accounts",
  #   "entry_path": "package/accounts.rb",
  #   "depends_on": [
  #     {
  #       "name": "clock",
  #     },
  #     {
  #       "name": "test_utils",
  #     }
  #   ],
  #   "env_vars": [
  #     {
  #       "name": "accounts.string_var",
  #       "doc": null
  #     },
  #     {
  #       "name": "accounts.integer_var",
  #       "doc": "integer value"
  #     }
  #   ],
  #   "objects": [
  #     {
  #       "name": "accounts_cfg",
  #       "schema": "schemas/accounts/accounts_cfg.schema.json"
  #     },
  #     {
  #       "name": "transaction",
  #       "schema": "schemas/accounts/transaction.schema.json"
  #     }
  #   ]
  # }

  Schema = Ree::PackageSchema

  # @param [String] abs_schema_path Absolute path to package Package.schema.json file
  # @param [Nilor[Ree::Package]] existing_package Loaded package
  # @return [Ree::Package]
  def call(abs_schema_path, existing_package = nil)
    if !File.exist?(abs_schema_path)
      raise Ree::Error.new("File not found: #{abs_schema_path}", :invalid_package_schema)
    end

    json_schema = begin
      JSON.load_file(abs_schema_path)
    rescue
      raise Ree::Error.new("Invalid content: #{abs_schema_path}", :invalid_package_schema)
    end

    schema_type = json_schema.fetch(Schema::SCHEMA_TYPE)

    if schema_type != Schema::PACKAGE
      raise Ree::Error.new("Invalid schema type: #{abs_schema_path}", :invalid_package_schema)
    end

    schema_version = json_schema.fetch(Schema::SCHEMA_VERSION) { Schema::SCHEMA_VERSION_NUMBER }
    entry_rpath = json_schema.fetch(Schema::ENTRY_PATH)
    package_name = json_schema.fetch(Schema::NAME).to_sym

    root_dir = if existing_package && existing_package.gem?
      Ree.gem(existing_package.gem_name).dir
    else
      Ree.root_dir
    end

    schema_rpath = Pathname
      .new(abs_schema_path)
      .relative_path_from(Pathname.new(root_dir))
      .to_s

    object_store = {}
    deps_store = {}
    vars_store = {}

    package = if existing_package
      existing_package
        .set_schema_version(schema_version)
        .set_entry_rpath(entry_rpath)
        .set_schema_rpath(schema_rpath)
    else
      Ree::Package.new(
        schema_version,
        package_name,
        entry_rpath,
        schema_rpath,
        nil
      )
    end

    package.set_schema_loaded

    json_schema.fetch(Schema::OBJECTS).each do |item|
      name = item[Schema::Objects::NAME].to_s
      schema_rpath = item[Schema::Objects::SCHEMA].to_s
      list = [name, schema_rpath]
      tags = item[Schema::Objects::TAGS] || []

      if list.reject(&:empty?).size != list.size
        raise Ree::Error.new("invalid object data for #{item.inspect}: #{abs_schema_path}", :invalid_package_schema)
      end

      if object_store.has_key?(name)
        raise Ree::Error.new("duplicate object name for '#{item[:name]}': #{abs_schema_path}", :invalid_package_schema)
      end

      object_store[name] = true

      object = Ree::Object.new(
        name.to_sym,
        schema_rpath,
        Ree::PathHelper.object_rpath(schema_rpath),
      )

      object.add_tags(tags)
      object.set_package(package.name)

      package.set_object(object)
    end

    deps = json_schema.fetch(Schema::DEPENDS_ON).map do |item|
      name = item[Schema::DependsOn::NAME].to_sym
      list = [name]

      if list.reject(&:empty?).size != list.size
        raise Ree::Error.new("invalid depends_on for: #{item.inspect}", :invalid_package_schema)
      end

      if deps_store.has_key?(name)
        raise Ree::Error.new("duplicate depends_on name for '#{item[:name]}'", :invalid_package_schema)
      end

      deps_store[name] = true
      Ree::PackageDep.new(name)
    end

    package.set_deps(deps)

    env_vars = json_schema.fetch(Schema::ENV_VARS).map do |item|
      name = item[Schema::EnvVars::NAME].to_s
      doc = item[Schema::EnvVars::DOC]
      list = [name]

      if list.reject(&:empty?).size != list.size
        raise Ree::Error.new("invalid env_var for: #{item.inspect}", :invalid_package_schema)
      end

      if vars_store.has_key?(name)
        raise Ree::Error.new("duplicate env_var name for '#{item[:name]}'", :invalid_package_schema)
      end

      vars_store[name] = true

      Ree::PackageEnvVar.new(name, doc)
    end

    package.set_env_vars(env_vars)

    tags = json_schema.fetch(Schema::TAGS)
    package.set_tags(tags)

    package
  end
end