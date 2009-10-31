# Author: Ernesto Jiménez <erjica@gmail.com>
 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.
 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the MIT
# License for more details.
 
# You should have received a copy of the MIT License along with this
# program. If not, see <http://www.opensource.org/licenses/mit-license.php>

require 'singleton'
require 'observer'
require 'twitter/stream/http'

module Twitter
  module Stream
    class Filter
      include Singleton
      include Observable
      PATH = "/statuses/filter.json"
      
      def run(word)
        raise ArgumentError, "No suscribers" if self.count_observers == 0
        self.segment = ""
        loop do
        Twitter::Stream::HTTP::Request(:GET, PATH, :track => word) { |req, http|
          http.request(req) { |res|
            res.read_body { |segment|
              add_segment(segment)
            }
          }
        }
        sleep(10)
        end
      end
      
      attr_accessor :segment
      def add_segment(value)
        @segment << value
        tweets = @segment.split(/\r/)
        @segment = tweets.pop
        tweets.each { |t|
          changed
          notify_observers(JSON.parse(t))
        }
      end
    end
  end
end
