# frozen_string_literal  = true

module Ree::PackagesSchema
  SCHEMA_TYPE = 'schema_type'
  REE_VERSION = 'ree_version'
  PACKAGES = 'packages'
  GEM_PACKAGES = 'gem_packages'
  
  module Packages
    NAME = 'name'
    SCHEMA = 'schema'
    GEM = 'gem'
  end

  module GemPackages
    NAME = 'name'
    SCHEMA = 'schema'
  end
end