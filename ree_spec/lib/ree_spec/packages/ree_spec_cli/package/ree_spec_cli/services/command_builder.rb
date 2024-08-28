class ReeSpecCli::CommandBuilder
  include Commander::Methods

  DEFAULT_PROCESS_COUNT = 1

  def build(&action_proc)
    files = []
    package_names = []
    run_all = false
    process_count = DEFAULT_PROCESS_COUNT

    program :name, "Ree Spec"
    program :version, "1.0"
    program :description, "Ree extensions for Rspec framework"
    program :help, "Author", "Ruslan Gatiyatov"

    command :run do |c|
      c.syntax  = "ree spec PACKAGE_NAME SPEC_MATCHER [options]"
      c.description = "run tests for specified package"
      c.example "ree spec accounts", "Run specs for \"accounts\" package"
      c.example "ree spec -p accounts -p roles", "Run specs for several packages"
      c.example "ree spec accounts welcome_email:42", "Run specific spec from specified package using spec matcher"
      c.example "ree spec --tag wip", "Run specs for packages which have \"wip\" tag"
      c.option "--project_path [ROOT_DIR]", String, "Root project dir path"
      c.option "--tag TAG_NAME", String, "Run specs for packages with specified tag"
      c.option "--parallel PROCESS_COUNT", String, "Run specs in parallel processes (e.g. --parallel 15, 15 processes)"
      c.option "--only-failed", "Run only failed specs from previous run"

      c.option "-f SPEC_FILE", "--fule SPEC_FILE", String, "List of spec files" do |f|
        files ||= []
        files << f
      end

      c.option "-p PACKAGE_NAME", "--package PACKAGE_NAME", String, "List of packages" do |o|
        package_names << o.to_sym
      end

      c.action do |args, options|
        package_name = args[0]&.to_sym
        spec_matcher = args[1]

        if options.project_path
          path = File.expand_path(options.project_path.to_s)

          if !File.directory?(path)
            puts("Project path not found: #{options.project_path}")
            exit 1
          end

          options.project_path = File.expand_path(options.project_path.to_s)
        end

        if package_name
          package_names << package_name
        end

        if package_name.nil? && package_names.empty?
          run_all = true
        end

        if options.parallel
          process_count = Integer(options.parallel)
        end

        if package_names.size > 1
          files = []
        end

        action_proc.call(
          package_names, spec_matcher, options.tag, files,
          run_all, !!options.only_failed, options.project_path || File.expand_path(Dir.pwd),
          process_count
        )
      end
    end

    self
  end
end