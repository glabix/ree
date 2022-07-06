# frozen_string_literal: true

RSpec.describe :years_diff do
  link :years_diff, from: :ree_datetime

  let(:err_result) {years_diff(Time.new(2030, 1, 1,2, 15),
    Time.new(2012, 1, 1, 2, 30))}
  context "Raise Argument Error" do
    it {
    expect{ err_result }.to raise_error(ArgumentError)
    }

  end

  context "Year with 366 days" do
    it {

      result = years_diff(Time.new(2012, 1, 1,2, 15),
        Time.new(2012, 12, 1, 2, 30))
      expect(result).to eq(1)

      result = years_diff(Time.new(2012, 1, 1,2, 15),
        Time.new(2012, 12, 1, 2, 30), round_mode: :up)
      expect(result).to eq(1)

      result = years_diff(Time.new(2012, 1, 1,2, 15),
        Time.new(2012, 3, 1, 2, 30), round_mode: :down)
      expect(result).to eq(0)
    }
  end

  context "Half year" do
    it {
      result = years_diff(Time.new(2013, 1, 1,2, 30),
        Time.new(2013, 7, 2, 14, 30), round_mode: :half_down)
      expect(result).to eq(0)

      result = years_diff(Time.new(2013, 1, 1,2, 30),
        Time.new(2013, 7, 2, 14, 30), round_mode: :half_up)
      expect(result).to eq(1)
    }
  end

  context "Down and Up round_mode" do
    it {
      result = years_diff(DateTime.new(2013, 1, 1, 14, 30),
        DateTime.new(2013, 12, 30, 14, 30), :round_mode => :down)
      expect(result).to eq(0)

      result = years_diff(Time.new(2013, 1, 1,2, 30),
        Time.new(2013, 2, 2, 14, 30), round_mode: :up)
      expect(result).to eq(1)
    }
  end
end

