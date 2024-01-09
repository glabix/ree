# frozen_string_literal: true

require 'pathname'
require 'json'

class Ree::PackagesSchemaBuilder
  Schema = Ree::PackagesSchema

  def initialize
    @packages_detector = Ree::PackagesDetector.new
  end

  # @dir [String] - path to root project dir
  def call
    packages = @packages_detector.call(Ree.root_dir)
    gem_packages = []

    Ree.gems.each do |gem|
      gem_packages += @packages_detector.call(gem.dir, gem.name)
    end

    result = {
      Schema::SCHEMA_VERSION => Schema::SCHEMA_VERSION_NUMBER,
      Schema::SCHEMA_TYPE => Schema::PACKAGES,
      Schema::PACKAGES => packages.sort_by { _1[:name] }.map {
        {
          Schema::Packages::NAME => _1.fetch(:name),
          Schema::Packages::SCHEMA => _1.fetch(:package_schema_path),
        }
      },
      Schema::GEM_PACKAGES => gem_packages.sort_by { [_1.fetch(:gem_name), _1.fetch(:name)] }.map {
        {
          Schema::Packages::GEM => _1.fetch(:gem_name),
          Schema::Packages::NAME => _1.fetch(:name),
          Schema::Packages::SCHEMA => _1.fetch(:package_schema_path),
        }
      },
    }

    result
  end
end