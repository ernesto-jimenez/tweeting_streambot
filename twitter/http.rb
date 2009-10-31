require 'base/http'

module Twitter
  class HTTP < Base::HTTP
    self.host = "twitter.com"
    self.accept = :json
  end
end
