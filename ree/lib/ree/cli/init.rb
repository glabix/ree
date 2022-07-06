module Ree
  module CLI
    class Init
      class << self
        def run(project_path:, test:, console:, stdout: $stdout)
          generated_files_list = Ree::Gen::Init.generate(
            project_path: project_path,
            test: test,
            console: console,
            stdout: stdout
          )
  
          generated_files_list.compact.each { |file| stdout.puts "Generated: #{file}" }
        rescue Errno::ENOENT => e
          stdout.puts "Error occurred. Possible reasons:\n #{project_path} not found. Please run on empty directory \n#{e.inspect}"
        rescue Ree::Error => e
          stdout.puts e.message
        end
      end
    end
  end
end
