# frozen_string_literal: true

RSpec.describe :slice do
  link :slice, from: :ree_hash

  let(:hash) {
    {
      id: 1,
      uuid: 'qwerty-qwerty-qwerty',
      list: [1, 2, 3],
      user: {
        name: 'John',
        last_name: 'Doe'
      },
      info: {
        balance: {
          money: 1337,
          currency: 0
        },
        age: 1337
      },
      skills: {
        math: 100,
        coding: 1337
      },
      users: [
        {
          id: 1,
          name: 'John'
        },
        {
          id: 2,
          name: 'Adam'
        }
      ]
    }
  }

  it {
    result = slice(hash, [users: [:id]])

    expected = {
      users: [{id: 1}, {id: 2}]
    }

    expect(result).to eq(expected)
  }

  it {
    result = slice(hash, [users: []])

    expected = {
      users: [
        {
          id: 1,
          name: 'John'
        },
        {
          id: 2,
          name: 'Adam'
        }
      ]
    }

    expect(result).to eq(expected)
  }

  it {
    h = hash.dup
    h[:users].push(Object.new)

    expect {
      slice(h, [users: [:id]])
    }.to raise_error(ReeHash::Slice::InvalidFilterKey) 
  }

  it {
    expect {
      slice(hash, [id: [:name]])
    }.to raise_error(ReeHash::Slice::InvalidFilterKey) 
  }

  it {
    result = slice(hash, [:id, :uuid])

    expected = {
      id: 1,
      uuid: 'qwerty-qwerty-qwerty'
    }

    expect(result).to eq(expected)
  }

  it {
    result = slice(
      hash, [
        :user, info: [:age, balance: [:money]], skills: [:math]
      ]
    )

    expected = {
      user: {
        name: 'John',
        last_name: 'Doe'
      },
      info: {
        balance: {
          money: 1337
        },
        age: 1337
      },
      skills: {
        math: 100
      }
    }

    expect(result).to eq(expected)
  }

  it {
    expect {
      slice(
        hash, [user: [:full_name]], raise: true
      )
    }.to raise_error(ReeHash::Slice::MissingKeyErr, "missing key `:full_name`")
  }

  it {
    expect {
      slice(hash, [:test], raise: true)
    }.to raise_error(ReeHash::Slice::MissingKeyErr, "missing key `:test`")
  }
end