#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'
require 'uri'
require 'pp'
#require 'socket'
require 'data_mapper'
require 'omniauth-oauth2'
require 'omniauth-google-oauth2'
require 'erubis'

############OmniAuth Google####################
use OmniAuth::Builder do
  config = YAML.load_file 'config/config.yml'
  provider :google_oauth2, config['identifier'], config['secret']
end

enable :sessions
set :session_secret, '*&(^#234a)'
###############################################

DataMapper.setup( :default, ENV['DATABASE_URL'] ||
                            "sqlite3://#{Dir.pwd}/my_shortened_urls.db" ) if development?
DataMapper.setup( :default, ENV['DATABASE_URL'] ) if production?
DataMapper::Logger.new($stdout, :debug)
DataMapper::Model.raise_on_save_failure = true

require_relative 'model'

DataMapper.finalize

#DataMapper.auto_migrate!
DataMapper.auto_upgrade!

Base = 36

get '/' do
  puts "inside get '/': #{params}"
#   session[:email] = ""
  @list = ShortenedUrl.all(:order => [ :id.asc ], :limit => 20, :usuario => session[:email])
  # in SQL => SELECT * FROM "ShortenedUrl" ORDER BY "id" ASC
  haml :index
end

post '/' do
  puts "inside post '/': #{params}"
  uri = URI::parse(params[:url])
  if uri.is_a? URI::HTTP or uri.is_a? URI::HTTPS then
    begin
      @short_url = ShortenedUrl.first_or_create(:url => params[:url], :url_corta => params[:url_corta], :usuario => session[:email], :n_visits => 0)
    rescue Exception => e
      puts "EXCEPTION!!!!!!!!!!!!!!!!!!!"
      pp @short_url
      puts e.message
    end
  else
    logger.info "Error! <#{params[:url]}> is not a valid URL"
  end
  redirect '/'
end

get '/:shortened' do
  puts "inside get '/:shortened': #{params}"

  short_url = ShortenedUrl.first(:url_corta => params[:shortened].to_s)

  puts short_url.n_visits
  short_url.n_visits += 1
  puts short_url.n_visits
  short_url.save

  # HTTP status codes that start with 3 (such as 301, 302) tell the
  # browser to go look for that resource in another location. This is
  # used in the case where a web page has moved to another location or
  # is no longer at the original location. The two most commonly used
  # redirection status codes are 301 Move Permanently and 302 Found.
  redirect short_url.url, 301
end

get '/auth/:name/callback' do
  session[:auth] = @auth = request.env['omniauth.auth']
  session[:email] = @auth['info'].email

  if session[:auth] then
    begin
      puts "inside get '/': #{params}"
      @list = ShortenedUrl.all(:order => [ :id.asc ], :limit => 20, :usuario => session[:email])
      haml :index
    end
  else
    redirect '/auth/failure'
  end
end

get '/auth/failure' do
  session.clear
  redirect '/'
end

get '/auth/cerrarSesionGoogle' do
  session.clear
  redirect '/'
end

get '/estadisticas/ver' do
  total_visitas = 0
  lista = ShortenedUrl.all(:order => [:id.asc])
  for i in 0...3 do
    total_visitas += lista[i].id
  end

  

  haml :estad
end

error do haml :index end
