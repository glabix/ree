# frozen_string_literal: true

module Ree::PackagesSchema
  SCHEMA_VERSION_NUMBER = '1.0'

  SCHEMA_TYPE = 'schema_type'
  REE_VERSION = 'ree_version'
  SCHEMA_VERSION = 'schema_version'
  PACKAGES = 'packages'
  GEM_PACKAGES = 'gem_packages'

  module Packages
    NAME = 'name'
    ENTRY_PATH = 'entry_path'
    GEM = 'gem'
  end

  module GemPackages
    NAME = 'name'
    ENTRY_PATH = 'entry_path'
  end
end