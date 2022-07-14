# frozen_string_literal = true

RSpec.describe :migrate_db do
  link :migrate_db, from: :ree_migrator

  before do
    Ree.enable_irb_mode
    require_relative('../../db')

    db = ReeMigratorTest::Db.new

    db.tables.each do |table|
      db.drop_table(table)
    end
  end

  after do
    Ree.disable_irb_mode
  end

  it {
    db = ReeMigratorTest::Db.new

    migrate_db(
      db,
      File.expand_path(
        File.join(__dir__, '../../sample_migrations/migrations.yml')
      )
    )

    data_first = db[:test_table].order(:id).first[:id]
    data_second = db[:test_table].order(:id).all.last[:id]

    expect(db[:test_table].columns.first).to eq(:id)
    expect(data_first).to eq(1)
    expect(data_second).to eq(10)
  }
end