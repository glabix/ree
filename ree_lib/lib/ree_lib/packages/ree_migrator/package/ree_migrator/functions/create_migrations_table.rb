# frozen_string_literal: true

class ReeMigrator::CreateMigrationsTable
  include Ree::FnDSL

  fn :create_migrations_table do
    singleton
    after_init :setup
  end

  def setup
    Sequel.extension(:migration)
  end

  contract(Sequel::Database => nil)
  def call(connection)
    if !connection.tables.include?(:migrations)
      connection.create_table :migrations do
        primary_key :id
        column :filename, "varchar(1024)", null: false
        column :created_at, DateTime, null: false
        column :type, "varchar(16)", null: false
      end
    end

    nil
  end
end