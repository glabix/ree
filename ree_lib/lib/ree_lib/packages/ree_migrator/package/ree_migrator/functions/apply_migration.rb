# frozen_string_literal: true

class ReeMigrator::ApplyMigration
  include Ree::FnDSL

  fn :apply_migration do
    link :now, from: :ree_datetime
    link :logger, from: :ree_logger
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

    logger.info("Applying migration: #{migration_path}")
    load(migration_path)

    migration = Sequel::Migration.descendants.last
    migration_name = File.basename(migration_path)

    connection.instance_eval(&migration.up)

    connection[:migrations].insert({
      filename: migration_name,
      type: type.to_s,
      created_at: now
    })

    nil
  end
end