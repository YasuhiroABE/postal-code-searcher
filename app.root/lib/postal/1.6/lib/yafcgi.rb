#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'cgi'
require 'uri'
require	'json'
require 'yaml'
require 'yapostal'

module YaPostal
  class FlexBoxResponder
    # [+confdir+] path to basedir of yapostal.yaml and yalt.yaml files.
    # [+category+] one of "street" | "city" | "pref"
    def initialize(confdir, category="street")
      @confdir = confdir
      @conf = YAML::load_file(File::join([@confdir,"yapostal.yaml"]))
      @dbname = @conf["database"]
      main_conf = File::join([@confdir, "yalt.yaml"])
      main_label = @conf["label_name"]
      wrapper = YALTools::MainWrapper.new(main_conf, main_label)
      @couch = wrapper.getCouch
      
      @category = category
      @category_kana = category + '_kana'
      
      @kanji_total_len = get_total_rows(@category).freeze
      @kana_total_len = get_total_rows(@category + "_kana").freeze
    end
    def get_total_rows(category)
      uri_template = '/%s/_design/all/_view/%s?group=true&group_numrows=true'
      uri = format(uri_template, @dbname, category)
p uri
      json = @couch.get(uri)
p json
      return json['group_numrows'].to_i
    end
    ##
    ## utility methods
    ##
    def parse_query(query)
      q = CGI.parse(query)
      page = 1
      page = q['p'][0].to_i if q.has_key?('p')
      size = 1
      size = q['s'][0].to_i if q.has_key?('s')
      query = ""
      query = q['q'][0].to_s if q.has_key?('q')
      prefKey = ""
      prefKey = q['k'][0].to_s if q.has_key?('k')
      cityKey = ""
      cityKey = q['j'][0].to_s if q.has_key?('j')
      
      ## check the parsed queries
      size = 1 if size < 1
      page = 1 if page < 1
      
      return page,size,query,prefKey,cityKey
    end
    def check_kana?(word)
      return true if word =~ /^[ァ-ヶ0-9A-z・ー、.()<>-]+$/
      return false
    end

    def check_pref?(pref)
      uri_template = '/%s/_design/all/_view/pref?key="%s"&reduce=false'
      uri_template = '/%s/_design/all/_view/pref_kana?key="%s"&reduce=false' if check_kana?(pref)
      uri = format(uri_template, @dbname, pref)
      ## sample: {"rows":[ {"key":"\u30d5\u30af\u30b7\u30de\u30b1\u30f3","value":3923} ]}
      json = JSON.parse(@couch.get(URI.escape(uri)).body)
p uri
p json
      return true if json['rows'].length > 0
      return false
    end

    def check_city?(city)
      uri_template = '/%s/_design/all/_view/city?key="%s"&reduce=false'
      uri_template = '/%s/_design/all/_view/city_kana?key="%s"&reduce=false' if check_kana?(city)
      uri = format(uri_template, @dbname, city)
      ## sample: {"rows":[ {"key":"\u30d5\u30af\u30b7\u30de\u30b1\u30f3","value":3923} ]}
      json = JSON.parse(@couch.get(URI.escape(uri)).body)
p uri
p json
      return true if json['rows'].length > 0
      return false
    end
    ## 
    ## end of the utilities
    ##

    ##
    ## main methods
    ##
    def get_numrows_by_multi(category1, category2, key1, key2)
      uri_template = '/%s/_design/multi/_view/%s_%s'
      uri_template += '?group=true&startkey=["%s","%s"]&endkey=["%s","%s\ufff0"]&group_numrows=true'
      uri = format(uri_template, @dbname, category1, category2,
                   key1, key2, key1, key2)
      return JSON.parse(@couch.get(URI.escape(uri)).body)['group_numrows'].to_i
    end

    def get_rows_by_multi(category1, category2, key1, key2, limit, skip)
      uri_template = '/%s/_design/multi/_view/%s_%s'
      uri_template += '?group=true&startkey=["%s","%s"]&endkey=["%s","%s\ufff0"]&limit=%s&skip=%s'
      uri = format(uri_template, @dbname, category1, category2,
                   key1, key2, key1, key2, limit, skip)
      return JSON.parse(@couch.get(URI.escape(uri)).body)['rows']
    end

    def get_numrows2(category, city, query)
      if check_kana?(query)
        if check_kana?(city)
          category_kana = category + '_kana'
          total_len = get_numrows_by_multi(category_kana, @category_kana, city, query)
        else
          total_len = get_numrows_by_multi(category, @category_kana, city, query)
        end
      else
        if check_kana?(city)
          category_kana = category + '_kana'
          total_len = get_numrows_by_multi(category_kana, @category, city, query)
        else
          total_len = get_numrows_by_multi(category, @category, city, query)
        end
      end
    end
    
    def get_rows2(category="city", city="", query="", page = 1, size = 1)
      skip = (page - 1) * size
      res = []
      if check_kana?(query)
        if check_kana?(city)
          category_kana = category + '_kana'
          get_rows_by_multi(category_kana, @category_kana, city, query, size, skip).each do |row|
            res << {"name"=>row['key'][1]}
          end
        else
          get_rows_by_multi(category, @category_kana, city, query, size, skip).each do |row|
            res << {"name"=>row['key'][1]}
          end
        end
      else
        if check_kana?(city)
          category_kana = category + '_kana'
          get_rows_by_multi(category_kana, @category, city, query, size, skip).each do |row|
            res << {"name"=>row['key'][1]}
          end
        else
          get_rows_by_multi(category, @category, city, query, size, skip).each do |row|
            res << {"name" => row['key'][1]}
          end
        end
      end
      return res
    end

    def get_numrows_by_single(category, key)
      uri_template = '/%s/_design/all/_view/%s?group=true&startkey="%s"&endkey="%s\ufff0"&group_numrows=true'
      uri = format(uri_template, @dbname, category, key, key)
      json = @couch.get(uri)
p uri
p json
      return json['group_numrows'].to_i
    end

    def get_rows_by_single(category, key, limit, skip)
      uri_template = '/%s/_design/all/_view/%s?group=true&startkey="%s"&endkey="%s\ufff0"&limit=%s&skip=%s'
      uri = format(uri_template, @dbname, category, key, key, limit, skip)
      json = @couch.get(uri)
p uri
p json
      return json['rows']
    end

    def get_numrows(query)
      if check_kana?(query)
        if query == ""
          return @kana_total_len
        else
          return get_numrows_by_single(@category_kana, query)
        end
      else
        if query == ""
          return @kanji_total_len
        else
          return get_numrows_by_single(@category, query)
        end
      end
    end

    def get_rows(query="", page = 1, size = 1)
      skip = (page - 1) * size
      res = []
      if check_kana?(query)
        get_rows_by_single(@category_kana, query, size, skip).each do |row|
          res << {"name"=>row['key']}
        end
      else
        get_rows_by_single(@category, query, size, skip).each do |row|
          res << {"name"=>row['key']}
        end
      end
      return res
    end
  end
end
