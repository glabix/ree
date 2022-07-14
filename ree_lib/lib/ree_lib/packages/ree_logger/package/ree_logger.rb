require 'fileutils'
require 'logger'
require 'rainbow'
require 'binding_of_caller'

module ReeLogger
  include Ree::PackageDSL

  package do
    depends_on :ree_object
    depends_on :ree_datetime
    depends_on :ree_validator
    depends_on :ree_hash

    env_var 'LOG_FILE_PATH'
    env_var 'LOG_LEVEL_FILE'
    env_var 'LOG_LEVEL_STDOUT'
    env_var 'LOG_RATE_LIMIT_INTERVAL'
    env_var 'LOG_RATE_LIMIT_COUNT'
  end
end
