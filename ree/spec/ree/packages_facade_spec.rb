# frozen_string_literal: true

RSpec.describe Ree::PackagesFacade do
  subject do
    Ree::PackagesFacade
  end

  describe '#self.write_packages_schema' do
    it 'writes Packages.schema.json file' do
      dir = sample_project_dir
      Ree.init(dir)

      subject.write_packages_schema
      packages_schema = File.join(dir, Ree::PACKAGES_SCHEMA_FILE)
      ensure_exists(packages_schema)

      schema = JSON.parse(File.read(packages_schema))
      
      expect(schema['packages'].size).not_to eq(0)
      expect(schema['gem_packages'].size).not_to eq(0)
    end
  end
end