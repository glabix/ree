# frozen_string_literal: true

class Ree::SpecRunner::Runner
  attr_accessor :no_specs_packages
  attr_accessor :prepared_command_params

  def initialize(path: nil, package: nil, spec_matcher: nil, show_missing_packages: true,
                stdout: $stdout, show_output: true )
    @package_name = package
    @no_specs_packages = []
    @spec_matcher = spec_matcher.to_s.split(':')[0]
    @spec_string_number = spec_matcher.to_s.split(':')[1].to_i
    @path = path
    @stdout = stdout
    @show_output = show_output
  end

  def run
    if @spec_matcher
      find_matched_files(@package_name)
    end

    prepare!
    check_input_params!
    display_missing_specs if @show_missing_packages
    print_message view.specs_header_message if @show_missing_packages

    execute_command
  end

  private

  def prepare!
    prepared_command_params = []
    no_specs_packages = []
    @command_params_list = []
    prepare_command_params
    prepare_no_specs_packages
    prepare_command
  end

  def is_package_included?(package_name)
    !prepared_command_params.select do |x|
      x.package_name == package_name
    end.empty?
  end

  def prepare_command_params
    @prepared_command_params ||= begin
      [
        Ree::SpecRunner::CommandGenerator.new(
          package_name: selected_package.name,
          package_path: File.join(@path, selected_package.dir),
          spec_matcher: @spec_matcher,
          spec_string_number: @spec_string_number,
          show_output:  @show_output
        ).generate
      ]
    end
  end

  def prepare_command
    @command_params_list += prepare_single_package_command(@package_name)
  end

  def prepare_no_specs_packages
    prepared_command_params
      .select { |cp| cp.spec_count == 0 }
      .map { |cp| no_specs_packages << cp.package_name }
  end

  def prepare_single_package_command(package_name)
    selected = prepared_command_params.detect do |cmd_params|
      cmd_params.package_name == package_name
    end

    prepare_commands_for_packages([selected])
  end

  def prepare_commands_for_packages(packages_command_params)
    running_packages = packages_command_params
      .select  { |cmd_params| cmd_params.spec_count > 0 }
      .sort_by { |cmd_params| cmd_params.package_name }

    running_packages
  end

  def execute_command
    @command_params_list.each do |command_param|
      eval(command_param.command);

      command_param.exitstatus = $?.exitstatus
    end

    failed = @command_params_list.select {|cmd_param| !cmd_param.success?}

    if failed.any?
      total_count = @command_params_list.count
      failed_count = failed.count

      print_message("#{failed_count} of #{total_count} packages failed:")
      print_message(failed.map(&:package_name))
      print_message("\n")
    end
  end

  def check_input_params!
    if @package_name
      unless is_package_included?(@package_name)
        exit_with_message(
          view.package_not_found_message(@package_name, prepared_command_params)
        )
      end

      if no_specs_packages.include?(@package_name)
        print_message(
          view.no_specs_for_package(@package_name)
        )
      end
    end
  end

  def display_missing_specs
    if !no_specs_packages.empty?
      print_message view.missing_specs_message(no_specs_packages)
    end
  end

  def find_matched_files(package_name)
    @spec_file_matches = Ree::SpecRunner::SpecFilenameMatcher.find_matches(
      package_path: File.join(@path, selected_package.dir),
      spec_matcher: @spec_matcher
    )

    case @spec_file_matches.size
    when 0
      raise Ree::Error.new("No spec were found for #{@spec_matcher}")
    when 1
      format_string_number = @spec_string_number == 0 ? "" : ":#{@spec_string_number}"
      @spec_matcher = @spec_file_matches.first
      puts "Following spec matches your input: #{@spec_matcher + format_string_number}"
    else
      format_spec_files = @spec_file_matches.map.with_index { |file, idx| "#{idx + 1}. #{file}" }.join("\n")

      puts "Following specs match your input:"
      puts format_spec_files
      print "Enter space-separated file numbers, ex: '1 2': "
      selected_files_numbers = $stdin.gets.chomp
        .split(' ')
        .map {|x| Integer(x) rescue nil }
        .compact
        .map { |n| n - 1 }
        .reject { |n| n >= @spec_file_matches.size }


      @spec_file_matches
        .select
        .with_index { |_file, idx| selected_files_numbers.include?(idx) }
        .each do |file|
          Ree::SpecRunner::Runner.new(
            path: @path,
            package: package_name,
            spec_matcher: file,
            show_output: @show_output,
            stdout: @stdout
          ).run
      end

      exit(0)
    end
  end

  def container
    @container = Ree.container
  end

  def selected_package
    @selected_package ||= packages.find { |p| p.name == @package_name }
  end

  def packages
    @packages ||= container.packages_facade.load_packages_schema.packages
  end

  def view
    @view ||= Ree::SpecRunner::View.new
  end

  def print_message(msg)
    @stdout.puts msg
    true
  end

  def exit_with_message(msg)
    print_message(msg)
    exit 1
  end
end
