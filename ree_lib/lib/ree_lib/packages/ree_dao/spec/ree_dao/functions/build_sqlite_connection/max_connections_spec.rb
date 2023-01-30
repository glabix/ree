package_require('ree_dao')

RSpec.describe :build_sqlite_connection do
  link :build_sqlite_connection, from: :ree_dao

  it {
    db = build_sqlite_connection({database: 'sqlite_db', max_connections: 2})
    expect(db.pool.max_size).to eq 2
  }
end