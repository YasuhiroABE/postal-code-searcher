# -*- coding: utf-8 -*-

module YaPostal
  
  # YaPostal::Controller is an controller class of the MVC2 model.
  #
  # It must be created for each client's request.
  #
  # == Configuration File
  # 
  # YaPostal::Controller class assumes that there are three files under the configuration directory.
  #
  # * yalt.yaml
  # * master_pw.json
  # * yapostal.yaml
  #
  class Controller
    def initialize(confdir, request)
      @confdir = confdir
      @conf = YAML::load_file(File::join([@confdir,"yapostal.yaml"]))
      @dbname = @conf["database"]

      @request = request
      @env = request.env
      @env["stime"] = Time.now.to_f

      @query = CGI.parse(@env['QUERY_STRING'])

      main_conf = File::join([@confdir, "yalt.yaml"])
      main_label = @conf["label_name"]
      wrapper = YALTools::MainWrapper.new(main_conf, main_label)
      @couch = wrapper.getCouch

      @debug = false
      @debug = true if @conf.has_key?("debug") and @conf["debug"].to_s =~ /true/i
    end

    def run
      ret = "Content-Type: text/html; charset=UTF-8\r\n\r\n"

      q = check_queries(@query)
      $stderr.puts "run() q=" + q.to_s if @debug      
      
      case q["mode"]
      when "search"
        ret = "Content-Type: text/html; charset=UTF-8\r\n\r\n"
        view, opts = gen_search_view(q)
        
        view.debug = false
        
        r = YaPostal::SearchRender.new(@confdir, view, opts, q, @env)
        ret += r.render
      when "search_json"
        ret = "Content-Type: application/json; charset=UTF-8\r\n\r\n"
        ret_json = {}
        begin
          view, opts = gen_search_view(q)
          
          view.debug = false
          rows, skip, page, max_page, max_rows = view.page(opts,q["page"],q["unit"])
          ret_json["rows"] = rows
          ret_json["total"] = rows.size
          ret_json["reason"] = "no results" if rows.empty?
        rescue
          ret_json["reason"] = "hanging-up query"
        end

        ret_json["elapsed_time"] = format("%.3f", Time.now.to_f - @env["stime"])
        ret += ret_json.to_json
      end
      return ret
    end

    private

    # returns [view, view_query_options]
    # 
    # [+view+] an instance of YALTools::YaViewDocs
    # [+view_query_options+] Hash object for view query options.
    #
    def gen_search_view(q = {})
      designname = "all"

      view = nil
      opts = {}
      if not q["old_code_prefix"].to_s.empty?
        viewname = "old_code_prefix"
        opts["startkey"] = format('"%s"',q[viewname])
        opts["endkey"] = format('"%s\ufff0"', q[viewname])
        view = YALTools::YaViewDocs.new(@couch, @dbname, designname, viewname)
      elsif not q["code_prefix"].empty? and not q["code_suffix"].empty?
        viewname = "code"
        opts["startkey"] = format('"%s"',q[viewname])
        opts["endkey"] = format('"%s\ufff0"', q[viewname])
        view = YALTools::YaViewDocs.new(@couch, @dbname, designname, viewname)
      elsif not q["code_prefix"].empty?
        viewname = ""
        viewnames = []
        if not q["street"].empty?
          viewnames = ["code_prefix","street"]
        elsif not q["street_kana"].empty?
          viewnames = ["code_prefix","street_kana"]
        elsif not q["city"].empty?
          viewnames = ["code_prefix","city"]
        elsif not q["city_kana"].empty?
          viewnames = ["code_prefix","city_kana"]
        elsif not q["pref"].empty?
          viewnames = ["pref","code_prefix"]
        elsif not q["pref_kana"].empty?
          viewnames = ["pref_kana","code_prefix"]
        else
          viewnames = ["code_prefix"]
        end
        
        case viewnames.size
        when 2
          viewname0 = viewnames[0]
          viewname1 = viewnames[1]
          viewname = format("%s_%s", viewname0, viewname1)
          opts["startkey"] = format('["%s","%s"]',q[viewname0],q[viewname1])
          opts["endkey"] = format('["%s","%s\ufff0"]',q[viewname0],q[viewname1])
        else
          viewname = viewnames[0]
          opts["startkey"] = format('"%s"',q[viewname])
          opts["endkey"] = format('"%s\ufff0"', q[viewname])
        end
        view = YALTools::YaViewDocs.new(@couch, @dbname, designname, viewname)
      elsif not q["code_suffix"].empty?
        viewname = nil
        if not q["street"].empty?
          viewnames = ["code_suffix","street"]
        elsif not q["street_kana"].empty?
          viewnames = ["code_suffix","street_kana"]
        elsif not q["city"].empty?
          viewnames = ["code_suffix","city"]
        elsif not q["city_kana"].empty?
          viewnames = ["code_suffix","city_kana"]
        elsif not q["pref"].empty?
          viewnames = ["pref","code_suffix"]
        elsif not q["pref_kana"].empty?
          viewnames = ["pref_kana","code_suffix"]
        else
          viewnames = ["code_suffix"]
        end

        case viewnames.size
        when 2
          viewname0 = viewnames[0]
          viewname1 = viewnames[1]
          viewname = format("%s_%s", viewname0, viewname1)
          opts["startkey"] = format('["%s","%s"]',q[viewname0],q[viewname1])
          opts["endkey"] = format('["%s","%s\ufff0"]',q[viewname0],q[viewname1])
        else
          viewname = viewnames[0]
          opts["startkey"] = format('"%s"', q[viewname])
          opts["endkey"] = format('"%s\ufff0"', q[viewname])
        end
        view = YALTools::YaViewDocs.new(@couch, @dbname, designname, viewname)
      else
        viewname = ""
        viewnames = []
        case [! q["street"].empty?,
              ! q["street_kana"].empty?,
              ! q["city"].empty?,
              ! q["city_kana"].empty?,
              ! q["pref"].empty?,
              ! q["pref_kana"].empty?]
        when [false,true,false,false,false,false] ## single
          viewnames << "street_kana"
        when [false,false,false,true,false,false]
          viewnames << "city_kana"
        when [false,false,false,false,false,true]
          viewnames << "pref_kana"
        when [true,false,false,false,false,false]
          viewnames << "street"
        when [false,false,true,false,false,false]
          viewnames << "city"
        when [false,false,false,false,true,false]
          viewnames << "pref"

        when [false,false,false,true,false,true]  ## double
          viewnames = ["pref_kana","city_kana"]
        when [false,true,false,false,false,true]
          viewnames = ["pref_kana","street_kana"]
        when [false,true,false,true,false,false]
          viewnames = ["city_kana","street_kana"]

        when [false,false,true,false,true,false]
          viewnames = ["pref","city"]
        when [true,false,false,false,true,false]
          viewnames = ["pref","street"]
        when [true,false,true,false,false,false]
          viewnames = ["city","street"]

        when [false,true,true,false,false,false]
          viewnames = ["city","street_kana"]
        when [true,false,false,true,false,false]
          viewnames = ["city_kana","street"]
        when [false,false,false,true,true,false]
          viewnames = ["pref","city_kana"]
        when [false,true,false,false,true,false]
          viewnames = ["pref","street_kana"]
        when [false,false,true,false,false,true]
          viewnames = ["pref_kana","city"]
        when [true,false,false,false,false,true]
          viewnames = ["pref_kana","street"]

        when [false,true,false,true,false,true] ## triple
          viewnames = ["pref_kana","city_kana","street_kana"]
        when [true,false,true,false,true,false]
          viewnames = ["pref","city","street"]
          
        end
        case viewnames.size
        when 1
          viewname = viewnames[0]
          opts["startkey"] = format('"%s"', q[viewname])
          opts["endkey"] = format('"%s\ufff0"', q[viewname])
        when 2
          viewname0 = viewnames[0]
          viewname1 = viewnames[1]
          viewname = format("%s_%s", viewname0, viewname1)
          opts["startkey"] = format('["%s","%s"]', q[viewname0], q[viewname1])
          opts["endkey"] = format('["%s","%s\ufff0"]', q[viewname0], q[viewname1])
        when 3
          viewname0 = viewnames[0]
          viewname1 = viewnames[1]
          viewname2 = viewnames[2]
          viewname = format("%s_%s_%s", viewname0, viewname1, viewname2)
          opts["startkey"] = format('["%s","%s","%s"]', q[viewname0], q[viewname1], q[viewname2])
          opts["endkey"] = format('["%s","%s","%s\ufff0"]', q[viewname0], q[viewname1], q[viewname2])
        else
          viewname = "code"
          opts["startkey"] = '"965"'
          opts["endkey"] = '"965\ufff0"'
        end
        view = YALTools::YaViewDocs.new(@couch, @dbname, designname, viewname)
      end
      
      if view == nil
        
        view = YALTools::YaViewDocs.new(@couch, @dbname, designname, viewname)
      end
      return [view,opts]
    end
    

    # returns a Hash instance which contains the query string as key/value pairs.
    #
    # Usually +q+ value will be the result of CGI.parse(@request.env['QUERY_STRING']).
    #
    # == Available query string
    # There is a list of available query name and datatype.
    # 
    # * mode (string) - rendering mode search/search_json (defaut: search)
    # * page (int) - pointing to the page number.
    # * unit (int) - number of rows of each page.
    # * code_prefix (string:length=3) - prefix of postal code.
    # * code_suffix (string:length=4) - suffix of postal code.
    # * pref,pref_js,pref_kana (string:100) - actual max length is 6 (URI.escap().length == 54)
    # * city,city_js,city_kana (string:340) - actual max length is 19 (URI.escap().length == 171)
    # * street,street_js,street_kana (string:1000) - actual max length is 63 (URI.escap().length == 550)
    # * old_code_prefix (int)
    #
    # Following variables is constructed by the query string.
    # * code == code_prefix + code_suffix (string:length=7)
    #
    # * lang (string:10) - test purpose only for the GetText module.
    def check_queries(q = {})
      ret = {}

      label = "mode"
      ret[label] = check_queries_string(q,label,20,"search")

      label = 'page'
      ret[label] = check_queries_int(q,label,1,1)
      label = 'unit'
      ret[label] = check_queries_int(q,label,1,5)

      label = 'code_prefix'
      ret[label] = check_queries_string(q,label,3,"")
      label = 'code_suffix'
      ret[label] = check_queries_string(q,label,4,"")

      label = 'code'
      ret["code"] = (ret['code_prefix'] + ret['code_suffix'])[0,7]

      # FlexBox returns the *_js variable which overrides q[label] variable.
      label = 'pref'
      label2 = 'pref_js'
      if q.has_key?(label2)
        ret[label] = ret[label2] = check_queries_string(q, label2, 20, "")
      else
        ret[label] = check_queries_string(q, label, 20, "")
      end
      if check_kana(ret[label])
        ret[label+"_kana"] = ret[label]
        ret[label] = ""
      else
        ret[label+"_kana"] = ""
      end
      
      label = 'city'
      label2 = 'city_js'
      if q.has_key?(label2)
        ret[label] = ret[label2] = check_queries_string(q, label2, 340, "")
      else
        ret[label] = check_queries_string(q, label, 340, "")
      end
      if check_kana(ret[label])
        ret[label+"_kana"] = ret[label]
        ret[label] = ""
      else
        ret[label+"_kana"] = ""
      end
      
      label = 'street'
      label2 = 'street_js'
      if q.has_key?(label2)
        ret[label] = ret[label2] = check_queries_string(q,label2,1000,"")
      else
        ret[label] = check_queries_string(q,label,1000, "")
      end
      if check_kana(ret[label])
        ret[label+"_kana"] = ret[label]
        ret[label] = ""
      else
        ret[label+"_kana"] = ""
      end

      label = 'old_code_prefix'
      ret[label] = check_queries_int(q,label,0,0)
      ret[label] = "" if ret[label] == 0
      
      return ret
    end
    # validates a query string.
    def check_queries_int(query, label, min_value, default)
      return default if not query.has_key?(label) or not query[label].kind_of?(Array) or query[label][0] == nil
      return default if query[label][0].to_i < min_value
      return query[label][0].to_i
    end
    # validates a query string.
    def check_queries_string(query, label, size, default)
      return default if not query.has_key?(label) or not query[label].kind_of?(Array) or query[label][0] == nil
      return default if query[label][0].respond_to?("empty?") and query[label][0].empty?
      return query[label][0][0,size.to_i]
    end
    #---
    # end of check_queries
    #+++

    #
    # Utilities
    #
    
    # returns uri in xhtml format
    def convert_uri(uri)
      uri.gsub(/&amp;/,'&').gsub(/&/, '&amp;')
    end
 
    def check_kana(word)
      return true if word =~ /^[ァ-ヶ0-9A-z・ー、.()<>-]+$/
      return false
    end
  end
end
