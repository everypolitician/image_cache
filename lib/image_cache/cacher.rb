require 'csv'
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
    attr_reader :extra_csv
    attr_reader :sizes

    def initialize(country, github_repo, extra_csv, sizes)
      @country = country
      @github_repo = github_repo
      @extra_csv = extra_csv
      @sizes = sizes
    end

    def extract_from_ep(legislature)
      # Return a two element array where the first element is the
      # directory for the images, and the second is an array of hashes
      # where each hash corresponds to a person.
      popolo_url = "https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/#{legislature[:popolo]}"
      popolo = JSON.parse(open(popolo_url).read, symbolize_names: true)
      [legislature[:slug], popolo[:persons]]
    end

    def extract_from_csv(csv_metadata)
      # Return a two element array where the first element is the
      # directory for the images, and the second is an array of hashes
      # where each hash corresponds to a person.
      [
        csv_metadata['dir'],
        CSV.parse(open(csv_metadata['url']), :headers => :first_line).map do |row|
          {
            :id => row['id'],
            :image => row['image_url']
          }
        end
      ]
    end

    def cache!
      options = { branch: 'gh-pages', message: 'Update image cache' }
      with_git_repo(github_repo, options) do
        cache_country(country)
      end
    end

    def house_to_people
      (
        country[:legislatures].map do |legislature|
          extract_from_ep(legislature)
        end + extra_csv.map do |csv_metadata|
          extract_from_csv(csv_metadata)
        end
      ).to_h
    end

    def cache_country(country)
      house_to_people.map do |directory, people|
        FileUtils.mkdir_p(directory)
        filelist = Parallel.map(people, in_threads: 3) do |person|
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
