RSpec.describe Ree::CLI::GenerateObjectSchema do
  subject { described_class }

  let(:project_dir) { sample_project_dir }
  let(:package_name) { "accounts" }
  let(:object_path) { "sample_project/bc/accounts/package/accounts/commands/register_account_cmd.rb"}
  let(:object_schema_dir) { File.join(project_dir, "bc", package_name, Ree::SCHEMAS, package_name, "commands") }
  let(:object_schema_filename) { "register_account_cmd.schema.json" }

  context "run" do
    it "generates register_account_cmd.schema.json for specified package" do
      subject.run(
        package_name: package_name,
        object_path: object_path,
        project_path: project_dir,
        silence: true
      )

      FileUtils.cd(object_schema_dir) do
        ensure_exists(object_schema_filename)
      end
    end

    it "output path for package schema" do
      output = with_captured_stdout {
        subject.run(
          package_name: package_name,
          object_path: object_path,
          project_path: project_dir,
          silence: false
        )
      }

      expect(output).to include(File.join(object_schema_dir, object_schema_filename))
    end

    it "show error for wrong object path" do
      expect {
        subject.run(
          package_name: package_name,
          object_path: "wrong/path/file.rb",
          project_path: project_dir,
          silence: false
        )
      }.to raise_error(Ree::Error)
    end
  end
end
