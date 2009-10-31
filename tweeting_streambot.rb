# Author: Ernesto Jiménez <erjica@gmail.com>
 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.
 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the MIT
# License for more details.
 
# You should have received a copy of the MIT License along with this
# program. If not, see <http://www.opensource.org/licenses/mit-license.php>

require 'rubygems'
require 'json'

require 'twitter/statuses'
require 'twitter/stream/filter'

class TweetingStreambot
  attr_accessor :user, :password
  
  def initialize(user, password, *keywords)
    Twitter::Stream::HTTP.user = self.user = user
    Twitter::Stream::HTTP.password = self.password = password
    
    Twitter::Stream::Filter.instance.add_observer(self)
    Twitter::Stream::Filter.instance.run(keywords.join(","))
  end
  
  def update(tweet)
    status = "RT @#{tweet["user"]["screen_name"]}: #{tweet["text"]}"[0..140]
    if status.size == 141
      status = "#{status[0..138]}…"
    end
    Twitter::Statuses.update(self.user, self.password, status)
  end
end

# Example
TweetingStreambot.new("user", "pasword", "#rubyconf", "#rbconf")
