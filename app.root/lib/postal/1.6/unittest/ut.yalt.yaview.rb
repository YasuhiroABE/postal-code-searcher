#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'test/unit'

class YALToolsYaViewTest < Test::Unit::TestCase

  require 'digest/sha2'

  $:.unshift File::join([File::dirname($0), "..","lib"])
  require 'yalt'

  def setup
    ## misc variables
    @basedir = File::dirname($0)
    @basename_prefix = File::basename($0, ".rb")
    @inc_dir = File::join([@basedir, "#{@basename_prefix}.files"])  ## basedir to an include directory
    ## for reading/writing usage
    @tmp_file = File::join([@inc_dir, "_tmp.json"])
    if FileTest::exist?(@tmp_file)
      File::unlink(@tmp_file)
    end
    
    ##
    ## please rewrite follongs
    ## * @dbname
    ## * couch_conf
    ## * couch_label
    ##
    @dbname = "unitdb"
    couch_conf = File::join([@basedir,"..","utils","conf","yalt.athlon.yaml"])
    couch_label = "default.user"
    @couch = YALTools::CmdLine::getCouch(couch_conf, couch_label, false)

    @couch.delete("/#{@dbname}")
    @couch.put("/#{@dbname}",{})
    data_list = YALTools::YaJsonRows.new(@couch, @dbname)
    open(File::join([@inc_dir,"group"])) do |f|
      json = {}
      id = nil
      f.each_line do |line|
        row = line.split(":")
        id = Digest::SHA2::hexdigest(line)
        json["_id"] = id
        json["name"] = row[0]
        json["gid"] = row[2].to_i
        @couch.put("/#{@dbname}/#{id}", json)
      end
    end
    ## @dbname contains the following document
    ## {
    ##    "_id"  : "...",
    ##    "_rev" : "..",
    ##    "gid"  : 6,
    ##    "name" : "disk"
    ## }

    ## define views.
    ## * /@dbname/_design/unittest/_views/gid
    ## * /@dbname/_design/unittest/_views/name
    json = {}
    json["views"] = { "gid" => { "map" => "" }, "name" => { "map" => "" }}
    json["views"]["gid"]["map"] = <<-EOF
function (doc) {
  if(doc.name) {
    emit(doc.gid, 1);
  }
}
EOF
    json["views"]["gid"]["reduce"] = "_count"
    json["views"]["name"]["map"] = <<-EOF
