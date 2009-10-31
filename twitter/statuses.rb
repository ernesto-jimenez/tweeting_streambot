require 'twitter/http'

module Twitter
  class Statuses
    def self.update(username, password, status)
      response = Twitter::HTTP::Auth(username, password)::POST("/statuses/update.json", :status => status)
    end
  end
end
