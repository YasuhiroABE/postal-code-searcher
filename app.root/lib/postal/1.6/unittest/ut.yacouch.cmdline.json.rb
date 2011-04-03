#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'test/unit'

class YALToolsCmdLineGrepTest < Test::Unit::TestCase

  require 'json'
  $:.unshift File::join([File::dirname($0), "..","lib"])
  require 'yalt'
  include YALTools::ProcJson
  
  def setup
    @basedir = File::dirname($0)
    @basename_prefix = File::basename($0, ".rb")
    @inc_dir = File::join([@basedir, "#{@basename_prefix}.files"])  ## basedir to an include directory

    ## flag[0] => :regexp_flag
    ## flag[1] => :invert_flag
    ## flag[2] => :ignore_case_flag
    ## flag[3] => :string_match_flag
    @possible_flags = [true,false].repeated_permutation(2).to_a
    
    @flags =        [false,false]
    @flags_regexp = [true,false]
    @flags_case =   [false,true]

    ## for reading/writing usage
    @tmp_file = File::join([@inc_dir, "_tmp.json"])
    if FileTest::exist?(@tmp_file)
      File::unlink(@tmp_file)
    end
  end

  def test_grep_json_0
    [[{"k"=>"v"},[["v"]]],[{"k"=>"v"},[["k","v","v"]]]].each do |json,kv_list|
      assert_false(grep_json(json, kv_list, false, false))
      assert_false(grep_json(json, kv_list, true, false))
      assert_false(grep_json(json, kv_list, false, true))
      assert_false(grep_json(json, kv_list, true,true))
    end
  end
  def test_grep_json_1
    [["k",[["k"]]],[{"k"=>"v"},[["k"]]], [{"k"=>"v"},[["k","v"]]]].each do |json,kv_list|
      assert(grep_json(json, kv_list, false, false))
      assert(grep_json(json, kv_list, true, false))
      assert(grep_json(json, kv_list, false, true))
      assert(grep_json(json, kv_list, true, true))
    end
  end
  def test_grep_json_2
    [[{"key"=>"value"},[["kEy"]]],[{"k"=>"v"},[["K"]]], [{"k"=>"v"},[["K","v"]]],[{"k"=>"v"},[["k","V"]]]].each do |json,kv_list|
      assert_false(grep_json(json, kv_list, false, false))
      assert_false(grep_json(json, kv_list, true, false))
      assert(grep_json(json, kv_list, false, true))
      assert(grep_json(json, kv_list, true, true))
    end
  end
  def test_grep_json_3
    [[{"key"=>"value"},[["Y$"]]]].each do |json,kv_list|
      assert_false(grep_json(json, kv_list, false, false))
      assert_false(grep_json(json, kv_list, true, false))
      assert_false(grep_json(json, kv_list, false, true))
      assert(grep_json(json, kv_list, true, true))
    end
  end
  
  def test_select_value_from_json
    json = {"_id"=>"x","_rev"=>"y","name"=>"z"}
    label = ["_id","name"]
    
    ret = select_value_from_json(json,label)
    assert_equal({"_id"=>"x","name"=>"z"}, ret)
    
    ret = exclude_value_from_json(json, label)
    assert_equal({"_rev"=>"y"}, ret)
  end
  
end
