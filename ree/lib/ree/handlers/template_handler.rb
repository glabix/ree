# frozen_string_literal  = true

require 'pathname'
require 'fileutils'

class Ree::TemplateHandler
  REJECTED_TEMPLATE_FILES   = %W(.DS_Store)
  NOT_HANDLED_TEMPLATES_EXT = %W(.erb)

  class << self
    def generate(template_name:, local_path:, project_path:, locals: {}, 
                stdout: STDOUT, stdin: STDIN)

      Ree::TemplateHandler.new(
        template_name: template_name.to_s,
        local_path: local_path,
        project_path: project_path,
        locals: locals,
        stdout: stdout,
        stdin: stdin
      ).generate
    end
  end

  def initialize(
    template_name:,
    local_path:,
    project_path:,
    locals:,
    stdout:,
    stdin:
  )

    @template_name = template_name
    @local_path = local_path
    @project_path = project_path
    @missing_variables = []
    @stdout = stdout
    @stdin = stdin
    default_locals = { package_subdir_name: 'package' }
    @locals = default_locals.merge(locals)
  end

  def generate
    project_path = @project_path
    template_detector = Ree::TemplateDetector.new(project_path)

    @template_directory    = template_detector.detect_template_folder(@template_name)
    @destination_directory = File.join(project_path, @local_path)

    template_files_list = Dir
      .glob(File.join(@template_directory, '**', '*'), File::FNM_DOTMATCH)
      .reject { |path| REJECTED_TEMPLATE_FILES.include? File.basename(path)  }

    template_files_list.each do |path|
      @missing_variables.concat(
        Ree::TemplateRenderer.get_undefined_variables(get_destination_path(path), @locals)
      )

      if handle_file_content?(path)
        @missing_variables.concat(
          Ree::TemplateRenderer.get_undefined_variables(File.read(path), @locals)
        )
      end
    end

    if @missing_variables.any?
      @missing_variables.uniq!

      @stdout.puts "Undefined variables were found:"
      @missing_variables.size.times { |t| @stdout.puts "  #{t+1}. #{@missing_variables[t]}" }

      @missing_variables.each do |var|
        @stdout.print "Type value for '#{var}': "
        @locals[var] = @stdin.gets.chomp
      end
    end

    template_files_list.map! do |path|
      rendered_abs_path = Ree::TemplateRenderer.handle(get_destination_path(path), @locals)
      rendered_rel_path = Pathname.new(rendered_abs_path).relative_path_from Pathname.new(project_path)

      if File.file?(rendered_abs_path) && File.exist?(rendered_abs_path)
        @stdout.puts "Warning! #{rendered_rel_path} already exists. Skipping file creation..."
        next
      end

      if File.directory?(path)
        FileUtils.mkdir_p(rendered_abs_path)
        next
      end

      rendered_file_content = handle_file_content?(path) ?
        Ree::TemplateRenderer.handle(File.read(path), @locals) :
        File.read(path)

      FileUtils.mkdir_p(File.dirname(rendered_abs_path))
      File.open(rendered_abs_path, 'w') { |f| f.write rendered_file_content }

      rendered_rel_path
    end

    template_files_list.compact
  end

  private

  def get_destination_path(file)
    return nil unless defined? @template_directory && defined? @destination_directory

    template_rel_path = Pathname.new(file).relative_path_from Pathname.new(@template_directory)
    File.join(@destination_directory, template_rel_path)
  end

  def handle_file_content?(path)
    File.file?(path) && !NOT_HANDLED_TEMPLATES_EXT.include?(File.extname(path))
  end
end
