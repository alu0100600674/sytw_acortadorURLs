class ShortenedUrl
  include DataMapper::Resource

  property :id, Serial
  property :url, Text
  property :url_corta, Text
  property :usuario, Text
end

