#frozen_string_literal = true

RSpec.describe :apply_migration do
  link :apply_migration, from: :ree_migrator
  link :create_migrations_table, from: :ree_migrator

  before do
    Ree.enable_irb_mode
    require_relative('../../db')

    db = ReeMigratorTest::Db.new

    db.tables.each do |table|
      db.drop_table(table)
    end

    create_migrations_table(db)
  end

  after do
    Ree.disable_irb_mode
  end

  it {
    db = ReeMigratorTest::Db.new

    apply_migration(
      db,
      File.expand_path(
        File.join(__dir__, '../../sample_migrations/schema_migrations/create_test_table.rb')
      ),
      :schema
    )

    apply_migration(
      db,
      File.expand_path(
        File.join(__dir__, '../../sample_migrations/data_migrations/populate_test_table.rb')
      ),
      :data
    )

    migrations = db[:migrations].order(:id).all
    migration = migrations.first

    expect(migration[:id]).to be_a(Integer)
    expect(migration[:filename]).to eq("create_test_table.rb")
    expect(migration[:created_at]).to be_a(DateTime)
    expect(migration[:type]).to eq('schema')

    migration = migrations.last

    expect(migration[:id]).to be_a(Integer)
    expect(migration[:filename]).to eq("populate_test_table.rb")
    expect(migration[:created_at]).to be_a(DateTime)
    expect(migration[:type]).to eq('data')
  }
end