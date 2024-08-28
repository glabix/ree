class ReeSpecCli::RunSpecs
  include Ree::FnDSL

  fn :run_specs do
    link :run_package_specs
    link :from_json, from: :ree_json
    link :symbolize_keys, from: :ree_hash
    link :group_by, from: :ree_array
    link :index_by, from: :ree_array
    link :to_hash, from: :ree_object
    link :to_json, from: :ree_json
  end

  SPEC_META_FILENAME = "ree_spec_meta.json"

  contract ArrayOf[Symbol], Nilor[String], Nilor[String], ArrayOf[String], Bool, Bool, String, Integer => nil
  def call(package_names, spec_matcher, tag, files, run_all, only_failed, project_path, process_count)
    init_ree_project(project_path)

    packages = filter_packages_to_run(package_names, tag, run_all)
    jobs, meta_index = get_jobs(packages, spec_matcher, files, only_failed)
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

        prev_meta = meta_index[job.abs_path]
        start_time = Time.now

        result = run_package_specs(job.package, [job.abs_path], number)

        end_time = Time.now
        exec_time = end_time - start_time
        is_success = result.status.exitstatus == 0

        duration = if is_success
          exec_time
        elsif prev_meta
          prev_meta.duration
        else
          exec_time
        end

        update_scan_metadata(
          SpecMeta.new(
            package: job.package.name.to_s,
            abs_path: job.abs_path,
            duration: duration,
            last_scan_at: Time.now,
            success: is_success
          )
        )

        if !is_success
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
      result[i+1] = nil
    end

    ['INT', 'TERM'].each do |signal|
      trap(signal) do
        shutdown(processes)
        exit
      end
    end

    result
  end

  def shutdown(processes)
    processes.each do |number, pid|
      Process.kill('TERM', pid) if !pid.nil?
    rescue Errno::ESRCH
    end

    processes.each do |number, pid|
      Process.wait(pid) if !pid.nil?
    rescue Errno::ECHILD
    end

    puts "All child processes terminated"
  end

  def print_start_message(job)
    puts("Running spec for :#{job.package.name}:\n#{job.abs_path}")
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

    pid = Process.wait
    number = processes.find { |_, v| v == pid }.first
    processes[number] = nil
    number
  end

  class Job
    include ReeDto::DSL

    build_dto do
      field :package, Ree::Package
      field :abs_path, String
    end
  end

  def get_jobs(package_names, spec_matcher, files, only_failed)
    prev_scan_meta = read_prev_scan_metadata
    result = []
    packages = package_names.map { packages_facade.get_package(_1) }
    scan_index = index_by(prev_scan_meta) { _1.abs_path }

    packages.each do |package|
      spec_files = get_spec_files(package, spec_matcher, files)

      spec_files.each do |abs_path|
        result << Job.new(package:, abs_path:)
      end
    end

    if only_failed
      result = result.select do |item|
        if scan_index[item.abs_path]
          !scan_index[item.abs_path].success
        else
          false
        end
      end
    end

    cur_min_duration = prev_scan_meta.min { _1.duration }&.duration || 0

    result.sort_by do |item|
      dur = if el = scan_index[item.abs_path]
        el.duration
      else
        cur_min_duration -= 1
        cur_min_duration
      end

      -dur
    end

    [result, scan_index]
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
    else
      all_specs
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

  def spec_meta_file_name
    dir = Dir.pwd
    File.join(dir, SPEC_META_FILENAME)
  end

  def read_prev_scan_metadata
    path = spec_meta_file_name

    if File.exist?(path)
      result = begin
        from_json(File.read(path))
      rescue
        []
      end

      build_metadata(result)
    else
      build_metadata([])
    end
  end

  def update_scan_metadata(spec_meta)
    meta = read_prev_scan_metadata
    prev_spec = meta.find { _1.abs_path == spec_meta.abs_path }
    meta.delete(prev_spec) if prev_spec
    meta << spec_meta

    result = to_json(meta.map { to_hash(_1) })

    File.open(spec_meta_file_name, "w") do |f|
      f.flock(File::LOCK_EX)
      f.write(result)
      f.flock(File::LOCK_UN)
    end
  end

  class SpecMeta
    include ReeDto::DSL

    build_dto do
      field :package, String
      field :abs_path, String
      field :duration, Float
      field :last_scan_at, Time
      field :success, Bool
    end
  end

  def build_metadata(data)
    data.map do |d|
      SpecMeta.new(symbolize_keys(d))
    end.compact
  rescue
    []
  end
end
