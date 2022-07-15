Sequel.migration do
  change do
    create_table :test_table do
      primary_key :id, type: :Bignum
    end
  end
end