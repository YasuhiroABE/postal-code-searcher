# -*- coding: utf-8 -*-

module YaPostal

  # YaPostal::Render is an view abstract class of the MVC2 model.
  #
  # Render provides some instance variables for ERB.
  # * @view - an instance of YALTools::YaDocs
  # * @options - options for the view 
  # * @query - sanitized http query parameters (see YaPostal::Controller#check_queries)
  # * @env - env of http query parameters (not sanitized)

  class Render
    include GetText
    # [+datadir+] base dir of templates and po files. (e.x. /#{datadir}/po, /#{datadir}/templates)
    # [+view+] an instance of YALTools::YaDocs.
    # [+opts+] query options for the +view+.
    # [+req_query+] sanitized query parameters of the @env['QUERY_STRING'].
    # [+env+] is @env of the YaPostal::Controller.
    def initialize(datadir, view, opts, req_query, env)
      @datadir = datadir
      @view = view
      @options = opts
      @query = req_query.clone
      @env = env

      @stime = @env["stime"]

      Locale::clear
      Locale::set_request([],[], @env["HTTP_ACCEPT_LANGUAGE"], @env["HTTP_ACCEPT_CHARSET"])
      GetText::set_output_charset("UTF-8")
      GetText::bindtextdomain("postal", "/app/data/postal/1.6/data/locale")
    end
    
    def render
      ret = ""
      return ret
    end
    
    def gen_uri(opts)
      ret = @env.has_key?("SCRIPT_NAME") ? @env["SCRIPT_NAME"] : ""
      tmp_q = []
      opts.each do |k,v|
        next if v.to_s.empty?
        tmp_q << "#{k}=#{CGI.escape(v.to_s)}"
      end
      ret += "?"
      ret += tmp_q.join("&amp;")
      
      return ret
    end
  end

  class SearchRender < Render
    def render
      ret = ""
      header_file = File::join([@datadir,"templates","header.erb"])
      body_file = File::join([@datadir,"templates","search.erb"])
      footer_file = File::join([@datadir,"templates","footer.erb"])
      
      ## context
      tmp_q = @query.clone
      tmp_q["mode"] = "search_json"
      json_query = gen_uri(tmp_q)
      
      ret += ERB.new(open(header_file,"r:utf-8").read).result(binding)
      ret += ERB.new(open(body_file,"r:utf-8").read).result(binding)
      ret += ERB.new(open(footer_file,"r:utf-8").read).result(binding)
      return ret
    end
  end
end
