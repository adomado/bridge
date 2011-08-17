require 'rubygems'
require 'sinatra'
require "uri"
require 'net/http'
#require 'net/https'
require 'json'


get '/' do
  headers = params['h'] ? JSON.parse(params['h']) : {}
  url = URI.parse(params['u'])
  path = url.path == "" ? "/" : url.path

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
  #http.use_ssl = false
  response = http.start do |http|
    http.request(request)
  end

  arg = "{ status: #{response.code}, headers: [#{response.each_name { }.to_json}], body: \"#{URI.escape(response.body)}\" }"
  json = "#{params['jsonp']}(#{arg});"
end
