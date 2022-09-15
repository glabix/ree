# frozen_string_literal = true
package_require("ree_dao/types/pg_array")

RSpec.describe ReeDao::PgArray do
  it {
    type = ReeDao::PgArray.new

    result = type.db_dump([1], role: nil)
    expect(result).to be_a(Sequel::Postgres::PGArray)
  }

  it {
    type = ReeDao::PgArray.new

    result = type.db_dump([1], role: nil)
    result = type.db_load(result, role: nil)
    expect(result).to eq([1])
  }
end