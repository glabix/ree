# frozen_string_literal: true

class Ree::PackagesSchemaLocator
  def call(path)
    find_source_path_in_hierarchy(path)
  end

  private

  def find_source_path_in_hierarchy(some_path)
    some_path = File.expand_path(some_path)

    raise Ree::Error.new("#{Ree::PACKAGES_SCHEMA_FILE} not found", :packages_json_not_found) if some_path == '/'

    return potential_file(some_path) if present?(some_path)

    find_source_path_in_hierarchy(File.dirname(some_path))
  end

  def present?(some_path)
    File.exist?(potential_file(some_path))
  end

  def potential_file(some_path)
    File.join(some_path, Ree::PACKAGES_SCHEMA_FILE)
  end
end