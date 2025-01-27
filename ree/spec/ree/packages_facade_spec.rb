# frozen_string_literal: true

RSpec.describe Ree::PackagesFacade do
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

  describe '#load_entire_package' do
    it 'loads package objects' do
      facade = Ree.container.packages_facade 

      package = facade.load_entire_package(:documents)
  
      expect{ Documents::CreateDocumentCmd }.not_to raise_error
      expect{ Accounts::DeliverEmail }.not_to raise_error
      expect{ HashUtils::Except }.not_to raise_error
    end
  end
end