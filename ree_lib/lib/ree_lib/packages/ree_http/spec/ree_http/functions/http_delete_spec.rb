# frozen_string_literal: true
require 'webmock/rspec'

RSpec.describe :http_delete do
  link :http_delete, from: :ree_http

  let(:host) { 'http://www.example.com' }
  let(:host_with_path) { host + '/someamzingpath/anypage' }
  let(:host_with_ssl) { 'https://www.example.com' }

  before :all do
    WebMock.enable!
  end

  after :all do
    WebMock.disable!
  end

  context "no ssl" do
    before :all do
      WebMock.reset!

      WebMock
        .stub_request(:delete, /example/)
        .with(
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent'=>'Ruby'
          }
        )
        .to_return(status: 200, headers: {})
    end

    it "without options" do
      http_delete(host)
      expect(WebMock).to have_requested(:delete, host)

      http_delete(
        host,
        basic_auth: {username: 'user', password: 'pass'}
      )
      expect(WebMock).to have_requested(:delete, host).with(basic_auth: ['user', 'pass'])

      http_delete(
        host,
        bearer_token: 'token'
      )
      expect(WebMock).to have_requested(:delete, host).with(headers: { 'Authorization': "Bearer token" })

      http_delete(
        host,
        query_params: { q: 100, "s"=> 'simple'}
      )
      expect(WebMock).to have_requested(:delete, host).with(query: { "q"=> 100, "s"=> "simple"})

      http_delete(
        host_with_path + '?a=200',
        query_params: { q: 100, "s"=> 'simple'}
      )
      expect(WebMock).to have_requested(:delete, host_with_path).with(query: {"a"=>200, "q"=> 100, "s"=> "simple"})
    end
  end

  context "force ssl" do

    before :all do
      WebMock
        .stub_request(:delete, 'https://www.example.com')
        .with(
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent'=>'Ruby',
            'Token'=>'321'
          }
        )
        .to_return(status: 200, headers: {})
    end

    it do
      http_delete(
        host,
        force_ssl: true, headers: { token: '321'}
      )
      expect(WebMock).to have_requested(:delete, host_with_ssl).with(headers: { 'Token'=>'321' })
    end
  end

  context "redirect" do
    before :all do
      WebMock.reset!
      WebMock
        .stub_request(:delete, 'https://www.example.com/redirect_307')
        .with(
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent'=>'Ruby',
          }
        )
        .to_return(status: 307, headers: {'Location': 'https://www.example.com/'})

      WebMock
        .stub_request(:delete, 'https://www.example.com/redirect_303')
        .with(
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent'=>'Ruby',
          }
        )
        .to_return(status: 303, headers: {'Location': 'https://www.example.com/'})

      WebMock
        .stub_request(:any, 'https://www.example.com/redirect_303_infinity')
        .with(
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent'=>'Ruby',
          }
        )
        .to_return(status: 303, headers: {'Location': 'https://www.example.com/redirect_303_infinity'})

      WebMock
        .stub_request(:any, 'https://www.example.com/')
        .with(
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent'=>'Ruby',
            'Token'=>'123'
          }
        )
        .to_return(status: 200, headers: {'Token': '123'})
    end
    after :all do
      WebMock.reset!
    end

    let(:err_result) {
      http_delete(
        host_with_ssl + '/redirect_303_infinity',
        force_ssl: true, headers: { token: '123'}
      )
    }

    it do
      expect{err_result}.to raise_error(ReeHttp::HttpExceptions::TooManyRedirectsError)

      http_delete(
        host_with_ssl + '/redirect_307',
        force_ssl: true, headers: { token: '123'}
      )
      expect(WebMock).to have_requested(:delete, host_with_ssl).with(headers: { 'Token'=>'123' })

      http_delete(
        host_with_ssl + '/redirect_303',
        force_ssl: true, headers: { token: '123'}
      )
      expect(WebMock).to have_requested(:get, host_with_ssl).with(headers: { 'Token'=>'123' })
    end
  end
end
