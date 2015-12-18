require 'image_cache/cacher'
require 'image_cache/countries'

module ImageCache
  def self.cache!(country_slug, github_repo)
    country = Countries.new.country(country_slug)
    Cacher.new(country, github_repo).cache!
  end
end
