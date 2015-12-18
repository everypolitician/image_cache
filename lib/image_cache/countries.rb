module ImageCache
  class Countries
    def country(slug)
      @country ||= countries.find { |c| c[:slug] == slug }
    end

    def countries
      @countries ||= JSON.parse(countries_json, symbolize_names: true)
    end

    def countries_json
      @countries_json ||= open(countries_json_url).read
    end

    def countries_json_url
      @countries_json_url ||= "https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/countries.json"
    end
  end
end
