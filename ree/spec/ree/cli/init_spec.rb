RSpec.describe Ree::CLI::Init do
  subject { described_class }

  let(:example_project_path) { '/tmp/example_project' }
  before {
    Dir.mkdir(example_project_path)
  }

  after {
    FileUtils.rm_rf(example_project_path)
  }

  context "run" do
    it "generates package" do
      subject.run(
        project_path: example_project_path,
        console:     "irb",
        test:        "rspec",
        stdout:      $stdout
      )

      FileUtils.cd(example_project_path) do
        ensure_exists(Ree::PACKAGES_SCHEMA_FILE)
        ensure_exists("Gemfile")
        ensure_exists("ree.setup.rb")
      end
    end

    it "output list of generated files" do
      output = with_captured_stdout {
        subject.run(
          project_path: example_project_path,
          console: "irb",
          test: "rspec",
          stdout: $stdout
        )
      }
      expect(output).to include("Generated: #{Ree::PACKAGES_SCHEMA_FILE}")
    end
  end
end
