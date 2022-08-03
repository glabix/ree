# frozen_string_literal  = true

require 'json'

class Ree::PackagesSchemaLoader
  # Sample Packages.schema.json
  # {
  #   "schema_type": "packages",
  #   "schema_version": "1.2.3",
  #   "packages": [
  #     {
  #       "name": "accounts",
  #       "schema": "bc/accounts/Package.schema.json"
  #     },
  #     {
  #       "name": "tests",
  #       "schema": "bc/tests/Package.schema.json"
  #     }
  #   ]
  # }
  
  Schema = Ree::PackagesSchema
  
  # @param [String] path Absolute path to Packages.schema.json file
  # @param Nilor[Ree::PackagesStore] packages_store Existing packages store
  # @return [Ree::PackagesStore]
  def call(abs_schema_path, packages_store = nil, gem_name = nil)
    if !File.exists?(abs_schema_path)
      raise Ree::Error.new("File not found: #{abs_schema_path}", :invalid_packages_schema)
    end

    schema = begin
      JSON.load_file(abs_schema_path)
    rescue
      raise Ree::Error.new("Invalid content: #{abs_schema_path}", :invalid_packages_schema)
    end

    schema_type = schema.fetch(Schema::SCHEMA_TYPE)
    
    if schema_type != Schema::PACKAGES
      raise Ree::Error.new("Invalid schema type: #{abs_schema_path}", :invalid_packages_schema)
    end

    # binding.irb

    schema_version = schema.fetch(Schema::SCHEMA_VERSION)
    data = schema.fetch(Schema::PACKAGES)
    packages_store ||= Ree::PackagesStore.new()
    names = {}

    data.each do |item|
      name = item[Schema::Packages::NAME].to_s
      schema_rpath = item[Schema::Packages::SCHEMA].to_s
      list = [name, schema]

      if list.reject(&:empty?).size != list.size
        raise Ree::Error.new("invalid package data for: #{item.inspect}", :invalid_packages_schema)
      end

      if names.has_key?(name)
        raise Ree::Error.new("duplicate package name for '#{item[:name]}'", :invalid_packages_schema)
      end

      names[name] = true

      package = Ree::Package.new(
        schema_version,
        name.to_sym,
        Ree::PathHelper.package_entry_path(schema_rpath),
        schema_rpath,
        gem_name
      )

      existing = packages_store.get(package.name)

      if existing && existing.gem_name != package.gem_name
        if existing.gem_name.nil?
          raise Ree::Error.new("Unable to add package `#{existing.name}` from `#{package.gem_name}` gem. Project has same package definition.", :duplicate_package)
        else
          raise Ree::Error.new("Unable to add package `#{existing.name}` from `#{package.gem_name}` gem. Package was already added from `#{existing.gem_name}` gem.", :duplicate_package)
        end
      end
      
      packages_store.add_package(
        Ree::Package.new(
          schema_version,
          name.to_sym,
          Ree::PathHelper.package_entry_path(schema_rpath),
          schema_rpath,
          gem_name
        )
      )
    end

    packages_store
  end
end