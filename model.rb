require 'dm-core'
require 'dm-migrations'
require 'restclient'
require 'xmlsimple'
require 'dm-timestamps'

class ShortenedUrl
  include DataMapper::Resource

  property :id, Serial
  property :url, Text
  property :url_corta, Text
  property :usuario, Text
  property :n_visits, Integer

  # has n, :visits
end

class Visit
  include DataMapper::Resource

  property :id, Serial
  property :created_at, DateTime
  property :ip, IPAddress
  property :country, String

  # belongs_to :shortenedurl
end
