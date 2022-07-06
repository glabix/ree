# frozen_string_literal: true

RSpec.describe :number_to_ordinalized do
  link :number_to_ordinalized, from: :ree_number

  context 'general' do
    it {
      expect(number_to_ordinalized(12)).to eq("12th")
      expect(number_to_ordinalized(-1)).to eq("-1st")
      expect(number_to_ordinalized(-1)).to eq("-1st")
      expect(number_to_ordinalized(-11)).to eq("-11th")
      expect(number_to_ordinalized(2)).to eq("2nd")
      expect(number_to_ordinalized(3)).to eq("3rd")
      expect(number_to_ordinalized(4)).to eq("4th")
      expect(number_to_ordinalized(2012)).to eq("2012th")
      expect(number_to_ordinalized(-2012)).to eq("-2012th")
      expect(number_to_ordinalized(-2022)).to eq("-2022nd")
      expect(number_to_ordinalized(-102022)).to eq("-102022nd")
      expect(number_to_ordinalized(-102012)).to eq("-102012th")
      expect(number_to_ordinalized(102034)).to eq("102034th")
      expect(number_to_ordinalized(102033)).to eq("102033rd")
      expect(number_to_ordinalized(2000)).to eq("2000th")
    }
  end

end