# frozen_string_literal: true

RSpec.describe :except do
  link :except, from: :ree_hash

  it {
    result = except(
      {
        name: {
          first_name: "John",
          last_name:  "Doe"
        },
        address: "Home",
        age: 35,
        pets: {
          dog: "Dog"
        }
      },
      :age, :pets
    )
    
    expect(result).to eq({:name => {:first_name => "John", :last_name => "Doe"}, :address => "Home"})
  }
end