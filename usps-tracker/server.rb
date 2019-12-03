require 'rubygems'
require 'bundler'

Bundler.require

require 'sinatra'
require 'rufus/scheduler'
require 'rack/conneg'

# scheduler = Rufus::Scheduler.new

# scheduler.every '2s' do
#   puts 'heh heh'
# end

require "google/apis/gmail_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

OPTIONS_FILE = if Sinatra::Base.production?
  '/data/options.json'
else
  'options.json'
end

file = File.read(OPTIONS_FILE)
options_json = JSON.parse(file)

OOB_URI = "https://serveraddress".freeze
APPLICATION_NAME = "Home Assistant USPS Tracker".freeze
CREDENTIALS_PATH = options_json['client_secrets'].freeze
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = if Sinatra::Base.production?
  "/data/token.yaml".freeze
else
  "token.yaml".freeze
end

SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY


# service = Google::Apis::GmailV1::GmailService.new
# service.client_options.application_name = APPLICATION_NAME
# service.authorization = authorize

def authenticate_google(code: '')
  client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
  token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
  authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store, '/authorize'
  user_id = "default"
  credentials = authorizer.get_credentials user_id
  if credentials.nil? && code.empty?
    url = authorizer.get_authorization_url base_url: OOB_URI
    puts "Open the following URL in the browser and enter the " \
         "resulting code after authorization:\n" + url
  else
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
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

authenticate_google

# get '/authenticate' do
#   erb :authenticate
# end

post '/authenticate' do
  puts params.to_s
end

get '/test' do
  [200, {"status": CREDENTIALS_PATH}.to_json]
end
