RSpec.describe Ree::CLI::DeleteObjectSchema do
  subject { described_class }

  let(:project_dir) { sample_project_dir }
  let(:package_name) { "accounts" }
  let(:object_path) { "bc/accounts/package/accounts/commands/register_account_cmd.rb"}
  let(:object_schema_dir) { File.join(project_dir, "bc", package_name, Ree::SCHEMAS, package_name, "commands") }
  let(:object_schema_filename) { "register_account_cmd.schema.json" }

  after(:each) do
    # make sure we regenerate schema
    Ree::CLI::GenerateObjectSchema.run(
      package_name: package_name,
      object_path: object_path,
      project_path: project_dir,
      silence: true
    )
  end

  context "run" do
    it "deletes register_account_cmd.schema.json for specified package" do
      subject.run(
        object_path: object_path,
        project_path: project_dir,
        silence: true
      )

      FileUtils.cd(object_schema_dir) do
        ensure_not_exists(object_schema_filename)
      end
    end
  end
end
