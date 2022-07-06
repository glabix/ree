module Ree
  module CLI
    class GenerateTemplate
      class << self
        def run(template_name:, project_path:, local_path:, locals:)
          generated_files_list = Ree::TemplateHandler.generate(
            template_name: template_name,
            project_path: project_path,
            local_path: local_path,
            locals: locals
          )
  
          generated_files_list.compact.each { |file| puts("Generated: #{file}") }

          puts("done")
        end
      end
    end
  end
end
