RSpec.describe Ree::CLI::GeneratePackageSchema do
  subject { described_class }

  let(:project_dir) { sample_project_dir }
  let(:package_name) { "accounts" }

  context "run" do
    it "generates Package.schema.json for specified package" do
      subject.run(
        package_name: package_name,
        project_path: project_dir,
        include_objects: true
      )

      package_dir = File.join(project_dir, "bc", package_name)
      
      FileUtils.cd(package_dir) do
        ensure_exists(Ree::PACKAGE_SCHEMA_FILE)
      end
    end

    it "output path for package schema" do
      output = with_captured_stdout {
        subject.run(
          package_name: package_name,
          project_path: project_dir,
          include_objects: true
        )
      }
      
      expect(output).to include(Ree::PACKAGE_SCHEMA_FILE)
    end
  end
end
