# frozen_string_literal = true

RSpec.describe :schema_migrations do
  link :schema_migrations, from: :test_migrations

  it {
    schema_migrations()
  }
end