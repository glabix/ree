module Ree
  module CLI
    class GeneratePackage
      class << self
        def run(package_name:, project_path:, path:, locals: {}, stdout: $stdout)
          generated_files_list = Ree::Gen::Package.generate(
            project_path: project_path,
            local_path:   path,
            package_name: package_name,
            locals:       locals
          )
  
          generated_files_list.compact.each { |file| stdout.puts "Generated: #{file}" }
        end
      end
    end
  end
end
