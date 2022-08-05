# frozen_string_literal  = true

module Ree::PackageSchema
  SCHEMA_VERSION_NUMBER = '1.0'

  SCHEMA_TYPE = 'schema_type'
  REE_VERSION = 'ree_version'
  SCHEMA_VERSION = 'schema_version'
  NAME = 'name'
  PACKAGE = 'package'
  ENTRY_PATH = 'entry_path'
  OBJECTS = 'objects'
  ENV_VARS = 'env_vars'
  DEPENDS_ON = 'depends_on'
  TAGS = 'tags'

  module Objects
    NAME = 'name'
    SCHEMA = 'schema'
  end

  module DependsOn
    NAME = 'name'
  end

  module EnvVars
    NAME = 'name'
    DOC = 'doc'
  end
end