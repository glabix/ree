# frozen_string_literal: true

RSpec.describe Ree::PackagesFacade do
  subject do
    Ree::PackagesFacade.new
  end

  describe '#self.write_packages_schema' do
    it 'writes Packages.schema.json file' do
      dir = sample_project_dir
      Ree.init(dir)

      facade = Ree.container.packages_facade
      facade.class.write_packages_schema

      packages_schema = File.join(dir, Ree::PACKAGES_SCHEMA_FILE)
      ensure_exists(packages_schema)
    end
  end

  describe '#write_package_schema' do
    it 'writes Package.schema.json file for package' do
      dir = sample_project_dir
      Ree.init(dir)

      facade = Ree.container.packages_facade
      package = facade.load_entire_package(:accounts)

      facade.write_package_schema(package.name)

      package_schema = File.join(dir, package.schema_rpath)
      ensure_exists(package_schema)
    end
  end
end