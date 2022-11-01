require 'fileutils'

module Ree
  module CLI
    class DeleteObjectSchema
      class << self
        def run(object_path:, project_path:, silence: false)
          ENV['REE_SKIP_ENV_VARS_CHECK'] = 'true'

          path = Ree.locate_packages_schema(project_path)
          dir = Pathname.new(path).dirname.to_s

          Ree.init(dir)

          object_name = object_path.split('/')[-1].split('.').first.to_sym

          puts("Deleting old #{object_name}.schema.json") if !silence

          schema_path = Ree::PathHelper.object_schema_rpath(object_path)
          abs_schema_path = File.join(dir, schema_path)

          if File.exist?(abs_schema_path)
            FileUtils.rm(abs_schema_path)

            puts(" #{schema_path}: is deleted") if !silence
          end

          puts("done") if !silence
        end
      end
    end
  end
end
