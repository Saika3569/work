require "uri"
require "net/http"
require "openssl"
require "base64"
require "ostruct"
require "json"
require "zlib"
require 'awesome_print'
require 'terminal-notifier'
require 'byebug'
require_relative './key.rb'

class ApiPtxData

  def initialize(**options)
    @app_id = options[:id]
    @app_key = options[:key]
    @bus_api = "https://ptx.transportdata.tw/MOTC/v2/Bus/RealTimeNearStop/City/Taipei/672?$filter=Direction%20eq%201&$orderby=StopSequence&$format=JSON"
  end

  def perform
    return TerminalNotifier.notify('有靠近的車輛', title: near_station.name) if near_station

    '目前還沒有靠近的車輛'
  end

  private

  def near_station
    near_station = get_response(uri: @bus_api, gzip: false).json.select {|data| (2..4).include?(data["StopSequence"]) }[0]

    OpenStruct.new(
      name: near_station['StopName']['Zh_tw']
    ) unless near_station.nil?

  end

  def get_response(uri:, gzip: false, options: {})
    uri_parser = URI.parse(uri)
    timestamp = get_gmt_timestamp
    hmac = encode_by_hmac_sha1(@app_key, 'x-date: ' + timestamp)

    request = Net::HTTP::Get.new(uri_parser)
    request["Accept"] = "application/json"
    request["Accept-Encoding"] = "gzip" if gzip
    request["X-Date"] = timestamp
    request["Authorization"] = %Q(hmac username=\"#{@app_id}\", algorithm=\"hmac-sha1\", headers=\"x-date\", signature=\"#{hmac}\")

    req_options = {
      use_ssl: uri_parser.scheme == "https",
    }.merge(options)

    response = Net::HTTP.start(uri_parser.hostname, uri_parser.port, req_options) do |http|
      http.request(request)
    end

    OpenStruct.new(
      code: response.code,
      json: parse_json_response(response),
      response: response,
    )
  end

  def get_gmt_timestamp
    Time.now.utc.strftime("%a, %d %b %Y %T GMT")
  end

  def encode_by_hmac_sha1(key, value)
    Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest.new('sha1'),
        key,
        value,
      )
    ).strip
  end

  def parse_json_response(response)
    response_body = case response.header["content-encoding"]
    when "gzip"
      sio = StringIO.new(response.body)
      gz = Zlib::GzipReader.new(sio)
      gz.read()
    else
      response.body
    end

    JSON.parse(response_body.force_encoding("UTF-8"))
  rescue => e
    puts "parse json response error!, #{e}"
    nil
  end
end

ap ApiPtxData.new(id: API_ID, key: API_KEY).perform
