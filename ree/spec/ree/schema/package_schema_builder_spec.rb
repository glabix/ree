# frozen_string_literal: true

RSpec.describe Ree::PackageSchemaBuilder do
  subject do
    Ree::PackageSchemaBuilder.new
  end

  xit 'builds valid Packages.schema.json' do
    dir = sample_project_dir
    Ree.init(dir)

    package_name = :accounts
    facade = Ree.container.packages_facade
    facade.load_entire_package(package_name)
    package = facade.get_package(package_name)

    schema = subject.call(package)
    json_schema = JSON.pretty_generate(schema)

    valid_json_schema = File.read(File.join(__dir__, 'samples/package_schemas/valid.package.json'))

    expect(json_schema).to eq(valid_json_schema)
  end
end