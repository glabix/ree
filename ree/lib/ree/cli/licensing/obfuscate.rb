# frozen_string_literal: true

module Ree
  module CLI
    module Licensing
      class Obfuscate
        class << self
          def run(source_path:, target_path:, client_id:, expires_at:, exclude_files: "", clients_dir: Dir.pwd, stdout: $stdout)
            exclude_list = exclude_files.to_s.split(',').map(&:strip).reject(&:empty?)

            Ree::Licensing::Obfuscator.run(
              source_path: source_path,
              target_path: target_path,
              client_id: client_id,
              expires_at: expires_at,
              clients_dir: clients_dir,
              exclude_files: exclude_list,
              stdout: stdout
            )
          rescue Ree::Error => e
            stdout.puts "Error: #{e.message}"
          end
        end
      end
    end
  end
end
