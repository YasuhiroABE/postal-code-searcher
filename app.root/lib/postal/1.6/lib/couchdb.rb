# -*- coding: utf-8 -*-

#
# The original code is located at the CouchDB Wiki
#
#   http://wiki.apache.org/couchdb/Getting_started_with_Ruby
#
# Please refer the original code.
#

module Couch
  
  # == Description
  #
  # This version of the Couch::Server class is modified for additional authentication methods.
  #
  # It supports the following authentication methods with or without SSL connection;
  #
  # * Basic Authentication
  # * Digest Authentication (net-http-digest_auth library is required)
  # * SSL Client Authentication (It is not supported by the CouchDB server)
  # * CouchDB Proxy Authentication
  #
  # Other, Get()/put()/post()/delete(), methods are same as original methods.
  #
  # == Usage
  #
  #   opts = {}
  #   server = Couch::Server.new("localhost", "5984", opts)
  #
  # The +opts["cacert"]+ enables the SSL connection.
  #
  #   opts["cacert"] = "/path/to/cacert.pem"
  #   server = Couch::Server.new("couchdb.example.org", "443", opts)
  #
  # The server hostname must be matched with the Common Name of the server certificate.
  #
  # === Basic Authentication
  #
  #   opts = {}
  #   opts["user"] = "username"
  #   opts["password"] = "xxxxxx"
  #   server = Couch::Server.new("localhost", "5984", opts)
  #
  # === Digest Authentication bfor Apache Proxy
  # 
  #   opts = {}
  #   opts["user"] = "username"
  #   opts["password"] = "xxxxxx"
  #   opts["digest_auth"] = ""
  #   server = Couch::Server.new("localhost", "80", opts)
  #
  # The digest authentication is turned on when the "digest_auth" key is defined.
  #
  # === SSL Client Authentication for Stunnel
  #
  #   opts['user'] = "username"
  #   opts['password'] = "xxxxxx"
  #   opts['cacert'] = "/path/to/cacert.pem"
  #   opts['ssl_client_cert'] = OpenSSL::X509::Certificate.new(File.new("/path/to/cert.pem"))
  #   opts['ssl_client_key']  = OpenSSL::PKey::RSA.new(File.new("/path/to/key.pem"))
  #   server = Couch::Server.new("couchdb.example.org", "6984", opts)
  #
  # The +ssl_verify_depth+ and +ssl_verify_mode+ are optional.
  # The default values are followings;
  #
  #   opts["ssl_verify_mode"] = OpenSSL::SSL::VERIFY_PEER
  #   opts["ssl_verify_depth"] = 5
  #
  # === Proxy Authentication for proxy_authentification_handler
  #
  #   opts["proxy_auth_user"]  = "user01"
  #   opts["proxy_auth_roles"] = "dbadmin"
  #   opts["proxy_auth_token"] = "d4c3b0fd10bed9642fb5bbfcc0203ca27c707300"
  #   server = Couch::Server.new("localhost", "80", opts)
  #
  # == About the original code
  #
  # The original "Couch" module is describe at the couchdb wiki;
  #
  #   http://wiki.apache.org/couchdb/Getting_started_with_Ruby
  #
  # Please refer the original file, couchdb.rb.orig, in the same directory.
  #
  # == License
  #
  # The modified code is licensed by the following term; 
  #
  #  Copyright (C) 2010,2011 Yasuhiro ABE <yasu@yasundial.org>
  #
  #  Licensed under the Apache License, Version 2.0 (the "License");
  #  you may not use this file except in compliance with the License.
  #  You may obtain a copy of the License at
  #  
  #       http://www.apache.org/licenses/LICENSE-2.0
  #  
  #  Unless required by applicable law or agreed to in writing, software
  #  distributed under the License is distributed on an "AS IS" BASIS,
  #  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  #  See the License for the specific language governing permissions and
  #  limitations under the License.
  
  class Server
    require 'net/https'
    def initialize(host, port, options = nil)
      @host = host
      @port = port
      @options = options
      @options = Hash.new if options.nil? or not options.kind_of?(Hash)
      @www_auth = nil
      @auth = nil
      if options.has_key?('digest_auth')
        require 'net/http/digest_auth'
        @digest_auth = Net::HTTP::DigestAuth.new
      end
    end

    def delete(uri)
      setup_digest_auth(uri,'DELETE')
      request(Net::HTTP::Delete.new(uri))
    end

    def get(uri)
      setup_digest_auth(uri,'GET')
      request(Net::HTTP::Get.new(uri))
    end

    def head(uri)
      setup_digest_auth(uri,'HEAD')
      request(Net::HTTP::Head.new(uri))
    end

    def put(uri, json)
      setup_digest_auth(uri,'PUT')
      req = Net::HTTP::Put.new(uri)
      req["content-type"] = "application/json"
      req.body = json
      request(req)
    end

    def post(uri, json)
      setup_digest_auth(uri,'POST')
      req = Net::HTTP::Post.new(uri)
      req["content-type"] = "application/json"
      req.body = json
      request(req)
    end

    def request(req)
      req.basic_auth @options['user'], @options['password'] if @options.has_key?('user') and 
        @options.has_key?('password') and 
        not @options.has_key?('digest_auth')
      req["X-Auth-CouchDB-UserName"] = @options['proxy_auth_user'] if @options.has_key?('proxy_auth_user')
      req["X-Auth-CouchDB-Roles"] = @options['proxy_auth_roles'] if @options.has_key?('proxy_auth_roles')
      req["X-Auth-CouchDB-Token"] = @options['proxy_auth_token'] if @options.has_key?('proxy_auth_token')
      
      client = Net::HTTP.new(@host, @port)
      check_ssl(client)
    
      client.set_debug_output $stderr if @options.has_key?('debug') and @options['debug']
  
      if @options.has_key?('digest_auth')
        req["Authorization"] = @auth
      end
      
      res = client.start { |http| http.request(req) }
      @www_auth = nil if res.kind_of?(Net::HTTPUnauthorized) and @options.has_key?('digest_auth')
      res
    end
    
    private
    
    def check_ssl(client)
      if @options.has_key?('cacert')
        client.use_ssl = true
        client.ca_file = @options['cacert']
        client.verify_mode  = OpenSSL::SSL::VERIFY_PEER
        client.verify_mode  = @options['ssl_verify_mode'] if @options.has_key?('ssl_verify_mode')
        client.verify_depth = 5
        client.verify_depth = @options['ssl_verify_depth'] if @options.has_key?('ssl_verify_depth')
        client.cert         = @options['ssl_client_cert'] if @options.has_key?('ssl_client_cert')
        client.key          = @options['ssl_client_key'] if @options.has_key?('ssl_client_key')
      end
    end

    def setup_digest_auth(uri, method)
      return if not @options.has_key?('digest_auth')
      if @www_auth == nil
        req = Net::HTTP::Get.new(uri)
        client = Net::HTTP.new(@host, @port)
        check_ssl(client)
        res = client.start { |http| http.request(req) }
        ## res must be the instance of Net::HTTPUnauthorized
        raise res if not res.kind_of?(Net::HTTPUnauthorized)
        @www_auth = res['www-authenticate']
      end
      url = TinyURI.new(@options['user'], @options['password'], uri)
      @auth = @digest_auth.auth_header(url, @www_auth, method)
    end
  end

  private
  # net/http/digest_auth using this class to pass information.
  class TinyURI  # :nodoc:all
    attr_accessor :request_uri, :user, :password
    def initialize(user, pass, path)
      @user = user 
      @password = pass
      @request_uri = path
    end
  end
end
