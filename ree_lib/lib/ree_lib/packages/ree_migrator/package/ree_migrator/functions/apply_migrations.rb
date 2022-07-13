# frozen_string_literal: true

class ReeMigrator::ApplyMigrations
  include Ree::FnDSL

  fn :apply_migrations do
    link :is_blank, from: :ree_object
    link :apply_migration
    # link :logger, from: :ree_logger
  end

  RUBY_EXT = '*.rb'
  DATA = 'data'
  SCHEMA = 'schema'

  InvalidMigrationYmlErr = Class.new(StandardError)
  MigrationNotFoundErr = Class.new(StandardError)

  contract(
    Sequel::Database,
    String,
    String,
    String => ArrayOf[String]
  ).throws(InvalidMigrationYmlErr, MigrationNotFoundErr)
  def call(connection, migrations_yml_path, schema_migrations_path, data_migrations_path)
    # logger.info("Parsing migrations.yml from #{migrations_yml_path}")

    migrations = YAML.load(File.read(migrations_yml_path))
    return [] if is_blank(migrations)

    applied_schema_migrations = indexed_migrations(SCHEMA)
    applied_data_migrations = indexed_migrations(DATA)
    schema_migrations = Dir.glob(File.join(schema_migrations_path, RUBY_EXT))
    data_migrations  = Dir.glob(File.join(data_migrations_path, RUBY_EXT))

    migrations = migrations.map do |migration|
      if !migration.is_a?(Hash) || !(migration.keys - [SCHEMA, DATA]).empty?
        raise InvalidMigrationYmlErr.new(
          "Invalid migrations.yml. Example of valid format:\n- schema: SCHEMA_MIGRATION_FILE_NAME.rb\n- data: DATA_MIGRATION_FILE_NAME.rb"
        )
      end

      migration_path = if migration.has_key?(SCHEMA)
        run_migration(
          connection,
          :schema,
          migration[SCHEMA],
          applied_schema_migrations,
          schema_migrations,
          schema_migrations_path
        )
      elsif migration.has_key?(DATA)
        run_migration(
          connection,
          :data,
          migration[DATA],
          applied_data_migrations,
          data_migrations,
          data_migrations_path
        )
      end

      migration_path
    end.compact

    migrations
  end

  private

  def indexed_migrations(type)
    connection[:migrations]
      .select_map(:filename)
      .where(type: type)
      .index_by { _1[:filename] }
  end

  def run_migration(connection, migration_type, migration_name, applied_migrations, migrations, migrations_path)
    return nil if applied_migrations.include?(migration_name)

    migration_path = migrations.detect { _1.include?(migration_name) }

    raise MigrationNotFoundErr.new(
      "schema migration file for #{migration_name} not found in #{migrations_path}"
    ) if !migration_path

    apply_migration(connection, migration_path, migration_type)

    migration_path
  end
end