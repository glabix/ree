Sequel.migration do
  change do
    from(:test_table).insert(id: 555555)
  end
end