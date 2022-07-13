# frozen_string_literal: true

class TestMigrations::DataMigrations
  include Ree::FnDSL

  fn :data_migrations do
  end

  contract(None => nil)
  def call()
  end
end