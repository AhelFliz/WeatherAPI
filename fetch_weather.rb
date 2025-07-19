require "httparty"
require "json"
require "attr_extras"
require "redis"
require "dotenv/load"
# require 'gruff'

class FetchWeather
  static_facade :run, :city

  def run
    save_or_fetch
  end

  def save_or_fetch
    if (cache = redis.get(key))
      puts "Hit - already in cache"
      response = JSON.parse(cache)
    else
      puts "No cache - creating cache"
      response = fetch_and_cache_response
    end
    response
  end

  def fetch_and_cache_response
    api_response = make_api_request

    return { "error" => "City not found or invalid: #{city}" } if api_response.code != 200 || api_response.parsed_response["days"].nil?

    parsed = api_response.parsed_response
    redis.set(key, parsed.to_json, ex: 15 * 60)
    parsed
  end

  def make_api_request
    HTTParty.get(base_uri)
  end

  def base_uri
    "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/#{city}?key=#{api_key}"
  end

  def api_key
    ENV.fetch("WEATHER_API", nil)
  end

  def key
    "weather:#{city.downcase.strip}"
  end

  def redis
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", nil))
  end
end
