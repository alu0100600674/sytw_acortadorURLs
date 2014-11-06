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
require 'chartkick'

require 'restclient'
require 'xmlsimple'

require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'

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

  puts "*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*"

  loc_datos = get_localizacion
  visit = Visit.new(:id => short_url.id, :created_at => Time.now, :ip => loc_datos['ip'], :country => loc_datos['countryName'])
  visit.save

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

get'/otros/urlsGuardadas' do
  haml :index
end

get '/estadisticas/visitas' do
  lista = ShortenedUrl.all(:order => [:id.asc])

  @lista_visitas = Array.new
  for i in 0...lista.length do
    tmp1 = lista[i].url_corta
    tmp2 = lista[i].n_visits
    @lista_visitas.push([tmp1, tmp2])
  end

  haml :estad
end

get '/estadisticas/paises' do
  lista = Visit.all(:order => [:id.asc])

  @lista_visitas = Array.new
  for i in 0...lista.length do
    tmp1 = lista[i].created_at
    tmp2 = lista[i].id  #Sustituir por número de visitas de cada día.
    @lista_visitas.push([tmp1, tmp2])
  end

  haml :lugares
end

get '/estadisticas/dias' do
  lista = Visit.all(:order => [:id.asc])

  @lista_visitas = Array.new
  for i in 0...lista.length do
    tmp1 = lista[i].created_at
    tmp2 = lista[i].id  #Sustituir por número de visitas de cada día.
    @lista_visitas.push([tmp1, tmp2])
  end

  haml :dias
end

def get_remote_ip(env)
  puts "request.url = #{request.url}"
  puts "request.ip = #{request.ip}"
  if addr = env['HTTP_X_FORWARDED_FOR']
    puts "env['HTTP_X_FORWARDED_FOR'] = #{addr}"
    addr.split(',').first.strip
  else
    puts "env['REMOTE_ADDR'] = #{env['REMOTE_ADDR']}"
    env['REMOTE_ADDR']
  end
end

def get_localizacion
  xml = RestClient.get "http://api.hostip.info/get_xml.php?ip=#{get_remote_ip(env)}";
  cc = XmlSimple.xml_in(xml.to_s)
end

error do haml :index end
