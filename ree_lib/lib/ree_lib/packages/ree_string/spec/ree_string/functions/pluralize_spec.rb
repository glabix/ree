# frozen_string_literal: true

RSpec.describe :pluralize do
  link :pluralize, from: :ree_string

  it {
    expect(pluralize(1, 'person', 'people')).to eq('1 person')
    expect(pluralize(2, 'person', 'people')).to eq('2 people')
  }

  context "when prefixed is false" do
    it {
      expect(pluralize(1, 'person', 'people', false)).to eq('person')
      expect(pluralize(2, 'person', 'people', false)).to eq('people')
    }
  end
end
