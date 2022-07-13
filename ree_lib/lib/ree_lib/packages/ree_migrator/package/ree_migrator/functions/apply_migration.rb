# frozen_string_literal: true

class ReeMigrator::ApplyMigration
  include Ree::FnDSL

  fn :apply_migration do
    link :now, from: :ree_datetime
  end

  contract(
    Sequel::Database,
    String,
    Or[:schema, :data] => nil
  ).throws(ArgumentError)
  def call(connection, migration_path, type)
    if !File.exist?(migration_path)
      raise ArgumentError.new("file not found: #{migration_path}")
    end

    load(migration_path)

    migration = Sequel::Migration.descendants.last
    connection.instance_eval(&migration.up)

    migration_name = File.basename(migration_path)

    connection[:schema_migrations].insert(
      filename: migration_name,
      type: type,
      created_at: now
    )

    nil
  end
end