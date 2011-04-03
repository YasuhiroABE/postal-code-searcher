# -*- coding: utf-8 -*-

module YALTools
  #
  # YALTools::YaDocs is designed to process huge amount of documents through the CouchDB REST API.
  #
  # For the performance, the +page+ variable is used to calculate skip and limit query variables.
  #
  # == +page+ starts from one...
  #
  # If there are seven documents on the *example* db and the +limit+ query option is set to three, 
  # then to get the all documents, the uri will be generated in the following manner;
  #
  #   /example/_all_docs?limit=3&skip=0  => {..,"rows":[{"_id":..},{"_id":..},{"_id":..}]}
  #   /example/_all_docs?limit=3&skip=3  => {..,"rows":[{"_id":..},{"_id":..},{"_id":..}]}
  #   /example/_all_docs?limit=3&skip=6  => {..,"rows":[{"_id":..}]}
  #
  # Corresponding code is the following;
  #
  #   view = YALTools::YaAllDocs.new(@couch, "example")
  #   q_opts = { "include_docs" => "true" } ## or some query options
  #   view.each(q_opts, 0, 3) do |resset, skip, page, max_page, max_rows|
  #      resset.each do |row|
  #        ...
  #      end
  #   end
  # 
  # The number of +page+ starts from one and the +max_page+ variable will be set to three.
  #
  # Please refer the unittest/ut.yalt.yaview.rb file about available query options.
  # == Note
  #
  # YALTools::YaDocs is an abstract class. 
  #
  # Please use YALTools::YaViewDocs and YALTools::YaAllDocs classes for acutual use.
  #

  class YaDocs

    attr_accessor :debug
    
    def initialize(couch, dbname)
      @couch = couch
      @dbname = dbname
      @debug = @couch.debug if @couch.respond_to?("debug")
      
      @default_query_options = {}
    end
    
    # +options+ must be proper view query option values.
    #
    #   options = {"group" => true}
    #   max_numrows(options) #=> 30
    # 
    # === Decision Table (*:can be ommitted)
    #  reduce:
    #   _count | group | gropu_numrows | startkey/endkey/key | reduce | skip | limit |
    #  --------+-------+---------------+---------------------+--------+------+-------+
    #     yes  |   on  |       on      |          off        |  true* |  del |  del  |
    #     yes  |   on  |       on      |           on        |  true* |  del |  del  |
    #     yes  |  off  |      off      |           on        |  true  |  del |  del  |
    #     yes  |  off  |      off      |          off        | false  |  del |    0  |
    #      no  |  off  |      off      |          off        | false  |  del |    0  |
    #      no  |  off  |      off      |           on        | false  |  del |  del  |
    #
    def max_numrows(options={})
      opts = {}
      
      if options.has_key?("startkey") or options.has_key?("endkey") or options.has_key?("key")
        opts["startkey"] = options["startkey"] if options.has_key?("startkey") and not options["startkey"] == nil
        opts["endkey"] = options["endkey"] if options.has_key?("endkey") and not options["endkey"] == nil
        opts["key"] = options["key"] if options.has_key?("key") and not options["key"] == nil
      else
        opts["reduce"] = "false"
        opts["limit"] = "0"
      end
      if options.has_key?("group") and options["group"].to_s == "true"
        opts["group"] = "true"
        opts["group_numrows"] = "true"

        opts.delete("reduce")
        opts.delete("limit")
      end
      opts.delete("include_docs")
      
      uri = gen_view_uri(opts)
      $stderr.puts "[debug] max_numrows() uri=#{uri}" if @debug
      
      return total_numrows(@couch.get(uri), opts)
    end
    
    # yields [rows, page, next_page_flag]
    # 
    # [+rows+] an instance of YALTools::YaJsonRows.
    # [+page+] the number of the current page.
    # [+next_page+] true if next page exists.
    #
    def get_all(query_options={}, current_page=1, limit=15) # :yields: rows,page,next_page_flag
      opts = @default_query_options.merge(query_options)
      page = current_page.to_i
      page = 1 if page < 1
      while true
        opts["skip"] = limit * (page - 1)
        opts["limit"] = limit + 1
        uri = gen_view_uri(opts)
        $stderr.puts "[debug] get_all() uri=#{uri}" if @debug
        
        rows = YALTools::YaJsonRows.new(@couch, @dbname)
        json = @couch.get(uri)
        i=0
        next_row = nil
        next_page_flag = false
        json.has_key?("rows") and yield_rows(json["rows"]) do |r|
          if i == limit
            next_page_flag = true
          else
            rows << r
          end
          i += 1
        end
        break if rows.length == 0
        yield [rows, page, next_page_flag]
        break if next_page_flag == false
        page += 1
      end
    end
    
    # yields [rows, skip, page, max_page, max_rows]. 
    #
    # The +query_options+ must be proper view query options, 
    #
    def each(query_options={}, start_page=0, limit=15) # :yields: rows, skip, page, max_page, max_rows
      pages(@default_query_options.merge(query_options), start_page, limit, true) do |rows, skip, page, max_page ,max_rows|
        yield [rows, skip, page, max_page ,max_rows]
      end
    end

    # yields [rows, skip, page, max_page, max_rows] with attachment documents. 
    # It might be too slow.
    #
    # The +query_options+ must be proper view query options, 
    #
    def each_with_attachments(query_options={}, start_page=0, limit=15) # :yields: rows, skip, page, max_page, max_rows
      pages(@default_query_options.merge(query_options), start_page, limit, true, true) do |rows, skip, page, max_page ,max_rows|
        yield [rows, skip, page, max_page ,max_rows]
      end
    end
    
    # returns [rows, skip, page, max_page, max_rows]. 
    # It is same as the yielded variables at YaDocs::each.
    # 
    # It returns just a result specified by the page variable.
    #
    def page(query_options={}, page_num=0, limit=15)
      return pages(@default_query_options.merge(query_options), page_num, limit, false)
    end
    
    private

    #
    # returns or yield YALTools::YaJsonRows instance and some informational variables.
    # 
    def pages(options={}, page=0, limit=15, do_iterate=false, with_attachments=false)
      $stderr.puts "[debug] pages(options=#{options}, page=#{page}, limit=#{limit}, do_iterate=#{do_iterate})"  if @debug
      opts = options.dup
      max_rows = max_numrows(opts)
      $stderr.puts "[debug] pages() max_rows=#{max_rows}" if @debug
      
      opts["limit"] = limit
      if options.has_key?("group") and options["group"].to_s == "true"
        opts.delete("reduce")
        opts.delete("include_docs")
      else
        opts.delete("group")
        opts["reduce"] = "false"
      end
      
      ## yield_skip_page(limit, max_rows, page) do |skip, current_page, max_page|
      yield_skip_page_r(limit, max_rows, page, opts) do |i_limit, skip, current_page, max_page, new_opts|
        new_opts["skip"] = skip
        new_opts["limit"] = i_limit
        uri = gen_view_uri(new_opts)
        $stderr.puts "[debug] pages() uri=#{uri}" if @debug
        
        resset = YALTools::YaJsonRows.new(@couch, @dbname)
        json = @couch.get(uri)
        json.has_key?("rows") and yield_rows(json["rows"]) do |doc|
          if with_attachments and doc.has_key?("_attachments")
            resset << get_page_with_attachment(doc)  
          else
            resset << doc
          end
        end
        if do_iterate
          yield [resset.reverse, skip, (max_page - current_page + 1), max_page ,max_rows]
        else
          return [resset.reverse, skip, (max_page - current_page + 1), max_page ,max_rows]
        end
      end
    end
    
    # returns Hash object of the given document
    #
    # [+doc+] doc == { "_id"=>"xxx", "key1"=>"val1", "key2"=>"val2" }
    def get_page_with_attachment(doc)
      $stderr.puts "[debug] get_page_with_attachment(doc=#{doc})" if @debug
      id = doc["_id"] if doc.has_key?("_id")
      uri = "/#{@dbname}/#{id}?attachments=true"
      $stderr.puts "[debug] get_page_with_attachment() uri=#{uri}" if @debug
      return @couch.get(uri)
    end
    
    # returns uri string, such as "/example/_design/all/_view/type?reduce=false&include_docs=true"
    def gen_view_uri(opts={})
      uri = format("/%s/_all_docs", @dbname)
      
      msg = { "uri" => uri } and $stderr.puts msg.to_json if @debug
      
      return gen_uri_with_options(uri, opts)
    end
    
    # returns the total number of results.
    #
    #   total_numrows(json) #=> 30
    #
    # It accepts the following +json+ data format;
    #
    # * {"total_rows":11,"offset":0,"rows":[]}
    # * {"rows":[{"key":null,"value":10}]}
    # * {"group_numrows":"1"} 
    #   * {"rows":[{"key":"a","value":1},{},..{}]} (if group_numrows is not implemented)
    #
    # The "group_numrows" is special case. Please see [https://github.com/YasuhiroABE/CouchDB-Group_NumRows].
    # 
    def total_numrows(json, opts={})
      $stderr.puts "total_numrows(json=#{json}, opts=#{opts})" if @debug
      ret = 0
      if json.kind_of?(Hash)
        if json.has_key?("total_rows")
          ret = json["total_rows"].to_i
          if json.has_key?("rows") and json["rows"].kind_of?(Array)
            i = json["rows"].length 
            ret = i if i > 0
          end
        elsif json.has_key?("rows") and json["rows"][0].kind_of?(Hash) and json["rows"][0].has_key?("value")
          if json["rows"].size == 1 and json["rows"][0].has_key?("key") and json["rows"][0]["key"] == nil
            ret = json["rows"][0]["value"].to_i
          elsif opts.has_key?("group_numrows") and opts["group_numrows"].to_s == "true"
            ## if group_numrows is not implemented.
            ret = json["rows"].size
          end
        elsif json.has_key?("group_numrows")
          ret = json["group_numrows"].to_i
        end
      end

      $stderr.puts "[debug] total_numrows=#{ret}" if @debug
      return ret
    end
    
    # returns the uri from +baseuri+ and +opts+.
    #
    #   gen_uri_with_options("/foo/path", {"k"=>"v","k2"=>"v2"}) #=> "/foo/path?k=v&k2=v2"
    #
    def gen_uri_with_options(baseuri, opts)
      uri = baseuri
      uri += "?" if uri !~ /\?$|\&$/
      tmp_list = []
      opts.kind_of?(Hash) and opts.each do |k,v|
        next if v == nil or (v.respond_to?("empty?") and v.empty?)
        tmp_list << "#{k}=#{v}"
      end
      uri += tmp_list.join("&")
      return uri
    end

    # iterates skip and page parameters for a view query.
    #
    # The +max_page+ will be calculated in the following way.
    #
    #     +------------+-------+------------------+----------+
    #     | total_rows | limit | total_rows/limit | max_page |
    #     +------------+-------+------------------+----------+
    #     |     10     |   4   |        2         |    3     | 
    #     +------------+-------+------------------+----------+
    #     |     10     |   5   |        2         |    2     |
    #     +------------+-------+------------------+----------+
    #     |     10     |   6   |        1         |    2     |
    #     +------------+-------+------------------+----------+
    #
    # Now, this method is obsolete.
    #
    def yield_skip_page(limit, total_rows, start_page=1) # :yields: skip, page, max_page
      max_page = (total_rows.to_f / limit.to_f).ceil
      
      page = start_page <= max_page ? start_page : max_page
      page = 1 if page < 1 ## 'page' must be greater than one, even though max_page is zero.
      skip = limit * (page - 1)
      
      while page <= max_page
        yield [skip,page,max_page]
        skip = limit * page
        page += 1
      end
    end

    #
    # +yield_skip_page_r+ is a reverse version of the +yield_skip_page+.
    #
    # +start_page+ is from one to +max_page+, less than one will be rounded to one.
    #
    def yield_skip_page_r(unit, total_rows, start_page=1, query_opts) # :yields: limit, skip, page, max_page, new_query_opts
      opts = query_opts.dup
      limit = unit

      # swaping +startkey+, +endkey+ and "descending" options.
      case "#{opts.has_key?('startkey')}.#{opts.has_key?('endkey')}"
      when "true.true"
        opts["startkey"] = query_opts["endkey"]
        opts["endkey"] = query_opts["startkey"]
      when "true.false"
        opts["endkey"] = opts["startkey"]
        opts.delete("startkey")
      when "false.true"
        opts["startkey"] = opts["endkey"]
        opts.delete("endkey")
      end
      if opts.has_key?("descending")
        opts["descending"] = (opts["descending"].to_s == "true") ? "false" : "true"
      else
        opts["descending"] = "true"
      end
      
      max_page = (total_rows.to_f / limit.to_f).ceil
      
      sanitized_start_page = start_page > 0 ? start_page : 1
      page = (max_page - sanitized_start_page + 1)
      page = 1 if page < 1 ## 'page' must be greater than one, even though max_page is zero.
      skip = total_rows - (limit * (max_page - page + 1))
      skip = total_rows if skip > total_rows
      skip = 0 if skip < 0
      
      $stderr.puts "[debug] yield_skip_page_r() sanitized_start_page=#{sanitized_start_page},skip=#{skip},page=#{page}" if @debug
      
      while page >= 1
        $stderr.puts "[debug] yield_skip_page_r() skip=#{skip},page=#{page},max_page=#{max_page}" if @debug
        if skip == 0
          tmp_limit = total_rows % limit
          tmp_limit = limit if tmp_limit == 0
          yield [tmp_limit ,skip,page,max_page,opts]
        else
          yield [limit ,skip,page,max_page,opts]
        end
        page -= 1
        # skip = limit * (page - 1)
        skip -= limit
        skip = 0 if skip < 0
      end
    end
    
    # iterates each row of the +rows+ array.
    #
    def yield_rows(rows) # :yields: row
      rows.respond_to?(:each) and rows.each do |row|
        if row.has_key?("doc") and row["doc"].kind_of?(Hash)
          ## if include_docs=true
          yield row["doc"]
        else
          yield row
        end
      end
    end
  end
  
  # == Description
  # 
  # YALTools::YaViewDocs is designed to handle huge amount of documents using View API.
  #
  # == Restrictions
  # To improve performance, the view definition should include the "_count" reduce 
  # function or "_sum" function with emit(x, 1).
  #
  #   {
  #     "xxx": {
  #        "map": "xxxx",
  #        "reduce": "_count"
  #     }
  #   }
  #      or
  #   {
  #     "xxx": {
  #        "map": "... emit(xxx, 1); ...",
  #        "reduce": "_sum"
  #     }
  #   }
  # 
  # Otherwise, the max_numrows method cannot return the correct value.
  # So, the pagination cannot work well.
  # 
  # In this case, please use the YALTools::YaDocs::get_all(options, limit) method instead.
  # 
  # Please refer the unittest script, unittest/ut.yalt.yaview.rb.
  # 
  # == Usage
  # 
  #    view = YALTools::YaViewDocs.new(@couch, @dbname, @designname, @viewname)
  #    view.each(opts, @opts[:page], @opts[:unit]) do |rows, skip, page, max_page, max_rows|
  #      rows.each do |i|  ## rows is an instance of YaJsonRows
  #        puts i.to_json
  #      end
  #    end
  # 
  class YaViewDocs < YaDocs
    def initialize(couch, dbname, design_name, view_name)
      @couch = couch
      @dbname = dbname
      @debug = @couch.debug if @couch.respond_to?("debug")
      
      @design_name = design_name
      @view_name = view_name
      
      @default_query_options = { "reduce" => "false", "descending" => "false", "include_docs" => "true" }
    end
    
    private
    def gen_view_uri(opts={})
      uri = format("/%s/_design/%s/_view/%s", @dbname, @design_name, @view_name)
      return gen_uri_with_options(uri, opts)
    end
  end

  # == Description
  #
  # YALTools::YaAllDocs is designed to handle huge amount of documents using the BulkDoc (_all_docs) API.
  #
  # == Usage
  #
  #     view = YALTools::YaAllDocs.new(@couch, @dbname)
  #     view.each(opts, @opts[:page], @opts[:limit]) do |rows, skip, page, max_page, max_rows|
  #       rows.each do |i|
  #        YALTools::CmdLine::save_data(i.to_json, @opts[:outfile], "w")
  #       end
  #     end
  #
  class YaAllDocs < YaDocs
    
    private
    def gen_view_uri(opts={})
      uri = format("/%s/_all_docs", @dbname)
      return gen_uri_with_options(uri, opts)
    end
  end
end
