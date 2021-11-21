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

class ApiPtxData

  def initialize
    @app_id = "8140620599e6417ab36ee14283a8759f"
    @app_key = "5424dazV1511nHq2pKAkFytx0Ok"
    @bus_api = "https://ptx.transportdata.tw/MOTC/v2/Bus/RealTimeNearStop/City/Taipei/672?$format=JSON"
  end

  def perform

    if near_station.any?
      TerminalNotifier.notify('有靠近的車輛', title: arr(near_station)[:name], sub_title: arr(near_station)[:plate_numb])
    else
      '目前還沒有靠近的車輛'
    end
  end
  private

  def attr(*near_station)
    {
      plate_numb: near_station['PlateNumb'],
      name: near_station['StopName']['Zh_tw']
    }
  end

  def near_station
    filter_direction.select {|data| (2..4).include?(data["StopSequence"]) }
  end

  def filter_direction
    get_response(uri: @bus_api, gzip: false).json.reject { |data| data['Direction'].zero? }
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


ap ApiPtxData.new.perform
