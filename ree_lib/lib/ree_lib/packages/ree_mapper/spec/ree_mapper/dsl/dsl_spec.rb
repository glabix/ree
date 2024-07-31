package_require('ree_mapper/dsl')

RSpec.describe ReeMapper::DSL do
  before {
    Ree.enable_irb_mode
  }

  after {
    Ree.disable_irb_mode
  }

  it {
    class ReeMapper::UserCaster
      include ReeMapper::DSL

      mapper :user_caster

      build_mapper(register_as: :user).use(:cast) do
        integer :id
        string  :name
        user    :created_by, null: true
      end
    end

    class ReeMapper::ProductCaster
      include ReeMapper::DSL

      mapper :product_caster do
        link :user_caster
      end

      build_mapper.use(:cast) do
        integer :id
        string  :title
        user    :creator
      end
    end

    result = ReeMapper::ProductCaster.new.cast(
      OpenStruct.new(
        {
          id: 1,
          title: 'Product',
          creator: {
            id: 1,
            name: 'John',
            created_by: {
              id: 2,
              name: 'Jane',
              created_by: nil
            }
          }
        }
      )
    )

    expect(result).to eq({
      id: 1,
      title: 'Product',
      creator: {
        id: 1,
        name: 'John',
        created_by: {
          id: 2,
          name: 'Jane',
          created_by: nil
        }
      }
    })
  }
end
