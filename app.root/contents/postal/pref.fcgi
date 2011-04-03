#!/usr/bin/env /usr/local/bin/ruby
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
require 'fcgi'
require 'json'
require 'yaml'
require 'yapostal'
require 'yalt'
## 
## Main loop
##

def check_kana?(word)
  return true if word =~ /^[ァ-ヶ0-9A-z・ー、.()<>-]+$/
  return false
end

# @responder = YaPostal::FlexBoxResponder.new("city")
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
  
  total_len = 0
  json = {"results" => [], "total" => "0"}

  view = nil
  opts = {}
  opts["group"] = "true"
  
  if check_kana?(@query['q'][0])
    view = YALTools::YaViewDocs.new(@couch, @dbname, "all", "pref_kana")
  else
    view = YALTools::YaViewDocs.new(@couch, @dbname, "all", "pref")
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
  
  ## terminate process
  out.print json.to_json + "\n"
  request.finish
}
##
## fin. 
##
