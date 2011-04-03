# -*- coding: utf-8 -*-

module YALTools

  # == Description
  #
  # YALTools::Main class is a wrapper class for the Couch::Server class which is described at the official CouchDB wiki.
  #
  # It aims to handle errors.
  #
  # == Usage
  #
  #   @couch = Main.new(Couch::Server.new(host,port))
  #   json = @couch.get("/example/_design/all/_view/all?reduce=false")
  #
  
  class Main

    attr_accessor :debug
    
    def initialize(couch = nil)
      @couch = couch
      @debug = false
    end

    # returns the result of the JSON.parse(Net::HTTPResponse.body)
    #
    # If the return object contains the "error" key, the {} will be returned.
    #
    # If it's failed to parse the (Net::HTTPResponse).body, then return the (Net::HTTPResponse).body.
    #
    def get(uri)
      json = {}
      begin
        res = @couch.get(URI.escape(uri))
        json = JSON.parse(res.body)
        if json.kind_of?(Hash) and json.has_key?("error")
          json = {}
        end
      rescue
        $stderr.puts $! if @debug
        json = res.body
      end
      return json
    end

    # returns the kind of Net::HTTPResponse instance.
    # When an error occures, it returns nil.
    def put(uri, json)
      res = nil
      begin
        res = @couch.put(URI.escape(uri), json.to_json)
      rescue
        $stderr.puts $! if @debug
      end
      return res
    end

    # returns the kind of Net::HTTPResponse instance.
    # When an error occures, it returns nil.
    def post(uri, json)
      res = nil
      begin
        res = @couch.post(URI.escape(uri), json.to_json)
      rescue
        $stderr.puts $! if @debug
      end
      return res
    end
    
    # returns the kind of Net::HTTPResponse instance.
    # When an error occures, it returns nil.
    def delete(uri)
      res = nil
      begin
        res = @couch.delete(URI.escape(uri))
      rescue
        $stderr.puts $! if @debug
      end
      return res
    end

    def head(uri)
      res = nil
      begin
        res = @couch.head(URI.escape(uri))
      rescue
        $stderr.puts $! if @debug
      end
      return res
    end
  end
end
