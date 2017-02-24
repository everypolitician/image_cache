require 'parallel'
require 'everypoliticianbot'
require 'fileutils'
require 'json'
require 'open-uri'
require 'tempfile'
require 'rmagick'

module ImageCache
  class Cacher
    include Everypoliticianbot::Github

    attr_reader :country
    attr_reader :github_repo
    attr_reader :sizes

    def initialize(country, github_repo, sizes)
      @country = country
      @github_repo = github_repo
      @sizes = sizes
    end

    def cache!
      options = { branch: 'gh-pages', message: 'Update image cache' }
      with_git_repo(github_repo, options) do
        cache_country(country)
      end
    end

    def cache_country(country)
      country[:legislatures].each do |legislature|
        popolo_url = "https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/#{legislature[:popolo]}"
        popolo = JSON.parse(open(popolo_url).read, symbolize_names: true)
        directory = legislature[:slug]
        FileUtils.mkdir_p(directory)
        filelist = Parallel.map(popolo[:persons], in_threads: 3) do |person|
          cache_person(person, directory)
        end
        index_file = File.join(directory, 'index.txt')
        File.write(index_file, filelist.flatten.compact.sort.join("\n"))
      end
    end

    def with_downloaded_file(url)
      contents = open(url, &:read)
      temporary_file = Tempfile.open('ep-image_cache') do |f|
        f.write(contents)
        f
      end
      block_result = yield temporary_file.path
      temporary_file.unlink
      block_result
    end

    def resize_image(original_filename, reduced_filename, width, height)
      img = Magick::Image.read(original_filename).first
      reduced = img.resize_to_fit!(width, height)
      reduced.background_color = 'white'
      img.write(reduced_filename)
    end

    def cache_person(person, basedir)
      return if person[:image].to_s.empty?
      person_id = person[:id]
      # TODO: Check if the image is actually a jpeg
      person_directory = File.join(basedir, person_id)
      FileUtils.mkdir_p(person_directory)
      with_downloaded_file(person[:image]) do |local_filename|
        sizes.map do |size|
          relative_filepath = File.join(person_id, "#{size}.jpeg")
          filepath = File.join(basedir, relative_filepath)
          next relative_filepath if File.exist?(filepath) && !ENV['FORCE_UPDATE']
          begin
            if size == 'original'
              FileUtils.cp(local_filename, filepath)
              log "Copied #{person[:image]} to #{filepath}"
            else
              width, height = size.match(/(\d+)x(\d+)/).captures
              width, height = Integer(width), Integer(height)
              resize_image(local_filename, filepath, width, height)
              log "Resized #{person[:image]} to #{filepath}"
            end
          rescue OpenURI::HTTPError => e
            err "Error trying to cache #{person[:image]}: #{e}"
            next
          end
          relative_filepath
        end
      end
    end

    private

    def log(*args)
      puts(*args) unless ENV['QUIET']
    end

    def err(*args)
      warn(*args) unless ENV['QUIET']
    end
  end
end
