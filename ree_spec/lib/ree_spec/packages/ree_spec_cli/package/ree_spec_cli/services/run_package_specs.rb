require "fileutils"

class ReeSpecCli::RunPackageSpecs
  include Ree::FnDSL

  fn :run_package_specs

  contract(Ree::Package, ArrayOf[String] => nil)
  def call(package, files)
    package_path = File.join(Ree.root_dir, package.dir)
    package_spec_path = File.join(package_path, 'spec')
    package_spec_helper = File.join(package_path, 'spec', 'spec_helper.rb')

    puts("**** Package: #{package.name}  *****")

    FileUtils.cd(Ree.root_dir) do
      system("bundle exec rspec --color --tty #{files.join(" ")} --default-path=#{package_spec_path} --require=#{package_spec_helper}")
    end

    nil
  end
end