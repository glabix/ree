# frozen_string_literal: true

require "sequel"

module ReeDao
  include Ree::PackageDSL

  package do
    depends_on :ree_array
    depends_on :ree_dto
    depends_on :ree_enum
    depends_on :ree_mapper
    depends_on :ree_string
    depends_on :ree_object
  end

  require_relative "./ree_dao/dsl"

  def self.init_cache(thread)
    ReeDao::Cache.init_cache(thread)
  end

  def self.drop_cache(thread)
    ReeDao::Cache.delete_cache(thread)
  end
end
