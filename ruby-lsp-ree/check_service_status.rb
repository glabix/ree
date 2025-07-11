require 'rufus-scheduler'
require 'net/http'
require 'uri'
require 'json'

# Replace these with your Yandex Cloud API details
YANDEX_CLOUD_API_URL = 'https://monitoring.api.cloud.yandex.net/monitoring/v2/checks'
AUTH_TOKEN = 'YOUR_YANDEX_CLOUD_AUTH_TOKEN'
SERVICE_ID = 'YOUR_SERVICE_ID'

def is_service_online
  uri = URI("#{YANDEX_CLOUD_API_URL}/#{SERVICE_ID}")
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{AUTH_TOKEN}"
  request['Content-Type'] = 'application/json'

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  if response.is_a?(Net::HTTPSuccess)
    data = JSON.parse(response.body)
    puts "Service is online: #{data}"
  else
    puts "Failed to reach Yandex Cloud API: #{response.code}"
  end
end

scheduler = Rufus::Scheduler.new

scheduler.every '1m' do
  puts 'Checking service status...'
  is_service_online
end

scheduler.join

