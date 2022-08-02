# frozen_string_literal: true

RSpec.describe Ree::ObjectSchemaBuilder do
  subject do
    Ree::ObjectSchemaBuilder.new
  end

  it 'builds valid schema for valid objects' do
    dir = sample_project_dir
    Ree.init(dir)

    Ree.load_package(:accounts)
    object = Ree.container.packages_facade.get_object(:accounts, :register_account_cmd)

    schema_path = Ree::PathHelper.abs_object_schema_path(object)

    schema = subject.call(object, schema_path)
    parsed_schema = JSON.parse(schema)
    valid_schema = JSON.parse(File.read(File.join(__dir__, 'samples/object_schemas/valid.package.json')))
    expect(parsed_schema).to eq(valid_schema)
  end
end