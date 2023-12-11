# frozen_string_literal: true

require "sequel"
require "fiber_scheduler"

module ReeDao
  include Ree::PackageDSL

  package do
    depends_on :ree_array
    depends_on :ree_dto
    depends_on :ree_enum
    depends_on :ree_mapper
    depends_on :ree_string
    depends_on :ree_object
    depends_on :ree_hash
  end

  require_relative "./ree_dao/dsl"
  require_relative "./ree_dao/thread_parents"
  require_relative "./ree_dao/aggregate_dsl"
  require_relative "./ree_dao/association_methods"
  require_relative "./ree_dao/associations"
  require_relative "./ree_dao/association"

  def self.load_sync_associations_enabled?
    ENV.has_key?("REE_DAO_SYNC_ASSOCIATIONS") && ENV["REE_DAO_SYNC_ASSOCIATIONS"] == "true"
  end
end

# ReeEnum::Value#sql_literal is used to properly serialize enum values
# for database queries
class ReeEnum::Value
  def sql_literal(*)
    mapped_value.to_s
  end
end