# frozen_string_literal: true

class TestMigrations::SchemaMigrations
  include Ree::FnDSL

  fn :schema_migrations do
  end

  contract(None => nil)
  def call()
  end
end