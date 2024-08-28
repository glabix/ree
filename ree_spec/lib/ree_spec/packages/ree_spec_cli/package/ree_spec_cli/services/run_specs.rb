class ReeSpecCli::RunSpecs
  include Ree::FnDSL

  fn :run_specs do
    link :in_groups_of, from: :ree_array
    link :run_package_specs
  end

  MAX_SPECS_PER_PROCESS = 1000

  contract ArrayOf[Symbol], Nilor[String], Nilor[String], ArrayOf[String], Bool, String, Integer, Integer => nil
  def call(package_names, spec_matcher, tag, files, run_all, project_path,
           process_count, specs_per_process)
    init_ree_project(project_path)

    packages = filter_packages_to_run(package_names, tag, run_all)
    specs_per_process = calculate_specs_per_process(process_count, specs_per_process)
    jobs = get_jobs(packages, specs_per_process, spec_matcher, files)

    processes = build_processes(process_count)
    error_files = []
    success_files = []

    jobs.each do |job|
      number = wait_for_vailable_process(processes)
      error_file, success_file = Tempfile.new, Tempfile.new
      error_files.push(error_file)
      success_files.push(success_file)

      processes[number] = Process.fork do
        print_start_message(job)
        result = run_package_specs(job.package, job.files, number)

        if result.status.exitstatus != 0
          error_file.write(result.out)
          error_file.rewind
          puts(result.out)
        else
          success_file.write(result.out)
          success_file.rewind
        end
      end
    end

    processes.each { |k, v| Process.wait(v) if !v.nil? }

    print_messages(error_files, success_files)

    nil
  end

  private

  def build_processes(process_count)
    result = {}

    process_count.times do |i|
      result[i] = nil
    end

    result
  end

  def print_start_message(job)
    puts("\n**** Running #{job.files.size} spec#{job.files.size == 1 ? "" : "s"} for #{job.package.name} ****\n")
  end

  def print_messages(error_files, success_files)
    success_files.each { puts(_1.read) }

    errors = error_files.map { _1.read }
    return if errors.empty?

    failures = errors
      .map { _1.split("Failed examples:")[1].to_s.strip }
      .compact
      .reject(&:empty?)
      .join("\n")

    puts("**** Failed examples from all specs: ****\n\n")
    puts(failures)
    puts("\n\n")
  ensure
    error_files.each(&:close)
    success_files.each(&:close)
  end

  def wait_for_vailable_process(processes)
    process = processes.find { |k, v| v.nil? }

    if process
      return process.first
    end

    number = nil

    processes.each do |k, v|
      Process.wait(v)
      processes[k] = nil
      number = k
      break
    end

    number
  end

  class Job < Struct.new(:package, :dir, :files); end

  def get_jobs(package_names, specs_per_process, spec_matcher, files)
    result = []
    packages = package_names.map { packages_facade.get_package(_1) }

    packages.each do |package|
      dir = Ree::PathHelper.abs_package_module_dir(package)

      spec_files = get_spec_files(package, spec_matcher, files)

      in_groups_of(spec_files, specs_per_process).each do |specs_group|
        result << Job.new(package, dir, specs_group)
      end
    end

    result
  end

  def get_spec_files(package, spec_matcher, files)
    package_dir = Ree::PathHelper.abs_package_dir(package)
    all_specs = Dir["#{package_dir}/spec/**/*_spec.rb"]

    if spec_matcher
      line_number = nil

      if spec_matcher.include?(":")
        parts = spec_matcher.split(":")
        spec_matcher = parts[0]
        line_number = parts[1]
      end

      file_path = File.join(package_dir, spec_matcher)

      if File.directory?(file_path)
        Dir["#{file_path}/**/*_spec.rb"]
      elsif File.exist?(file_path)
        if line_number
          ["#{file_path}:#{line_number}"]
        else
          [file_path]
        end
      else
        result = all_specs.select do |spec|
          spec =~ /#{spec_matcher.split('').join('.*')}/
        end

        if result.size == 0 && line_number
          ["#{result.first}:#{line_number}"]
        else
          result
        end
      end
    elsif files && files.size > 0
      files
    else
      all_specs
    end
  end

  def calculate_specs_per_process(process_count, specs_per_process)
    if process_count > 1
      specs_per_process
    else
      MAX_SPECS_PER_PROCESS
    end
  end

  def filter_packages_to_run(package_names, tag, run_all)
    packages_to_run = []

    if tag
      package_names = filter_existing_packages(package_names)
      tagged_packages = filter_packages_by_tag(package_names, tag)
      packages_to_run += tagged_packages
    elsif run_all
      packages_to_run += all_packages.map(&:name)
    else
      package_names = filter_existing_packages(package_names)
      packages_to_run += package_names
    end

    packages_to_run.uniq
  end

  def init_ree_project(project_path)
    schema_path = Ree.locate_packages_schema(project_path)
    schema_dir = Pathname.new(schema_path).dirname.to_s
    Ree.init(schema_dir)
    packages_facade.load_packages_schema
  end

  def packages_facade
    Ree.container.packages_facade
  end

  def all_packages
    packages_facade.packages_store.packages.select { !_1.gem? }
  end

  def filter_existing_packages(package_names)
    existing_packages = all_packages.map(&:name)
    extra_packages = package_names - existing_packages

    extra_packages.each do |package|
      puts "Package #{package} not found"
    end

    package_names - extra_packages
  end

  def filter_packages_by_tag(packages, tag)
    package_names = packages.map(&:name)

    package_names.select do |package_name|
      package = packages_facade.read_package_schema_json(package_name)
      package.tags.include?(tag)
    end
  end
end
