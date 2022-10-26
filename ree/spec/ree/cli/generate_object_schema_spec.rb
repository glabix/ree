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

    it "generates schema.json for new object" do
      new_object_file_rpath = "bc/accounts/package/accounts/commands/definitely_new_object.rb"
      new_object_file_abs_path = File.join(project_dir, new_object_file_rpath)

      if File.exists?(new_object_file_abs_path)
        FileUtils.rm(new_object_file_abs_path)
      else
        new_object_content = <<-NEW_OBJECT
        class Accounts::DefinitelyNewObject
          include Ree::FnDSL
        
          fn :definitely_new_object do
          end
        
          contract(None => nil)
          def call()
          end
        end
        NEW_OBJECT
  
        File.open(
          new_object_file_abs_path,
          'w+'
        ) { |f| f.write new_object_content }
      end 

      subject.run(
        package_name: package_name,
        object_path: new_object_file_rpath,
        project_path: project_dir,
        silence: true
      )

      FileUtils.cd(object_schema_dir) do
        ensure_exists("definitely_new_object.schema.json")
      end

      FileUtils.cd(project_dir) do
        package_schema = JSON.parse(File.open(File.join(project_dir, "bc", "accounts", "Package.schema.json")).read)
        expect(package_schema.dig("objects").find { |o| o["name"] == "definitely_new_object" }).to_not eq(nil)
      end

      FileUtils.rm(new_object_file_abs_path)
      FileUtils.rm(File.join(object_schema_dir, "definitely_new_object.schema.json"))
      Ree::CLI::GeneratePackageSchema.run(
        package_name: package_name,
        project_path: project_dir,
        include_objects: true,
        silence: false
      )
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
