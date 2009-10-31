require 'twitter/http'

module Twitter
  module Stream
    class HTTP < Twitter::HTTP
      self.host = "stream.twitter.com"
      self.accept = :json
      self.user = "testmine"
      self.password = "12341234"
      self.base_path = "/1"
    end
  end
end
