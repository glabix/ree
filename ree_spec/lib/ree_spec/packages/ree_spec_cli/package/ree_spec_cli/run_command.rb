require "commander"

class ReeSpecCli::RunCommand
  include Ree::FnDSL

  fn :run_command do
    link "ree_spec_cli/services/command_builder", -> { CommandBuilder }
    link :run_specs
  end

  def call
    action_proc = Proc.new do |package_names, spec_matcher, tag, files, run_all, only_failed, project_path, process_count|
      run_specs(
        package_names, spec_matcher, tag, files, run_all, only_failed,
        project_path, process_count
      )
    end

    command = CommandBuilder.new.build(&action_proc)
    command.run!
  end
end