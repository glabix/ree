class Ree::TemplateDetector
  DEFAULT_TEMPLATES_DIRECTORY = File.expand_path(__dir__)

  def initialize(project_path)
    @all_templates_directory ||= File.join(project_path, ".ree", "templates")
  end

  def detect_template_folder(template_name)
    template_path = [@all_templates_directory, DEFAULT_TEMPLATES_DIRECTORY]
      .map    {|dir| File.join(dir, template_name.to_s)}
      .detect  {|dir| Dir.exist?(dir)}

    raise Ree::Error.new('Template does not exist') if template_path.nil?

    template_path
  end

  def gem_template_folder(template_name)
    File.join(DEFAULT_TEMPLATES_DIRECTORY, template_name.to_s)
  end

  def project_template_folder(template_name)
    File.join(@all_templates_directory, template_name.to_s)
  end

  def template_file_path(template_name, relative_path)
    file_path = [detect_template_folder(template_name), DEFAULT_TEMPLATES_DIRECTORY]
      .map {|folder| File.join(folder, relative_path)}
      .detect {|file| File.exist?(file)}

      raise Ree::Error.new('Template does not exist') if file_path.nil?

    file_path
  end
end