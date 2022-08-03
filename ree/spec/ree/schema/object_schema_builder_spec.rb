# frozen_string_literal: true

RSpec.describe Ree::ObjectSchemaBuilder do
  subject do
    Ree::ObjectSchemaBuilder.new
  end

  it 'builds valid schema for valid objects' do
    dir = sample_project_dir
    Ree.init(dir)

    package_name = :accounts
    object_name = :register_account_cmd
    Ree.load_package(package_name)
    object = Ree.container.packages_facade.get_object(package_name, object_name)

    schema_path = Ree::PathHelper.abs_object_schema_path(object)

    schema = subject.call(object)
    json_schema = JSON.pretty_generate(schema)
    valid_schema = File.read(File.join(__dir__, 'samples/object_schemas/valid.package.json'))
    expect(json_schema).to eq(valid_schema)
  end
end