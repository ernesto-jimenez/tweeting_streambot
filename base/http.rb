# Author: Ernesto Jiménez <erjica@gmail.com>
 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.
 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the MIT
# License for more details.
 
# You should have received a copy of the MIT License along with this
# program. If not, see <http://www.opensource.org/licenses/mit-license.php>

require 'net/http'
require 'net/https'
require 'uri'
require 'cgi'
require 'json'

module Base
  class HTTP
    class << self
      def host
        if defined?(@host)
          @host
        elsif superclass != Object && superclass.host
          superclass.host.dup.freeze
        end
      end
      
      def host=(value)
        @host = value.to_s
      end
      
      def port
        if defined?(@port)
          @port
        elsif superclass != Object && superclass.port
          superclass.port.dup.freeze
        end
      end
      
      def port=(value)
        @port = value.to_s
      end
      
      def accept
        if defined?(@accept)
          @accept
        elsif superclass != Object && superclass.accept
          superclass.accept.dup.freeze
        end
      end
      
      def accept=(value)
        @accept = value.to_s
      end
      
      def base_path
        if defined?(@base_path)
          @base_path
        elsif superclass != Object && superclass.base_path
          superclass.base_path.dup.freeze
        end
      end
      
      def base_path=(value)
        @base_path = value.to_s
      end
      
      def user
        if defined?(@user)
          @user
        elsif superclass != Object && superclass.user
          superclass.user.dup.freeze
        end
      end
      
      def user=(value)
        @user = value.to_s
      end
      
      def password
        if defined?(@password)
          @password
        elsif superclass != Object && superclass.password
          superclass.password.dup.freeze
        end
      end
      
      def password=(value)
        @password = value.to_s
      end
      
      def debugging
        if defined?(@debugging)
          @debugging
        elsif superclass != Object && superclass.debugging
          superclass.debugging.dup.freeze
        end
      end
      
      def debugging=(value)
        @debugging = value.to_s
      end
    end
    
    self.port = "80"
    self.accept = "text/html"
    self.base_path = ""
    
    def self.Host(host)
      hosted_class = self.dup
      hosted_class.host = host
      return hosted_class
    end
    
    def self.Auth(user, password)
      hosted_class = self.dup
      hosted_class.user = user
      hosted_class.password = password
      return hosted_class
    end
    
    def self.Request(method, path, params={}, &block)
      path = build_path(method, path, params)
      
      socket = Net::HTTP.new(host, port)
      socket.use_ssl = true if port == 443
      
      socket.start do |http|
        request = RequestForMethod(method).new(path, {
          'Accept' => build_accept,
          'Host' => host
        })
        request.basic_auth user, password if user && password
        if !params.empty?
          request.set_form_data(params)
        end
        
        yield(request, http) if block_given?
        
        DEBUG(request)
        
        reply = http.request(request)
        
        DEBUG(reply)
        
        return reply
      end
    end
    
    def self.RequestURL(method, url, params={}, &block)
      url = URI.parse(url)
      actual_host = host
      self.host = url.host
      reply = Request(method, url.path, params, &block)
      self.host = actual_host
      return reply
    end
    
    def self.build_accept(accept=accept)
      case accept
      when :json, 'json'
        return "application/json"
      when :xml, 'xml'
        return "application/xml"
      when :html, 'html'
        return "text/html"
      when :text, 'text'
        return "text/plain"
      else
        return accept.to_s
      end
    end
    
    def self.decode(body, format)
      case format
      when "application/json"
        return JSON.parse(body)
      else
        return body
      end
    end
    
    def self.RequestContent(method, path, params={}, &block)
      response = self.Request(method, path, params, &block)
      if response.code.to_s == '200'
        return decode(response.body, build_accept)
      else
        raise ::Base::InvalidResponse
      end
    end
    
    def self.POST(path, params={}, &block)
      response = self.RequestContent(:POST, path, params, &block)
    end
    
    def self.PUT(path, params={}, &block)
      response = self.RequestContent(:PUT, path, params, &block)
    end
    
    def self.DELETE(path, params={}, &block)
      response = self.RequestContent(:DELETE, path, params, &block)
    end
    
    def self.GET(path, params={}, &block)
      response = self.RequestContent(:GET, path, params, &block)
    end
    
    def self.HEAD(path, params={}, &block)
      response = self.RequestContent(:HEAD, path, params, &block)
    end
    
    def self.build_path(method, path, params) # :nodoc:
      if method == :GET && !params.empty?
        query = path.split('?')
        path  = query.shift
        query<< params.collect {|key,value| "#{key}=#{CGI.escape(value)}" }
        path << '?' << query.join('&')
        params.clear
      end
      return "/#{base_path}/#{path}".gsub(%r{//}, '/')
    end
    
    # Returns the correct net/http class for the given method
    def self.RequestForMethod(method) # :nodoc:
      case method
      when :POST, :post
        Net::HTTP::Post
      when :PUT, :put
        Net::HTTP::Put
      when :DELETE, :delete
        Net::HTTP::Delete
      when :GET, :get
        Net::HTTP::Get
      when :HEAD, :head
        Net::HTTP::Head
      else
        raise ArgumentError("invalid method: #{method}\n  Valid methods are :POST, :PUT, :DELETE and :GET")
      end
    end
    
    DEBUGGED_HEADERS = [
      'authorization',
      'status',
      'content-type',
      'accept',
      'content-length',
      'host',
      'location'
    ] # :nodoc:
    
    def self.DEBUG(debug) # :nodoc:
      return unless debugging
      if debug.kind_of?(Net::HTTPRequest)
        puts "#{debug.method} #{debug.path} HTTP/1.1"
      else
        puts "HTTP/#{debug.http_version} #{debug.code} #{debug.message}"
      end
      
      debug.each_key do |key|
        next unless DEBUGGED_HEADERS.include?(key)
        header = key.split('-').collect {|word| word.capitalize }.join('-')
        puts "#{header}: #{debug[key]}"
      end
      
      puts ""
      puts debug.body if debug.body
      puts ""
    end
  end
  
  class InvalidResponse < Exception; end
end
