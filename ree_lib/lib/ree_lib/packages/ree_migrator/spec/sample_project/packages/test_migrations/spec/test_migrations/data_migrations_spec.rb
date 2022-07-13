# frozen_string_literal = true

RSpec.describe :data_migrations do
  link :data_migrations, from: :test_migrations

  it {
    data_migrations()
  }
end