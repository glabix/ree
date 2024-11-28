# frozen_string_literal: true

class Ree::SpecRunner::SpecFilenameMatcher
  class << self
    def find_matches(package_path:, spec_matcher:, filenames:)
      Ree::SpecRunner::SpecFilenameMatcher.new(package_path, spec_matcher, filenames).find_matches
    end
  end

  def initialize(package_path, spec_matcher, filenames)
    @package_path = File.expand_path(package_path)
    @spec_matcher = spec_matcher
    @filenames = filenames
  end

  def find_matches
    if @filenames.size > 0
      glob_pattern = filenames.map { |filename| File.join(@package_path, "**/#{filename}") }

      Dir.glob(glob_pattern)
        .select { |fn| File.file?(fn) }
        .map {|file| Pathname.new(file).relative_path_from(Pathname.new(@package_path)).to_s }
    else
      expected_filename = File.join(@package_path, @spec_matcher)

      if File.exist?(expected_filename)
        return Pathname.new(expected_filename).relative_path_from(Pathname.new(@package_path)).to_s.split
      end

      Dir.glob(File.join(@package_path, '**/*_spec.rb'))
        .select { |fn| File.file?(fn) }
        .map {|file| Pathname.new(file).relative_path_from(Pathname.new(@package_path)).to_s }
        .grep(/#{@spec_matcher.split('').join('.*')}/)
    end
  end
end
