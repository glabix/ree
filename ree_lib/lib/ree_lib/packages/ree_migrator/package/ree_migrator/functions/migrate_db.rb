# frozen_string_literal: true

class ReeMigrator::MigrateDb
  include Ree::FnDSL

  fn :migrate_db do
    link :create_migrations_table
    link :apply_migrations
    link :logger, from: :ree_logger
  end

  SCHEMA_MIGRATIONS = "schema_migrations"
  DATA_MIGRATIONS = "data_migrations"

  contract(Sequel::Database, String => nil)
  def call(db_connection, migrations_yml_path)
    migrations_yml_dir = File.dirname(migrations_yml_path)
    schema_migrations_path = File.join(migrations_yml_dir, SCHEMA_MIGRATIONS)
    data_migrations_path = File.join(migrations_yml_dir, DATA_MIGRATIONS)

    logger.info("Applying schema and data migrations for #{db_connection.opts[:database]} database")

    create_migrations_table(db_connection)

    apply_migrations(
      db_connection,
      migrations_yml_path,
      schema_migrations_path,
      data_migrations_path
    )

    nil
  end
end