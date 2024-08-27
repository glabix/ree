class ReeSpecCli::CommandBuilder
  include Commander::Methods

  DEFAULT_PROCESS_COUNT = 1
  DEFAULT_SPECS_PER_PROCESS_COUNT = 5

  def build(&action_proc)
    files = []
    package_names = []
    run_all = false
    process_count = DEFAULT_PROCESS_COUNT
    specs_per_process = DEFAULT_SPECS_PER_PROCESS_COUNT

    program :name, "Ree Spec"
    program :version, ReeSpec::VERSION
    program :description, "Ree extensions for Rspec framework"
    program :help, "Author", "Ruslan Gatiyatov"

    command :"spec" do |c|
      c.syntax  = "ree spec PACKAGE_NAME SPEC_MATCHER [options]"
      c.description = "run tests for specified package"
      c.example "ree spec accounts", "Run specs for \"accounts\" package"
      c.example "ree spec -p accounts -p roles", "Run specs for several packages"
      c.example "ree spec accounts welcome_email:42", "Run specific spec from specified package using spec matcher"
      c.example "ree spec --tag wip", "Run specs for packages which have \"wip\" tag"
      c.option "--project_path [ROOT_DIR]", String, "Root project dir path"
      c.option "--tag TAG_NAME", String, "Run specs for packages with specified tag"
      c.option "--parallel", String, "Run specs in parallel processes (e.g. --parallel 15:5, 15 processes, max 5 package spec files per process)"

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
        options_hash = options.__hash__
        options_hash.delete(:trace)

        if options_hash[:project_path]
          options_hash[:project_path] = File.expand_path(options_hash[:project_path])
        end

        if package_name
          package_names << package_name
        end

        if package_name.nil? && options_hash.keys.empty? && spec_matcher.nil? && package_names.empty?
          run_all = true
        end

        if options[:parallel]
          parallel = options[:parallel].split(":")[0..1]
          process_count = Integer(parallel.first)

          if parallel.size > 1
            specs_per_process = Integer(parallel.last)
          end
        end

        if package_names.size > 1
          files = []
        end

        action_proc.call(
          package_names, spec_matcher, options_hash[:tag], files,
          run_all, options_hash[:project_path] || File.expand_path(Dir.pwd),
          process_count, specs_per_process
        )
      end
    end

    self
  end
end