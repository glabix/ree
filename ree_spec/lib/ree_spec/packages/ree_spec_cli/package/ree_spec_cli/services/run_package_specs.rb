require "open3"
require "fileutils"

class ReeSpecCli::RunPackageSpecs
  include Ree::FnDSL

  fn :run_package_specs

  class CommandResult < Struct.new(:out, :err, :status); end


  contract(Ree::Package, ArrayOf[String], Integer => CommandResult)
  def call(package, files, test_env_number)
    package_path = File.join(Ree.root_dir, package.dir)
    package_spec_path = File.join(package_path, 'spec')
    package_spec_helper = File.join(package_path, 'spec', 'spec_helper.rb')
    result = nil

    FileUtils.cd(Ree.root_dir) do
      result = run_shell_command(
        "TEST_ENV_NUMBER=#{test_env_number} bundle exec rspec --color --tty #{files.join(" ")} --default-path=#{package_spec_path} --require=#{package_spec_helper}"
      )
    end

    result
  end

  private

  def run_shell_command(command)
    out_str = ""
    err_str = ""
    status = nil

    Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
      stdout.each_line do |line|
        out_str << line
      end

      stderr.each_line do |line|
        err_str << line
      end

      status = wait_thr.value
    end

    CommandResult.new(out_str, err_str, status)
  end
end