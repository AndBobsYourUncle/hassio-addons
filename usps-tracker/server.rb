require 'rubygems'
require 'bundler'

Bundler.require

require 'sinatra'
require 'rufus/scheduler'
require 'rack/conneg'

scheduler = Rufus::Scheduler.new

scheduler.in '1s' do
  authenticate_google
end

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
OPTIONS = JSON.parse(file)

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

APPLICATION_NAME = OPTIONS['project_id'].freeze
CREDENTIALS_PATH = OPTIONS['client_secrets'].freeze
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = if Sinatra::Base.production?
  "/data/token.yaml".freeze
else
  "token.yaml".freeze
end

SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY

def authenticate_google(code: '')
  client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
  token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
  authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
  user_id = "default"
  credentials = authorizer.get_credentials user_id
  if credentials.nil? && code.empty?
    url = authorizer.get_authorization_url base_url: OOB_URI
    puts "Open the following URL in the browser and enter the " \
         "resulting code after authorization into the WebUI of this addon:\n" + url
  elsif credentials.nil?
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

get '/authenticate' do
  erb :authenticate
end

post '/authenticate' do
  authenticate_google(code: params['code'])

  erb :authenticated
end

get '/test' do
  service = Google::Apis::GmailV1::GmailService.new
  service.client_options.application_name = APPLICATION_NAME
  service.authorization = authenticate_google

  messages = service.list_user_messages("me", q: "from:auto-reply@usps.com after:1575750604").messages

  message = service.get_user_message("me", messages.first.id)

  subject = message.payload.headers.find { |header| header.name == 'Subject'}.value

  puts subject

  [200, {"status": CREDENTIALS_PATH}.to_json]
end
