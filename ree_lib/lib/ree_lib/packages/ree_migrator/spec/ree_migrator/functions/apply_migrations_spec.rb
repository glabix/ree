# frozen_string_literal = true

package_require('ree_migrator/functions/apply_migrations')

RSpec.describe :apply_migrations do
  link :apply_migrations, from: :ree_migrator
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

    apply_migrations(
      db,
      File.expand_path(
        File.join(__dir__, '../../sample_migrations/migrations.yml')
      ),
      File.expand_path(
        File.join(__dir__, '../../sample_migrations/schema_migrations')
      ),
      File.expand_path(
        File.join(__dir__, '../../sample_migrations/data_migrations')
      )
    )

    data_first = db[:test_table].order(:id).first[:id]
    data_second = db[:test_table].order(:id).all[1][:id]

    expect(db[:test_table].columns.first).to eq(:id)
    expect(data_first).to eq(1)
    expect(data_second).to eq(2)
  }
end