function (doc) {
  if(doc.name) {
    emit(doc.name, 1);
  }
}
EOF
    res = @couch.put("/#{@dbname}/_design/unittest", json)
  end
  
  def test_name_view_get_all
    view = YALTools::YaViewDocs.new(@couch, @dbname, "unittest", "name")
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    counter = 1
    view.get_all({},0,11) do |result_set, page, next_page_flag|
      assert_equal(counter, page)

      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i

        doc_counter += 1
      end
      counter += 1
    end
    assert_equal(90, view.max_numrows({}))
    assert_equal(doc_counter, view.max_numrows({}))
    assert_equal("adm", first_doc["name"])
    assert_equal("yasu", last_doc["name"])
  end

  def test_name_view
    view = YALTools::YaViewDocs.new(@couch, @dbname, "unittest", "name")
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    page_counter = 1
    opts = {}
    view.each(opts,0,11) do |result_set, skip, page, max_page, max_rows|
      assert_equal(page_counter, page)
      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i
        
        doc_counter += 1
      end
      page_counter += 1
    end
    assert_equal(90, view.max_numrows(opts))
    assert_equal(doc_counter, view.max_numrows(opts))
    assert_equal("adm", first_doc["name"])
    assert_equal("yasu", last_doc["name"])
    
    # test_name_view_reverse
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    page_counter = 1
    opts = {}
    opts["descending"] = "true"
    view.each(opts,0,11) do |result_set, skip, page, max_page, max_rows|
      # puts "[debug] page=#{page},rows.len=#{result_set.length}"
      assert_equal(page_counter, page)
      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i
        
        doc_counter += 1
      end
      page_counter += 1
    end
    assert_equal(90, view.max_numrows(opts))
    assert_equal(doc_counter, view.max_numrows(opts))
    assert_equal("adm", last_doc["name"])
    assert_equal("yasu", first_doc["name"])

    # test_name_view_start_end_keys
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    opts = {}
    opts["startkey"] = '"b"'
    opts["endkey"] = '"f"'
    view.each(opts,0,11) do |result_set, skip, page, max_page, max_rows|
      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i

        doc_counter += 1
      end
    end
    
    assert_equal(14, view.max_numrows(opts))
    assert_equal(doc_counter, view.max_numrows(opts))
    assert_equal("backup", first_doc["name"])
    assert_equal("disk", last_doc["name"])

    # test_name_view_startkey
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    opts = {}
    opts["startkey"] = '"b"'
    view.each(opts,0,11) do |result_set, skip, page, max_page, max_rows|
      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i
        
        doc_counter += 1
      end
    end
    
    assert_equal(84, view.max_numrows(opts))
    assert_equal(doc_counter, view.max_numrows(opts))
    assert_equal("backup", first_doc["name"])
    assert_equal("yasu", last_doc["name"])

    # test_name_view_endkey
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    opts = {}
    opts["endkey"] = '"f"'
    view.each(opts,0,11) do |result_set, skip, page, max_page, max_rows|
      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i
        
        doc_counter += 1
      end
    end
    
    assert_equal(20, view.max_numrows(opts))
    assert_equal(doc_counter, view.max_numrows(opts))
    assert_equal("adm", first_doc["name"])
    assert_equal("disk", last_doc["name"])
  end
  
  ##
  ## for gid views
  ##
  def test_gid_view
    view = YALTools::YaViewDocs.new(@couch, @dbname, "unittest", "gid")
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    opts = {}
    view.each(opts,0,11) do |result_set, skip, page, max_page, max_rows|
      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i
        
        doc_counter += 1
      end
    end
    assert_equal(90, view.max_numrows(opts))
    assert_equal(doc_counter, view.max_numrows(opts))
    assert_equal(0, first_doc["gid"])
    assert_equal(65534, last_doc["gid"])

    # test_gid_reverse
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    opts = {"descending" => "true"}
    view.each(opts,0,11) do |result_set, skip, page, max_page, max_rows|
      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i
        
        doc_counter += 1
      end
    end
    assert_equal(90, view.max_numrows(opts))
    assert_equal(doc_counter, view.max_numrows(opts))
    assert_equal(0, last_doc["gid"])
    assert_equal(65534, first_doc["gid"])

    # test_gid_start_end_keys
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    opts = {}
    opts["startkey"] = 10
    opts["endkey"] = 20
    view.each(opts,0,11) do |result_set, skip, page, max_page, max_rows|
      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i
        
        doc_counter += 1
      end
    end
    assert_equal(5, view.max_numrows(opts))
    assert_equal(doc_counter, view.max_numrows(opts))
    assert_equal(10, first_doc["gid"])
    assert_equal(20, last_doc["gid"])

    # test_gid_startkey
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    opts = {}
    opts["startkey"] = 10
    view.each(opts,0,11) do |result_set, skip, page, max_page, max_rows|
      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i
        
        doc_counter += 1
      end
    end
    assert_equal(80, view.max_numrows(opts))
    assert_equal(doc_counter, view.max_numrows(opts))
    assert_equal(10, first_doc["gid"])
    assert_equal(65534, last_doc["gid"])

    # test_gid_endkey
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    opts = {}
    opts["endkey"] = 20
    view.each(opts,0,11) do |result_set, skip, page, max_page, max_rows|
      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i
        
        doc_counter += 1
      end
    end
    assert_equal(15, view.max_numrows(opts))
    assert_equal(doc_counter, view.max_numrows(opts))
    assert_equal(0, first_doc["gid"])
    assert_equal(20, last_doc["gid"])

    # test_name_group
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    opts = {}
    opts["group"] = "true"
    view.each(opts,0,11) do |result_set, skip, page, max_page, max_rows|
      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i
        
        doc_counter += 1
      end
    end
    assert_equal(90, view.max_numrows(opts))
    assert_equal(doc_counter, view.max_numrows(opts))
    assert_equal(0, first_doc["key"])
    assert_equal(65534, last_doc["key"])

    # test_name_group_start_end_keys
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    opts = {}
    opts["group"] = "true"
    opts["startkey"] = 10
    opts["endkey"] = 20
    view.each(opts,0,11) do |result_set, skip, page, max_page, max_rows|
      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i
        
        doc_counter += 1
      end
    end
    assert_equal(5, view.max_numrows(opts))
    assert_equal(doc_counter, view.max_numrows(opts))
    assert_equal(10, first_doc["key"])
    assert_equal(20, last_doc["key"])

    # test_gid_group_startkey
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    opts = {}
    opts["group"] = "true"
    opts["startkey"] = 10
    view.each(opts,0,11) do |result_set, skip, page, max_page, max_rows|
      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i
        
        doc_counter += 1
      end
    end
    assert_equal(80, view.max_numrows(opts))
    assert_equal(doc_counter, view.max_numrows(opts))
    assert_equal(10, first_doc["key"])
    assert_equal(65534, last_doc["key"])
    
    # test_gid_group_endkey
    first_doc = nil
    last_doc = nil
    doc_counter = 0
    opts = {}
    opts["group"] = "true"
    opts["endkey"] = 20
    view.each(opts,0,11) do |result_set, skip, page, max_page, max_rows|
      result_set.each do |i|
        first_doc = i if first_doc == nil
        last_doc = i
        
        doc_counter += 1
      end
    end
    assert_equal(15, view.max_numrows(opts))
    assert_equal(doc_counter, view.max_numrows(opts))
    assert_equal(0, first_doc["key"])
    assert_equal(20, last_doc["key"])
  end
end
