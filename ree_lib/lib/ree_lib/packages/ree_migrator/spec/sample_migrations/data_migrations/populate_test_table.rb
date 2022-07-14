Sequel.migration do
  change do
    db = ReeMigratorTest::Db.new

    db[:test_table].where({}).delete

    (1..10).each do |i|
      db[:test_table].insert({id: i})
    end
  end
end