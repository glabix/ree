# frozen_string_literal  = true

class Ree::SpecRunner::CommandGenerator
  attr_accessor :package_name, :package_path, :spec_matcher, :spec_string_number

  def initialize(package_name:, package_path:, spec_matcher:, spec_string_number:, show_output: true)
    @package_name = package_name
    @package_path = File.expand_path(package_path)
    @spec_matcher = spec_matcher
    @spec_string_number = spec_string_number
    @output = show_output ? '$stdout' : 'File::NULL'
  end

  def spec_count
    Dir[File.join(package_path, 'spec/**/*_spec.rb')].size
  end

  def command
    package_spec_path = File.join(package_path, 'spec')
    package_spec_helper = File.join(package_path, 'spec', 'spec_helper.rb')
    matcher = ""

    if spec_matcher
      matched_file = File.expand_path(spec_matcher, package_path)
      matcher = File.exist?(matched_file) ? matcher_with_number(matched_file, spec_string_number) : matcher_with_number(spec_matcher, spec_string_number)
    end

    "print_message(
        '**** Package: #{package_name}  *****') \\
          && system('cd #{Ree.root_dir} \\
          && bundle exec rspec --color --tty #{matcher} --default-path=#{package_spec_path} --require=#{package_spec_helper}', \\
          out: #{@output.to_s}, err: :out)"
  end

  def generate
    Ree::SpecRunner::CommandParams.new.tap do |cp|
      cp.package_name = package_name
      cp.package_path = package_path
      cp.command      = command
      cp.spec_count   = spec_count
    end
  end

  private

  def matcher_with_number(matcher_string, string_number)
    string_number == 0 ? matcher_string : [matcher_string, string_number].join(':')
  end
end
