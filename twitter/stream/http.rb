require 'twitter/http'

module Twitter
  module Stream
    class HTTP < Twitter::HTTP
      self.host = "stream.twitter.com"
      self.accept = :json
      self.base_path = "/1"
    end
  end
end
