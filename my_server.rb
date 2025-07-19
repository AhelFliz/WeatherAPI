require_relative 'fetch_weather'
require "webrick"
require "erb"
require "net/http"
require "json"
require "uri"

class MyServer < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(request, response)
    path = (request.path == '/') ? 'home' : URI.decode(request.path[1..])
    template_file = File.join(__dir__, 'templates', "#{path}.html.erb")

    @location = request.query['location']&.strip
    @location = 'Madrid' if @location.nil? || @location.empty?

    @weather = FetchWeather.run(@location)

    analyze_file(template_file, response)
  end

  def analyze_file(template_file, response)
    if File.exist?(template_file)
      template = File.read(template_file)
      result = ERB.new(template).result(binding)

      response.status = 200
      response['Content-Type'] = 'text/html; charset=UTF-8'
      response.body = result
    else
      response.status = 404
      response.body = "<h1>404 – Template not found: #{path}</h1>"
    end
  end
end

server = WEBrick::HTTPServer.new(Port: 8000)
server.mount '/', MyServer
trap 'INT' do
  server.shutdown
end
server.start
