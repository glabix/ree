# frozen_string_literal: true
require 'webmock/rspec'

RSpec.describe :http_patch do
  link :http_patch, from: :ree_http

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
        .stub_request(:patch, /example/)
        .with(
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent'=>'Ruby'
          }
        )
        .to_return(status: 200, headers: {})
    end

    it "no ssl" do
      http_patch(host)
      expect(WebMock).to have_requested(:patch, host)

      http_patch(
        host,
        basic_auth: {username: 'user', password: 'pass'}
      )
      expect(WebMock).to have_requested(:patch, host).with(basic_auth: ['user', 'pass'])

      http_patch(
        host,
        bearer_token: 'token'
      )
      expect(WebMock).to have_requested(:patch, host).with(headers: { 'Authorization': "Bearer token" })

      http_patch(
        host,
        query_params: { q: 100, "s"=> 'simple'}
      )
      expect(WebMock).to have_requested(:patch, host).with(query: { "q"=> 100, "s"=> "simple"})

      http_patch(
        host_with_path + '?a=200',
        query_params: { q: 100, "s"=> 'simple'}
      )
      expect(WebMock).to have_requested(:patch, host_with_path).with(query: {"a"=>200, "q"=> 100, "s"=> "simple"})

      http_patch(
        host_with_path + '?a=200',
        query_params: { q: 100, "s"=> 'simple'},
        body: "abc"
      )
      expect(WebMock).to have_requested(:patch, host_with_path).with(
        query: {"a"=>200, "q"=> 100, "s"=> "simple"},
        body: "abc"
      )
    end
  end

  context "force ssl" do

    before :all do
      WebMock.reset!
      WebMock
        .stub_request(:patch, 'https://www.example.com')
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
      http_patch(
        host,
        force_ssl: true, headers: { token: '321'}
      )
      expect(WebMock).to have_requested(:patch, host_with_ssl).with(headers: { 'Token'=>'321' })
    end
  end

  context "redirect" do
    before :all do
      WebMock.reset!
      WebMock
        .stub_request(:patch, 'https://www.example.com/redirect_307')
        .with(
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent'=>'Ruby',
          }
        )
        .to_return(status: 307, headers: {'Location': 'https://www.example.com/'})

      WebMock
        .stub_request(:patch, 'https://www.example.com/redirect_303')
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
            'Host' => 'www.example.com'
          }
        )
        .to_return(status: 200)
    end
    after :all do
      WebMock.reset!
    end

    let(:err_result) {
      http_patch(
        host_with_ssl + '/redirect_303_infinity',
        force_ssl: true, headers: { token: '123'}
      )
    }

    it do
      expect{err_result}.to raise_error(ReeHttp::HttpExceptions::TooManyRedirectsError)

      http_patch(
        host_with_ssl + '/redirect_307',
        force_ssl: true, headers: { token: '123'}
      )

      expect(WebMock).to have_requested(:patch, host_with_ssl + '/redirect_307').with(headers: { 'Token'=>'123' }).once
      expect(WebMock).to have_requested(:patch, host_with_ssl).once

      http_patch(
        host_with_ssl + '/redirect_303',
        force_ssl: true, headers: { token: '123'}
      )

      expect(WebMock).to have_requested(:patch, host_with_ssl + '/redirect_303').with(headers: { 'Token'=>'123' }).once
      expect(WebMock).to have_requested(:get, host_with_ssl).once
    end
  end
end
