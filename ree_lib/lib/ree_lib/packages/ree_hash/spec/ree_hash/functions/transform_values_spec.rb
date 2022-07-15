# frozen_string_literal = true

RSpec.describe :transform_values do
  link :transform_values, from: :ree_hash

  it {
    obj = {name: 'John', password: 'PASSWORD'}

    result = transform_values(obj) do |key, value|
      if key.to_s.include?('password')
        'FILTERED'
      else
        value
      end
    end

    expect(result).to eq({name: 'John', password: 'FILTERED'})
  }

  it {
    obj = {name: 'John', password: 'PASSWORD', list: [1, {password: 'PASSWORD'}]}

    result = transform_values(obj) do |key, value|
      if key.to_s.include?('password')
        'FILTERED'
      else
        value
      end
    end

    expect(result).to eq(
      {
        name: 'John',
        password: 'FILTERED',
        list: [1, {password: 'FILTERED'}]
      }
    )
  }
end