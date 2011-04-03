#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
##
##
app_uri = "postal"
Rev = "1.6"
@basedir = "/app/lib/#{app_uri}/#{Rev}"
@confdir = "/app/data/#{app_uri}/#{Rev}"
$:.unshift File::join([@basedir,"lib"])
ENV['GEM_HOME'] = File::join([@basedir,"gems"])

require 'rubygems'
require 'json'
require 'yaml'
require 'fcgi'
require 'yapostal'
require 'yalt'
## 
## Main loop
##

def check_kana?(word)
  return true if word =~ /^[ァ-ヶ0-9A-z・ー、.()<>-]+$/
  return false
end

@conf = YAML::load_file(File::join([@confdir,"yapostal.yaml"]))
@dbname = @conf["database"]
main_conf = File::join([@confdir, "yalt.yaml"])
main_label = @conf["label_name"]
wrapper = YALTools::MainWrapper.new(main_conf, main_label)
@couch = wrapper.getCouch

FCGI.each { |request|
  ## begin main process
  out = request.out
  out.print "Content-type: application/json; charset=utf-8\r\n\r\n"
  
  @query = CGI::parse(request.env['QUERY_STRING'])
  
  json = {"results" => [], "total" => "0"}
  
  view = nil
  opts = {}
  opts["group"] = "true"
  if @query.has_key?('k') and @query['k'].kind_of?(Array) and not @query['k'][0].empty?
    if @query.has_key?('j') and @query['j'].kind_of?(Array) and not @query['j'][0].empty?
      if check_kana?(@query['j'][0])
        view = YALTools::YaViewDocs.new(@couch, @dbname, "all", "pref_kana_city_kana_street_kana")
      else
        view = YALTools::YaViewDocs.new(@couch, @dbname, "all", "pref_city_street")
      end
      opts["startkey"] = format('["%s","%s","%s"]',@query['k'][0], @query['j'][0], @query['q'][0])
      opts["endkey"] = format('["%s","%s","%s\ufff0"]',@query['k'][0], @query['j'][0], @query['q'][0])
      rows, skip, page, max_page, max_rows = view.page(opts, @query['p'][0].to_i, @query['s'][0].to_i)
      json["total"] = max_rows
      
      rows.each do |item|
        tmp = {}
        item.each do |k,v|
          tmp["name"] = v[2].to_s if k == "key"
          tmp["id"] = v.to_i   if k == "value"
        end
        json["results"] << tmp
      end
    else
      e = format("%s,%s", check_kana?(@query['k'][0]), check_kana?(@query['q'][0]))
      case e
      when "true,true"
        view = YALTools::YaViewDocs.new(@couch, @dbname, "all", "pref_kana_street_kana")
      when "true,false"
        view = YALTools::YaViewDocs.new(@couch, @dbname, "all", "pref_kana_street")
      when "false,true"
        view = YALTools::YaViewDocs.new(@couch, @dbname, "all", "pref_street_kana")
      when "false,false"
        view = YALTools::YaViewDocs.new(@couch, @dbname, "all", "pref_street")
      end
      opts["startkey"] = format('["%s","%s"]',@query['k'][0], @query['q'][0])
      opts["endkey"] = format('["%s","%s\ufff0"]',@query['k'][0], @query['q'][0])
      rows, skip, page, max_page, max_rows = view.page(opts, @query['p'][0].to_i, @query['s'][0].to_i)
      json["total"] = max_rows
      
      rows.each do |item|
        tmp = {}
        item.each do |k,v|
          tmp["name"] = v[1].to_s if k == "key"
          tmp["id"] = v.to_i   if k == "value"
        end
        json["results"] << tmp
      end
    end
  else
    if @query.has_key?('j') and @query['j'].kind_of?(Array) and not @query['j'][0].empty?
      e = format("%s,%s", check_kana?(@query['j'][0]), check_kana?(@query['q'][0]))
      case e
      when "true,true"
        view = YALTools::YaViewDocs.new(@couch, @dbname, "all", "city_kana_street_kana")
      when "true,false"
        view = YALTools::YaViewDocs.new(@couch, @dbname, "all", "city_kana_street")
      when "false,true"
        view = YALTools::YaViewDocs.new(@couch, @dbname, "all", "city_street_kana")
      when "false,false"
        view = YALTools::YaViewDocs.new(@couch, @dbname, "all", "city_street")
      end
      opts["startkey"] = format('["%s","%s"]',@query['j'][0], @query['q'][0])
      opts["endkey"] = format('["%s","%s\ufff0"]',@query['j'][0], @query['q'][0])
      rows, skip, page, max_page, max_rows = view.page(opts, @query['p'][0].to_i, @query['s'][0].to_i)
      json["total"] = max_rows
      
      rows.each do |item|
        tmp = {}
        item.each do |k,v|
          tmp["name"] = v[1].to_s if k == "key"
          tmp["id"] = v.to_i   if k == "value"
        end
        json["results"] << tmp
      end
    else
      if check_kana?(@query['q'][0])
        view = YALTools::YaViewDocs.new(@couch, @dbname, "all", "street_kana")
      else
        view = YALTools::YaViewDocs.new(@couch, @dbname, "all", "street")
      end
      opts["startkey"] = format('"%s"', @query['q'][0])
      opts["endkey"] = format('"%s\ufff0"', @query['q'][0])
      rows, skip, page, max_page, max_rows = view.page(opts, @query['p'][0].to_i, @query['s'][0].to_i)
      json["total"] = max_rows

      rows.each do |item|
        tmp = {}
        item.each do |k,v|
          tmp["name"] = v.to_s if k == "key"
          tmp["id"] = v.to_i   if k == "value"
        end
        json["results"] << tmp
      end
    end
  end
  
  ## terminate process
  out.print json.to_json + "\n"
  request.finish
}
##
## fin. 
##
