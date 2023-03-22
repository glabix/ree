# frozen_string_literal: true

package_require('ree_array/functions/group_by')

RSpec.describe :group_by do
  link :group_by, from: :ree_array

  it {
    list = [ {id: 1, name: 'John'}, {id: 1, name: 'Smith'} ]
    result = group_by(list) { _1[:id] }

    expect(result).to eq(
      {
        1 => [ {id: 1, name: 'John'}, {id: 1, name: 'Smith'} ]
      }
    )
  }
end