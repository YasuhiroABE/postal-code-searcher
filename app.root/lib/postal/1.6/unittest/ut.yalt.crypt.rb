#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'test/unit'

class YALToolsCryptTest < Test::Unit::TestCase

  $:.unshift File::join([File::dirname($0), "..","lib"])
  require 'yalt'

  def setup
    @basedir = File::dirname($0)
    @basename_prefix = File::basename($0, ".rb")
    @inc_dir = File::join([@basedir, "#{@basename_prefix}.files"])  ## basedir to an include directory

    ## for reading/writing usage
    @tmp_file = File::join([@inc_dir, "_tmp.json"])
    if FileTest::exist?(@tmp_file)
      File::unlink(@tmp_file)
    end
  end
  def teardown
    if FileTest::exist?(@tmp_file)
      File::unlink(@tmp_file)
    end
  end
  def test_load_crypt_password
    master_pw_file = File::join([@inc_dir, "master_pw.json"])
    master_pw = YALTools::Crypt::load_crypt_password(master_pw_file)
    assert_equal("b5745b7adb9fcedfb16265e16f81b8243aea8dc886607a1277cd7508f9343be9", master_pw)
  end

  def test_encrypt_and_decrypt_text
    master_pw_file = File::join([@inc_dir, "master_pw.json"])
    original_plain_text = "xxxxyyyzzzz"
    
    assert(File::exist?(master_pw_file))

    enc_text, salt = YALTools::Crypt::encrypt_text(master_pw_file, original_plain_text)
    assert_equal(String, salt.class)
    assert_equal(String, enc_text.class)
    assert_equal(16, salt.length)
    assert_compare(1, "<=", enc_text.length)

    plain_text = YALTools::Crypt::decrypt_text(master_pw_file, salt, enc_text)
    assert_equal(original_plain_text, plain_text)
  end

  def test_save_crypt_password
    original_pass = "foo.bar"
    YALTools::Crypt::save_crypt_password(original_pass, @tmp_file)
    require 'json'
    json = JSON.parse(open(@tmp_file).read)
    
    assert(json.has_key?("sec_text"))
    assert_equal(original_pass, json["sec_text"])
  end

  def test_gen_password
    pass = YALTools::Crypt::gen_password
    assert_equal(64, pass.size)
  end
end
