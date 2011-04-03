# -*- coding: utf-8 -*-

module YALTools
  
  # == Description
  #
  # YALTools::YaJsonRows is a container of json rows.
  #
  # == Usage
  #
  # Here is an example to delete all documents of the example db.
  #
  #    @couch = YALTools::Main.new(host, port, opts)
  #    ...
  #    json = @couch.get("/example/_all_docs")
  #    delete_list = YALTools::YaJsonRows.new(@couch, "example")
  #    json["rows"] do |item|
  #      delete_list << item
  #    end
  #    failed_list = delete_list.delete_all
  #
  # In the other way, it can delete json rows reading from $stdin
  # and with the update_all method.
  #
  #    update_list = YALTools::YaJsonRows.new(@couch, @dbname)
  #    $stdin.each_line do |line|
  #      begin
  #        json = JSON::parse(line)
  #        json["_deleted"] = true
  #      rescue
  #        json = {}
  #      ensure
  #         update_list << line if not json.empty?
  #      end
  #    end
  #    failed_list = update_list.update_all
  #
  # The "update_all" method helps to add, delete or modify key/value.
  #
  # 
  class YaJsonRows < Array

    attr_accessor :debug

    # When creating initial document without "_id", POST method is required.
    # 
    # In this case, the "post" string can be pass to the +method+ argument.
    def initialize(couch, dbname)
      @couch = couch
      @dbname = dbname

      @debug = false
    end
    
    # adds "_deleted" = true to each item and  executes update query.
    #
    # The delete_all finally returns the failed json rows.
    def delete_all
      self.each do |i|
        i["_deleted"] = true
      end
      update_all
    end
    
    # posts all item to _bulk_docs interface, then it returns failed json rows.
    def update_all
      uri = format("/%s/_bulk_docs", @dbname)
      json = { "docs" => self }
      res = @couch.post(uri,json)
      $stderr.puts "[debug] res=#{res}" if @debug
      self.clear
      failed_list = self.clone
      if res.kind_of?(Net::HTTPSuccess)
        JSON.parse(res.body).each do |doc|
          if doc.has_key?("error")
            failed_list << doc
            $stderr.puts "[debug] error_doc=#{doc}" if @debug
          end
        end
      else
        begin
          json = JSON.parse(res.body)
          failed_list << json
        rescue
          failed_list << res.body
        end
      end
      return failed_list
    end
    alias post_all update_all
    
    #---
    # overrides some array specific methods
    #+++
    
    # overrides Array::push method
    alias :original_push :push
    
    # new push method
    def push(json)
      case json
      when String
        hash = {}
        begin 
          hash = JSON::parse(json)
        rescue
          hash = {}
        ensure
          original_push(hash)
        end
      when Hash
        original_push(json)
      when Array
        $stderr.puts "[warn] Array json representation in YALTools::YaJsonRows is as-is basis."
        original_push(json)
      end
    end
    
    # overrides << method by new push method.
    alias :<< :push
  end
end
