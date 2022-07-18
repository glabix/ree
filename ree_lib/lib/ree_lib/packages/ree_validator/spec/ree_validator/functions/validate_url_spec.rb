# frozen_string_literal: true

RSpec.describe :validate_url do
  link :validate_url, from: :ree_validator

  context "valid" do
    it {
      expect(validate_url("https://google.com")).to eq(true)
      expect(validate_url("https://google.com?param")).to eq(true)
      expect(validate_url("http://google.com")).to eq(true)
      expect(validate_url("ftp://google.com")).to eq(true)
      expect(validate_url("192.168.0.1")).to eq(true)
      expect(validate_url("google.com")).to eq(true)

      expect(
        validate_url(
          "https://google.com",
          schemes: ['https', 'http'],
          ports: [80, 443],
          domains: ['google.com', 'test.com'],
        )
      ).to eq(true)
    }
  end

  context "invalid" do
    it {
      expect {
        validate_url(
          "ftp://google.com",
          schemes: ['http']
        )
      }.to raise_error(ReeValidator::ValidateUrl::UrlErr) do |e|
        expect(e.message).to eq('scheme should be one of ["http"]')
      end
    }

    it {
      expect {
        validate_url(
          "ftp://google.com",
          ports: [80]
        )
      }.to raise_error(ReeValidator::ValidateUrl::UrlErr) do |e|
        expect(e.message).to eq('port should be one of [80]')
      end
    }

    it {
      expect {
        validate_url(
          "https://google.com",
          Class.new(StandardError).new('message'),
          domains: ['test.com']
        )
      }.to raise_error(StandardError) do |e|
        expect(e.message).to eq('message')
      end
    }
  end
end