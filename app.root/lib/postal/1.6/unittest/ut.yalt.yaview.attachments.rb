#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'test/unit'

class YALToolsYaViewTest < Test::Unit::TestCase

  require 'base64'
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
    @dbname = "unitdb_a"
    couch_conf = File::join([@basedir,"..","utils","conf","yalt.athlon.yaml"])
    couch_label = "default.user"
    @couch = YALTools::CmdLine::getCouch(couch_conf, couch_label, false)

    @couch.delete("/#{@dbname}")
    @couch.put("/#{@dbname}",{})
    data_list = YALTools::YaJsonRows.new(@couch, @dbname)
    open(File::join([@inc_dir,"attach_docs.txt"])) do |f|
      json = {}
      id = nil
      f.each_line do |line|
        row = line.split(":")
        id = Digest::SHA2::hexdigest(line)
        json["_id"] = id
        json["name"] = row[0]
        json["gid"] = row[2].to_i

        ## adds an attachment doc
        if json["name"] == "sys"
          filename = "a.txt"
          filepath = File::join([@inc_dir, filename])
          json["_attachments"] = { filename => {} }
          json["_attachments"][filename]["content_type"] = "text/plain"
          json["_attachments"][filename]["data"] = Base64::encode64(open(filepath).read) if FileTest::exist?(filepath)
        end
        @couch.put("/#{@dbname}/#{id}", json)
        json = {}
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
  
  def test_attachments
    view = YALTools::YaViewDocs.new(@couch, @dbname, "unittest", "name")
    first_doc = nil
    last_doc = nil
    page_counter = 1
    view.debug = true
    view.each_with_attachments({},0,2) do |rows, skip, page, max_page, max_rows|
      assert_equal(page_counter, page)
      
      rows.each do |row|
        if row.has_key?("_attachments")
          assert_equal("sys",row["name"])
          assert_equal("a.txt", row["_attachments"].keys[0])
          assert_equal("text/plain", row["_attachments"]["a.txt"]["content_type"])
          assert_equal("aGVsbG8gd29ybGQhCg==", row["_attachments"]["a.txt"]["data"])
        end
      end
      page_counter += 1
    end
  end
end
