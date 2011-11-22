require 'rubygems'
require 'sinatra'
require "uri"
require 'net/http'
require 'net/https'
require 'json'
require 'sinatra/memcache'  # sinatra support => https://github.com/gioext/sinatra-memcache


# Memcached config
set :cache_server, "localhost:11211"
set :cache_namespace, "bridge-memcache"
set :cache_enable, true
set :cache_logging, true
set :cache_default_expiry, 60*1   # seconds, default => 1 min
set :cache_default_compress, true


get '/' do
  headers = params['h'] ? JSON.parse(params['h']) : {}
  url = URI.parse(params['u'])
  path = url.path == "" ? "/" : url.path + "?" + (url.query||"")  # required when url.query is present in get request

  if params['m'] == 'get'
    request = Net::HTTP::Get.new(path)
  elsif params['m'] == 'post'
    request = Net::HTTP::Post.new(path)
  elsif params['m'] == 'put'
    request = Net::HTTP::Put.new(path)
  elsif params['m'] == 'delete'
    request = Net::HTTP::Delete.new(path)
  elsif params['m'] == 'head'
    request = Net::HTTP::Head.new(path)
  else
    request = Net::HTTP::Get.new(path)
  end

  headers.each do |key, value|
    request.add_field(key, value)
  end

  request.body = params['b'] if params['b']

  http = Net::HTTP.new(url.host, url.port)

  # Know when to use https
  http.use_ssl = true if url.scheme == "https"

  response = http.start do |http|
    if params['c'] == "true"
      timeout = (params["cn"].to_i == 0 ? 1 : params["cn"].to_i)
      cache params['u'], :expiry => (60 * timeout) do
        http.request(request) # uncached request
      end
    else
      http.request(request) # uncached request
    end

  end

  arg = "{ status: #{response.code}, headers: [#{response.each_name { }.to_json}], body: \"#{URI.escape(response.body)}\" }"
  json = "#{params['jsonp']}(#{arg});"
end
