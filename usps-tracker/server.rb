# frozen_string_literal: true

require 'rubygems'
require 'bundler'

Bundler.require

require 'sinatra'
require 'rufus/scheduler'
require 'rack/conneg'
require 'sinatra/activerecord'
require 'sinatra/jbuilder'

require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'logger'

require './models/package'

OPTIONS_FILE = Sinatra::Base.production? ? '/data/options.json' : 'options.json'

file = File.read(OPTIONS_FILE)
OPTIONS = JSON.parse(file)

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

APPLICATION_NAME = OPTIONS['project_id'].freeze
CREDENTIALS_PATH = OPTIONS['client_secrets'].freeze
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = Sinatra::Base.production? ? '/data/token.yaml' : 'token.yaml'

SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY

def authenticate_google(code: '')
  client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
  token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
  authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
  user_id = 'default'
  credentials = authorizer.get_credentials user_id
  if credentials.nil? && code.empty?
    url = authorizer.get_authorization_url base_url: OOB_URI
    puts 'Open the following URL in the browser and enter the ' \
         "resulting code after authorization into this addon's WebUI: " + url
    puts "\nYou might need to replace the domain with the IP of your Home " \
         ' Assistant instance when opening the WebUI for the addon.'
    puts "It isn't recommended to expose this addon to the Internet."
  elsif credentials.nil?
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

def fetch_new_messages
  logger = Logger.new(STDOUT)

  service = Google::Apis::GmailV1::GmailService.new
  service.client_options.application_name = APPLICATION_NAME
  service.authorization = authenticate_google

  return unless authenticate_google.present?

  latest_timestamp = Package.latest_timestamp

  query = 'from:auto-reply@usps.com'

  if latest_timestamp.nil?
    latest_timestamp = Chronic.parse(OPTIONS['earliest_fetch_time']).to_i
  end

  query += " after:#{latest_timestamp}"

  logger.info 'Querying for latest messages...'
  messages = service.list_user_messages('me', q: query).messages

  if messages.nil?
    logger.info 'No new messages found...'
    return
  end

  logger.info 'Getting full message bodies...'
  full_messages = messages.map do |message_info|
    service.get_user_message('me', message_info.id)
  end

  sorted_messages = full_messages.sort_by(&:internal_date)

  sorted_messages.each do |message|
    subject = message.payload.headers.find { |h| h.name == 'Subject' }.value
    logger.info subject

    package = Package.upsert_with_message(message)
    logger.info package.inspect
  end
end

scheduler = Rufus::Scheduler.new

scheduler.in '1s' do
  fetch_new_messages
end

scheduler.every OPTIONS['fetch_interval'] do
  fetch_new_messages
end

configure do
  set :server, :puma # default to puma for performance
  set :bind, '0.0.0.0'
  if Sinatra::Base.production?
    set :database, 'sqlite3:/data/usps-tracker.sqlite3'
  else
    set :database, 'sqlite3:usps-tracker.sqlite3'
  end
end

use(Rack::Conneg) do |conneg|
  conneg.set :accept_all_extensions, false
  conneg.set :fallback, :json
  conneg.provide([:json])
end

get '/authenticate' do
  erb :authenticate
end

post '/authenticate' do
  authenticate_google(code: params['code'])

  erb :authenticated
end

get '/packages' do
  @packages = Package.all

  jbuilder :package_index
end

get '/delivered_today_count' do
  @package_count = Package.delivered.where(delivered_at: (Date.today.beginning_of_day..Date.today.end_of_day))

  puts @package_count.to_sql

  @package_count = @package_count.count

  jbuilder :delivered_today_count
end

get '/enroute_count' do
  @package_count = Package.enroute.count

  jbuilder :enroute_count
end
