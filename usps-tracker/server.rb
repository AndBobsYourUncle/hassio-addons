require 'rubygems'
require 'bundler'

Bundler.require

require 'sinatra'
require 'rufus/scheduler'
require 'rack/conneg'

scheduler = Rufus::Scheduler.new

scheduler.every '2s' do
  puts 'heh heh'
end

configure do
  set :server, :puma # default to puma for performance
  set :bind, '0.0.0.0'
end

use(Rack::Conneg) { |conneg|
  conneg.set :accept_all_extensions, false
  conneg.set :fallback, :json
  conneg.provide([:json])
}

before do
  if negotiated?
    content_type negotiated_type
  end
end

get '/test' do
  [200, {"status": "OK"}.to_json]
end
