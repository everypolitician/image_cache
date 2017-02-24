require 'image_cache/cacher'
require 'image_cache/countries'

module ImageCache
  def self.cache!(country_slug, github_repo, sizes)
    country = Countries.new.country(country_slug)
    Cacher.new(country, github_repo, sizes).cache!
  end
end
