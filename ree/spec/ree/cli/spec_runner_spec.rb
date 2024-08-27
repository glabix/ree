RSpec.describe Ree::CLI::SpecRunner do
  subject { described_class }

  let(:project_dir) { sample_project_dir }
  after { Ree.init(project_dir) }

  describe "::run" do
    it 'run all test without errors' do
      expect {
        subject.run(
          path: project_dir,
          run_all: true,
        )
      }.not_to raise_error
    end

    it 'run tests for specified package without errors' do
      expect {
        subject.run(
          path: project_dir,
          package_names: [:accounts],
        )
      }.not_to raise_error
    end

    it 'run tests for several specified packages without errors' do
      expect {
        subject.run(
          path: project_dir,
          package_names: [:accounts, :roles],
        )
      }.not_to raise_error
    end

    it 'run tests for specified package and spec_matcher without errors' do
      expect {
        subject.new(
          path: project_dir,
          package_names: [:accounts],
          spec_matcher: 'build_user:6',
        ).run
      }.not_to raise_error
    end

    it 'run tests for ancestors packages of specified package' do
      spec_runner = subject.new(
        path: project_dir,
        package_names: [:test_utils],
        with_ancestors: true,
      )
      expect {
        spec_runner.run
      }.not_to raise_error

      expect(spec_runner.packages_to_run.size).to be >= 1
    end

    it 'run tests for children packages of specified package' do
      spec_runner = subject.new(
        path: project_dir,
        package_names: [:accounts],
        with_children: true,
      )
      expect {
        spec_runner.run
      }.not_to raise_error

      expect(spec_runner.packages_to_run.size).to be >= 1
    end

    it 'run tests for packages with specified tag' do
      spec_runner = subject.new(
        path: project_dir,
        tag_name: 'wip'
      )
      expect {
        spec_runner.run
      }.not_to raise_error

      expect(spec_runner.packages_to_run.size).to be >= 1
    end

    it 'run tests for specified package and filenames' do
      expect {
        subject.new(
          path: project_dir,
          package_names: [:accounts, :test_utils],
          filenames: ["build_user_spec.rb", "deliver_email_spec.rb", "json_pretty_printer_spec.rb"],
        ).run
      }.not_to raise_error

      expect {
        subject.new(
          path: project_dir,
          spec_matcher: "hello",
          package_names: [:accounts, :test_utils],
          filenames: ["build_user_spec.rb", "deliver_email_spec.rb", "json_pretty_printer_spec.rb"],
        ).run
      }.to raise_error(
        Ree::Error,
        "Filenames option cannot be used with SPEC_MATCHER"
      )
    end
  end
end
