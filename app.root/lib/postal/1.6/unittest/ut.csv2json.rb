#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'test/unit'

class YaCsv2JsonTest < Test::Unit::TestCase
  $:.unshift File::join([File::dirname($0), "..","utils","bin"])
  load 'csv2json'

  include YaCsv2Json

  def test_parse_csv_line_simple
    res = {}
    titles = ["name","age"]
    values = ["yasu",30]
    parse_csv_line(titles.dup, values, res)
    assert_equal("yasu", res["name"])
    assert_equal(30, res["age"])
  end

  def test_parse_csv_line_map_reduce
    res = {}
    titles = ["_id","language","views","all","map","views","all","reduce"]
    values = ["_design/all","javascript",nil,nil,"function(doc){}",nil,nil,"_count"]
    parse_csv_line(titles.dup, values, res)
    assert_equal("javascript",res["language"])
    assert_equal("function(doc){}",res["views"]["all"]["map"])
    assert_equal("_count",res["views"]["all"]["reduce"])
  end

  def test_parse_csv_line_security_roles
    res = {}
    titles = ["admins","names","admins","roles","readers","names","readers","roles"]
    values = [nil,"user1",nil,"dbadmin",nil,"",nil,"dbreader"]
    parse_csv_line(titles.dup, values, res)
    values = [nil,"user1",nil,"dbwriter",nil,"",nil,"dbreader"]
    parse_csv_line(titles.dup, values, res)
    
    assert_equal(["user1"],              res["admins"]["names"])
    assert_equal(["dbadmin","dbwriter"], res["admins"]["roles"])
    assert_equal([""],                   res["readers"]["names"])
    assert_equal(["dbreader"],           res["readers"]["roles"])
  end
end

