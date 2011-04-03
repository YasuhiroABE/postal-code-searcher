#!/usr/bin/env /usr/local/bin/ruby
# -*- coding: utf-8 -*-

Rev = "1.6"
app_uri = "postal"
@basedir = "/app/lib/#{app_uri}/#{Rev}"
@confdir = "/app/data/#{app_uri}/#{Rev}"
$:.unshift File::join([@basedir,"lib"])

ENV['GEM_HOME'] = File::join([@basedir,"gems"])
require 'rubygems'
require 'fcgi'
require 'cgi'
require 'yapostal'

FCGI.each {|request|
 Thread.current[:current_request] = nil

  out = request.out
  main = YaPostal::Controller.new(@confdir, request)
  
  out.print main.run
  
  request.finish
}
