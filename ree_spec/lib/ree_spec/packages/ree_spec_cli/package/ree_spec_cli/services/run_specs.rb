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

    print_message(packages, tag, run_all)

    specs_per_process = calculate_specs_per_process(process_count, specs_per_process)
    jobs = get_jobs(packages, specs_per_process, spec_matcher, files)

    jobs.each do |job|
      run_package_specs(job.package, job.files)
    end

    nil
  end

  private

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

      if File.exist?(file_path)
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

  def print_message(packages, tag, run_all)
    if tag
      puts("Mode: Tagged packages")
    elsif run_all
      puts "Mode: All packages"
    else
      puts "Mode: Selected packages"
    end

    if packages.size == 1
      puts("Running specs for #{packages.size} package")
    else
      puts("Running specs for #{packages.size} packages")
    end
  end

  def filter_packages_to_run(package_names, tag, run_all)
    packages_to_run = []

    if tag
      package_names = filter_existing_packages(package_names)
      tagged_packages = filter_packages_by_tag(package_names, tag)
      packages_to_run += tagged_packages
      puts("Tagged packages run")
    elsif run_all
      packages_to_run += all_packages.map(&:name)
      puts "All packages run"
    else
      package_names = filter_existing_packages(package_names)
      packages_to_run += package_names
    end

    packages_to_run = packages_to_run.uniq

    if packages_to_run.size == 1
      puts("Running specs for #{packages_to_run.size} package")
    else
      puts("Running specs for #{packages_to_run.size} packages")
    end

    packages_to_run
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
