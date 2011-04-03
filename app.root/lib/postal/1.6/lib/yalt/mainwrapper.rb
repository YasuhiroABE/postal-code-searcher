# -*- coding: utf-8 -*-

module YALTools
  
  ##
  ## YALTools::MainWrapper is a class which has a responsibility to control 
  ## information about the authentication.
  ## 
  ## The YALTools::MainWrapper::getCouch method returns  an instance of YALTools::Main.
  ## 
  ## The +conf_file+ can hold multiple authentication entries.
  ## The +label+ specifies the entry which will be used for authentication.
  ## 
  ## == Usage
  ##    wrapper = YALTools::MainWrapper.new("config.yaml", "default.user")
  ##    wrapper.set_masster_pwfile("master_pw.json")
  ##    @couch = wrapper.getCouch
  ##    h = @couch.get("/example/_all_docs")
  ##
  ## === Configuration File Format
  ## These are standard form of the yaml conf file.
  ##
  ## [For basic/digest authentication]
  ##   The net-http-digest_auth library is required for the digest auth.
  ##
  ##     label:
  ##       host:
  ##       port:
  ##       user:
  ##       password:
  ##       password_salt:       ## option for encrypted password.
  ##       password_pass_file:  ## option.
  ##       digest_auth:         ## option for digest_auth.
  ##       cacert:              ## option for ssl.
  ##
  ## [for ssl_client authentication]
  ##   Stunnel or other deligation server is required for the ssl client auth.
  ##
  ##     label:
  ##       host:
  ##       port:
  ##       user:
  ##       password:
  ##       cacert:
  ##       ssl_client_cert_file:
  ##       password_salt:        ## option.
  ##       password_pass_file:   ## option.
  ##       ssl_client_key_file:
  ##       ssl_client_key_file_pass:       ## option for the encrypted ssl_client_key_file.
  ##       ssl_client_key_file_pass_salt:  ## option.
  ##       ssl_client_key_file_pass_file:  ## option.
  ##       ssl_verify_depth:     ## option.
  ##       ssl_verify_mode:      ## option. one of "OpenSSL::SSL::VERIFY_NONE",
  ##                             ##                "OpenSSL::SSL::VERIFY_PEER",
  ##                             ##                "OpenSSL::SSL::VERIFY_CLIENT_ONCE",
  ##                             ##                "OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT"
  ##
  ## [for proxy_authentication]
  ##   The proxy authentication is a rare case, I think. 
  ##   But it's possible.
  ##
  ##     label:
  ##       host:
  ##       port:
  ##       user:
  ##       password:
  ##       password_salt:       ## option.
  ##       password_pass_file:  ## option.
  ##       proxy_auth_user:
  ##       proxy_auth_token:
  ##       proxy_auth_rules:
  ##       cacert:              ## option for ssl.
  ##
  ## == Requirements for encryption/decryption support.
  ## 
  ## YALTools::MainWrapper class supports the password encryption and decription.
  ## A master password file is essential for this function.
  ##
  ## The set_master_pwfile(filepath) method is prepared for your convenience.
  ##
  ## Instead of the set_master_pwfile() method, please use +password_pass_file+ and
  ## +ssl_client_key_file_pass_file+ config entries.
  ##
  ## == Examples
  ##
  ## === Case 1. Connect directly to CouchDB.
  ##
  ##  case1.admin:
  ##     host: localhost
  ##     port: 5984
  ##     user: admin
  ##     password: xxxxxx
  ##
  ## === Case 2. Connect directly to CouchDB, but password is encrypted.
  ##
  ##   case2.admin:
  ##     host: localhost
  ##     port: 5984
  ##     user: admin
  ##     password: d3a5a45f8c5e1ad0dd134a9c46e1c82f
  ##     password_salt: 3c31184f5193ef30
  ##
  ## The password, xxxxxx, was encrypted by the salt and the master-password text;
  ##
  ##   {"sec_text":"f4fcf31194e12f3fbfefa3d1f5256e2cf19859f63f5cf2ab1e5778f85afa40f2"}.
  ##
  ## After saving the above line to the file like as 'sec_text.txt', the encrypted string can be decrypted;
  ##
  ##    $ utils/sbin/decpassword -m sec_text.txt -t d3a5a45f8c5e1ad0dd134a9c46e1c82f -s 3c31184f5193ef30
  ##    xxxxxx
  ##
  ## === Case 3. Connect to CouchDB via Apache working as a ssl web proxy.
  ##
  ## In this case, apache is working as a proxy and listening on 443 port with the following setting;
  ##   <IfModule mod_proxy.c>
  ##         ProxyPass / http://127.0.0.1:5984/
  ##         ProxyPassReverse / http://127.0.0.1:5984/
  ##   </IfModule>
  ##
  ##   case3.admin:
  ##     host: localhost
  ##     port: 443
  ##     user: admin
  ##     password: xxxxxx
  ##     cacert: /etc/ssl/certs/cacerts.pem
  ##
  ## The user and password will be confirmed by the CouchDB.
  ##
  ## === Case 4. Connect to CouchDB via stunnel.
  ##
  ##   admin.admin:
  ##     host: ssl.yasundial.org
  ##     port: 6984
  ##     user: admin
  ##     password: xxxxxx
  ##     cacert: /etc/ssl/certs/cacerts.pem
  ##     ssl_client_cert_file: /etc/ssl/certs/client.cert.pem
  ##     ssl_client_key_file: /etc/ssl/certs/client.key.pem
  ##     ssl_client_key_file_pass: xyxyxyxy
  ##     ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER
  ##
  ## == Exceptions
  ## [YALTools::LabelNotFoundError] 
  ##   causes from 
  ##   * initialize
  ## 
  
  class MainWrapper

    attr_accessor :debug

    # If the label is not defined on the conf_file, it raises the exception, YALTools::LabelNotFoundError.
    def initialize(conf_file, label)
      begin
        @conf = YAML::load_file(conf_file)
      rescue
        @conf = {}
      end
      @label = label
      @debug = false
      @master_pwfile = ""
      
      raise YALTools::LabelNotFoundError if not @conf.has_key?(@label)
    end

    # sets the master password filepath for encryption and decription.
    #
    # The file format of the master password file is ;
    #
    #   {"sec_text":"xxxxxxxxxxxxxxxxxxxxxxxxxxxx"}
    #
    # The value of "sec_text" must be string, but there is no limitation of its length.
    #
    def set_master_pwfile(filepath)
      @master_pwfile = filepath
      $stderr.puts "[debug] set master_pwfile to #{filepath}." if @debug
    end
    
    # returns the instance of the YALTools::Main or nil if failed.
    def getCouch()
      main = nil
      
      opts = {}
      begin
        @conf[@label].keys.each do |l|
          case l
          when 'ssl_client_cert_file'
            opts['ssl_client_cert'] = 
              OpenSSL::X509::Certificate.new(File.new(@conf[@label][l]))
            
          when 'ssl_client_key_file'
            if @conf[@label].has_key?('ssl_client_key_file_pass')
              ssl_client_key_file_pass = ""              
              if @conf[@label].has_key?('ssl_client_key_file_pass_salt')
                if @conf[@label].has_key?('ssl_client_key_file_pass_file')
                   ssl_master_pwfile = @conf[@label]['ssl_client_key_file_pass_file']
                else
                  ssl_master_pwfile = @master_pwfile
                end
                ssl_client_key_file_pass = YALTools::Crypt::decrypt_text(ssl_master_pwfile,
                                                                        @conf[@label]['ssl_client_key_file_pass_salt'], 
                                                                        @conf[@label]['ssl_client_key_file_pass'])
              else
                ssl_client_key_file_pass = @conf[@label]['ssl_client_key_file_pass']
              end
              opts['ssl_client_key'] = OpenSSL::PKey::RSA.new(File.new(@conf[@label][l]),
                                                              ssl_client_key_file_pass)
            else
              opts['ssl_client_key'] = OpenSSL::PKey::RSA.new(File.new(@conf[@label][l]))
            end
          when 'ssl_verify_mode'
            begin
              opts[l] = eval(@conf[@label][l])
            rescue
              opts[l] = nil
            end
          when 'password'
            if @conf[@label].has_key?('password_salt')
              password_master_pwfile = @master_pwfile
              password_master_pwfile = @conf[@label]['password_pass_file'] if @conf[@label].has_key?('password_pass_file')
              opts[l] = YALTools::Crypt::decrypt_text(password_master_pwfile,
                                                     @conf[@label]['password_salt'], @conf[@label][l])
            else
              opts[l] = @conf[@label][l]
            end
          when 'host','port'
          when 'password_salt','password_pass_file'
          when 'ssl_client_key_file_pass','ssl_client_key_file_pass_salt','ssl_client_key_file_pass_file'
            ## do nothing
          else
            opts[l] = @conf[@label][l]
          end
        end
        
        opts["debug"] = true if debug
        $stderr.puts "opts: #{opts}" if debug
        
        main = YALTools::Main.new(Couch::Server.new(@conf[@label]["host"], @conf[@label]["port"], opts))
        main.debug = debug if debug and main.respond_to?(:debug)
      rescue
        $stderr.puts $! if debug
      end
      checkCouchDBVersion(main)
      return main
    end

    private
    
    # returns true or false. 
    #
    # +couch+ is an instance of Couch::Server or YALTools::Main.
    #
    # The "true" means that it successfully connected to CouchDB.
    def checkCouchDBVersion(couch)
      flag = false
      begin
        json = couch.get("/")
        case json
        when Hash 
          flag = true if json.has_key?("version")
        when Net::HTTPResponse
          flag = true if json.body =~ /version/
        end
      rescue
      end
      raise YALTools::ServerConnectionError if flag == false
    end
  end
end
