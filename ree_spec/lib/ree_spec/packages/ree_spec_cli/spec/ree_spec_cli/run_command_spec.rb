# frozen_string_literal: true

RSpec.describe :run_command do
  link :run_command, from: :ree_spec_cli

  it {
    project_path =  File.expand_path(
      File.join(__dir__, "../../../../../../../ree/spec/sample_project")
    )

    ARGV.clear
    ARGV << "run"
    ARGV << "accounts"
    ARGV << "--project_path"
    ARGV << project_path
    ARGV << "--parallel"
    ARGV << "2"

    run_command()
  }

  it {
    project_path =  File.expand_path(
      File.join(__dir__, "../../../../../../../ree/spec/sample_project")
    )

    ARGV.clear
    ARGV << "run"
    ARGV << "accounts"
    ARGV << "build_user"
    ARGV << "--project_path"
    ARGV << project_path

    run_command()
  }
end