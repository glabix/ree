# frozen_string_literal: true

package_require('RELATIVE_FILE_PATH')

RSpec.describe MODULE_NAME::CLASS_NAME do
  let(:OBJECT_NAME) { described_class.new }

  it {
    OBJECT_NAME.()
  }
end