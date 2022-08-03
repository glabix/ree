# frozen_string_literal: true

RSpec.describe Ree::PackagesSchemaBuilder do
  subject do
    Ree::PackagesSchemaBuilder.new
  end

  it 'builds valid Packages.schema.json' do
    dir = sample_project_dir
    Ree.init(dir)

    schema = subject.call
    json_schema = JSON.pretty_generate(schema)

    valid_json_schema = File.read(File.join(__dir__, 'samples/packages_schemas/valid.packages.json'))

    expect(json_schema).to eq(valid_json_schema)
  end
end