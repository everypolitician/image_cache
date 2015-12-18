require 'parallel'
require 'everypoliticianbot'
require 'fileutils'
require 'json'
require 'open-uri'

module ImageCache
  class Cacher
    include Everypoliticianbot::Github

    attr_reader :country
    attr_reader :github_repo

    def initialize(country, github_repo)
      @country = country
      @github_repo = github_repo
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
        filelist = Parallel.map(popolo[:persons], in_threads: 3) do |person|
          cache_person(person, directory)
        end
        FileUtils.mkdir_p(directory)
        index_file = File.join(directory, 'index.txt')
        File.write(index_file, filelist.flatten.compact.sort.join("\n"))
      end
    end

    def cache_person(person, basedir)
      return if person[:image].to_s.empty?
      person_id = person[:id]
      # TODO: Check if the image is actually a jpeg
      filepath = File.join(basedir, "#{person_id}.jpeg")
      FileUtils.mkdir_p(File.dirname(filepath))
      return person_id if File.exist?(filepath) && !ENV['FORCE_UPDATE']
      begin
        contents = open(person[:image]).read
        return if contents.empty?
        File.write(filepath, contents)
        log "Copied #{person[:image]} to #{filepath}"
        return person_id
      rescue OpenURI::HTTPError => e
        err "Error trying to cache #{person[:image]}: #{e}"
        return
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
