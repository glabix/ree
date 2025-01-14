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
          package_names: nil,
          spec_matcher: nil,
          with_ancestors: nil,
          with_children: nil,
          tag_name: nil
        )
      }.not_to raise_error
    end

    it 'run tests for specified package without errors' do
      expect {
        subject.run(
          path: project_dir,
          package_names: [:accounts],
          spec_matcher: nil,
          with_ancestors: nil,
          with_children: nil,
          tag_name: nil
        )
      }.not_to raise_error
    end

    it 'run tests for several specified packages without errors' do
      expect {
        subject.run(
          path: project_dir,
          package_names: [:accounts, :roles],
          spec_matcher: nil,
          with_ancestors: nil,
          with_children: nil,
          tag_name: nil
        )
      }.not_to raise_error
    end

    it 'run tests for specified package and spec_matcher without errors' do
      expect {
        subject.new(
          path: project_dir,
          package_names: [:accounts],
          spec_matcher: 'build_user:6',
          with_ancestors: nil,
          with_children: nil,
          tag_name: nil
        ).run
      }.not_to raise_error
    end

    it 'run tests for ancestors packages of specified package' do
      spec_runner = subject.new(
        path: project_dir,
        package_names: [:test_utils],
        spec_matcher: nil,
        with_ancestors: true,
        with_children: nil,
        tag_name: nil
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
        spec_matcher: nil,
        with_ancestors: nil,
        with_children: true,
        tag_name: nil
      )
      expect {
        spec_runner.run
      }.not_to raise_error

      expect(spec_runner.packages_to_run.size).to be >= 1
    end

    it 'run tests for packages with specified tag' do
      spec_runner = subject.new(
        path: project_dir,
        package_names: nil,
        spec_matcher: nil,
        with_ancestors: nil,
        with_children: nil,
        tag_name: 'wip'
      )
      expect {
        spec_runner.run
      }.not_to raise_error

      expect(spec_runner.packages_to_run.size).to be >= 1
    end
  end
end
