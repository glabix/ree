# frozen_string_literal: true

RSpec.describe :except do
  link :except, from: :ree_hash

  let(:hash) {
    {
      name: {
        first_name: "John",
        last_name:  "Doe"
      },
      address: "Home",
      projects: [1, 2, { id: 1 }],
      settings: {id: 1, number: 25},
      age: 35,
      pets: {
        dog: {
          name: "Dog"
        }
      }
    }
  }

  context "global except only" do 
    it {
      result = except(hash, global_except: [:id])

      expected = {
        name: {
          first_name: "John",
          last_name:  "Doe"
        },
        address: "Home",
        projects: [1, 2, {}],
        settings: {number: 25},
        age: 35,
        pets: {
          dog: {
            name: "Dog"
          }
        }
      }

      expect(result).to eq(expected)
    }
  end

  context "with options" do
    it {
      result = except(hash, [:address, :age], global_except: [:name])
      
      expected = {
        projects: [1, 2, { id: 1 }],
        settings: {id: 1, number: 25},
        pets: {
          dog: {}
        }
      }

      expect(result).to eq(expected)
    }

    it {
      result = except(hash, global_except: [:name])
      
      expected = {
        address: "Home",
        projects: [1, 2, { id: 1 }],
        settings: {id: 1, number: 25},
        age: 35,
        pets: {
          dog: {}
        }
      }

      expect(result).to eq(expected)
    }

    it {
      result = except(hash, [:age], global_except: [:name, :address])
      
      expected = {
        projects: [1, 2, { id: 1 }],
        settings: {id: 1, number: 25},
        pets: {
          dog: {}
        }
      }

      expect(result).to eq(expected)
    }

    it {
      result = except(hash, [:address, pets: [dog: [:name]]])

      expected = {
        name: {
          first_name: "John",
          last_name:  "Doe"
        },
        projects: [1, 2, { id: 1 }],
        settings: {id: 1, number: 25},
        age: 35,
        pets: {
          dog: {}
        }
      }

      expect(result).to eq(expected)
    }
    
    it {
      result = except(
        hash, [:address, {settings: [:id, :number]}],
        global_except: [:name]
      )

      expected = {
        projects: [1, 2, { id: 1 }],
        settings: {},
        age: 35,
        pets: {
          dog: {}
        }
      }

      expect(result).to eq(expected)
    }

    it {
      result = except(hash, [:address, {name: [:last_name]}])
      
      expected = {
        name: {
          first_name: "John"
        },
        projects: [1, 2, { id: 1 }],
        settings: {id: 1, number: 25},
        age: 35,
        pets: {
          dog: {
            name: "Dog"
          }
        }
      }
      
      expect(result).to eq(expected)
    }

    it {
      result = except(
        hash, [:address, {name: [:last_name], settings: [:number]}]
      )
      
      expected = {
        name: {
          first_name: "John"
        },
        projects: [1, 2, { id: 1 }],
        settings: {id: 1},
        age: 35,
        pets: {
          dog: {
            name: "Dog"
          }
        }
      }
      
      expect(result).to eq(expected)
    }
  end

  context "general" do
    it {
      result = except(hash, [:name])

      expected = {
        address: "Home",
        projects: [1, 2, { id: 1 }],
        settings: {id: 1, number: 25},
        age: 35,
        pets: {
          dog: {
            name: "Dog"
          }
        }
      }

      expect(result).to eq(expected)
    }
  end

  context "invalid contract" do
    it {
      expect {
        except(hash, ['key'])
      }.to raise_error do |e|
        expect(e).to be_a(Ree::Contracts::ContractError)
        expect(e.message).to eq(
          "Contract violation for ReeHash::Except#call\n\t - keys: expected [:key0, .., :keyM => [:keyN, .., :keyZ]], got => [\"key\"]"
        )
      end
    }
  end
end