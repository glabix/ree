# frozen_string_literal  = true

module Ree
  module CLI
    autoload :Init, 'ree/cli/init'
    autoload :GeneratePackagesSchema, 'ree/cli/generate_packages_schema'
    autoload :GeneratePackageSchema, 'ree/cli/generate_package_schema'
    autoload :GenerateObjectSchema, 'ree/cli/generate_object_schema'
    autoload :DeleteObjectSchema, 'ree/cli/delete_object_schema'
    autoload :GeneratePackage, 'ree/cli/generate_package'
    autoload :GenerateTemplate, 'ree/cli/generate_template'
    autoload :IndexProject, 'ree/cli/indexing/index_project'
    autoload :IndexFile, 'ree/cli/indexing/index_file'
    autoload :IndexPackage, 'ree/cli/indexing/index_package'
    autoload :SpecRunner, 'ree/cli/spec_runner'
  end
end
