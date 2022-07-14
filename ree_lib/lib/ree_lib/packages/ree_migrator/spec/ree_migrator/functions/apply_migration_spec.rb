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
        File.join(__dir__, '../../schema_migrations/create_users.rb')
      ),
      :schema
    )

    migration = db[:migrations].first

    expect(migration[:filename]).to eq("create_users.rb")
    expect(migration[:created_at]).to be_a(DateTime)
    expect(migration[:type]).to eq('schema')
  }

  it {
    db = ReeMigratorTest::Db.new

    apply_migration(
      db,
      File.expand_path(
        File.join(__dir__, '../../data_migrations/create_data.rb')
      ),
      :data
    )

    data = db[:test_table].first[:id]

    expect(data).to eq(12345)
  }
end