# frozen_string_literal  = true

module Ree::ObjectSchema
  SCHEMA_TYPE = 'schema_type'
  REE_VERSION = 'ree_version'
  SCHEMA_VERSION = 'schema_version'
  SCHEMA_VERSION_NUMBER = '0.0.1' # !!! Bump version when structure is changed !!!
  NAME = 'name'
  OBJECT = 'object'
  LINKS = 'links'
  CONTEXT = 'context'
  PATH = 'path'
  METHODS = 'methods'
  CLASS = 'class'
  PACKAGE_NAME = 'package_name'
  MOUNT_AS = 'mount_as'
  FACTORY = 'factory'
  ERRORS = 'errors'

  module Links
    NAME = 'name'
    PACKAGE_NAME = 'package_name'
    TARGET = 'target'
    AS = 'as'
    IMPORTS = 'imports'

    module Imports
      CONST = 'const'
      AS = 'as'
    end
  end

  module Methods
    ARGS = 'args'
    METHOD = 'method'
    RETURN = 'return'
    THROWS = 'throws'
    DOC = 'doc'

    module Args
      ARG = 'arg'
      TYPE = 'type'
    end
  end

  module Errors
    CODE = 'code'
  end
end