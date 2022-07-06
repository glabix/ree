# frozen_string_literal: true

RSpec.describe :validate_url do
  link :validate_url, from: :ree_validator

  context "valid" do
    it {
      expect(validate_url("https://google.com", :code)).to eq(true)
      expect(validate_url("https://google.com?param", :code)).to eq(true)
      expect(validate_url("http://google.com", :code)).to eq(true)
      expect(validate_url("ftp://google.com", :code)).to eq(true)
      expect(validate_url("192.168.0.1", :code)).to eq(true)
      expect(validate_url("google.com", :code)).to eq(true)

      expect(
        validate_url(
          "https://google.com",
          :code,
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
          :code,
          schemes: ['http']
        )
      }.to raise_error(ReeValidator::ValidateUrl::InvalidSchemeErr) do |e|
        expect(e.extra_code).to eq(:code)
        expect(e.message).to eq('scheme should be one of ["http"]')
      end
    }

    it {
      expect {
        validate_url(
          "ftp://google.com",
          :code,
          ports: [80]
        )
      }.to raise_error(ReeValidator::ValidateUrl::InvalidPortErr) do |e|
        expect(e.extra_code).to eq(:code)
        expect(e.message).to eq('port should be one of [80]')
      end
    }

    it {
      expect {
        validate_url(
          "https://google.com",
          :code,
          domains: ['test.com']
        )
      }.to raise_error(ReeValidator::ValidateUrl::InvalidDomainErr) do |e|
        expect(e.extra_code).to eq(:code)
        expect(e.message).to eq('domain should be one of ["test.com"]')
      end
    }
  end
end