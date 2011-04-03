<!-- -*- mode: markdown ; coding: utf-8 -*- -->

Enhancement of Couch::Server Class 
==================================
The original Couch::Server class is introduced at [Getting started with Ruby at Official CouchDB Wiki](http://wiki.apache.org/couchdb/Getting_started_with_Ruby "Official CouchDB Wiki").

We provide some enhancements for the Couch::Server class as the following;

* Basic Authentication
* Digest Authentication for Apache Proxy
* SSL Client Authentication for Stunnel
* Proxy Authentication for proxy\_authentification\_handler

Get()/put()/post()/delete() methods are same as the original methods.

Basic Usage
-----------
It uses third argument to pass options as follows.

    opts = {}
    server = Couch::Server.new("localhost", "5984", opts)

### Basic Authentication
It supports following parameters.

* user
* password

#### Example

    opts = {}
    opts["user"] = "username"
    opts["password"] = "xxxxxx"
    server = Couch::Server.new("localhost", "5984", opts)

The "cacert" parameter is also available for connecting to SSL port such as 6984 and 443.
To use this feature, please refer the latter part of this document.

### Digest Authentication bfor Apache Proxy
To use this feature, net-http-digest_auth module is essential.

It supports following parameters.

* user
* password
* digest\_auth

#### Example
    opts = {}
    opts["user"] = "username"
    opts["password"] = "xxxxxx"
    opts["digest_auth"] = ""
    server = Couch::Server.new("localhost", "80", opts)

The value of "digest\_auth" is not evaluated.

The "cacert" parameter is also available for connecting to SSL port such as 6984 and 443.
To use this feature, please refer the latter part of this document.

### SSL Client Authentication for Stunnel
It supports following parameters.

* cacert - the filepath of the PEM file.
* ssl\_verify\_mode - (default: OpenSSL::SSL::VERIFY\_PEER)
* ssl\_verify\_depth - (default: 5)
* ssl\_client\_cert - Instance of OpenSSL::X509::Certificate
* ssl\_client\_key - Instance of OpenSSL::PKey::RSA

#### Example
    opts['user'] = "username"
    opts['password'] = "xxxxxx"
    opts['cacert'] = "/etc/ssl/certs/cacerts_and_server_certs.pem"
    opts['ssl_client_cert'] = OpenSSL::X509::Certificate.new(File.new("/etc/ssl/certs/client.cert.pem"))
    opts['ssl_client_key']  = OpenSSL::PKey::RSA.new(File.new("/etc/ssl/keys/client.key.pem"))
    server = Couch::Server.new("couchdb.example.org", "6984", opts)

The hostname of the first argument must be same as the common name (cn) of the server certificate.

This feature is depending on the standard ruby libraries.
Please refer the following documents.

* [library openssl](http://www.ruby-doc.org/stdlib/libdoc/openssl/rdoc/index.html "OpenSSL")
* [library net/http](http://www.ruby-doc.org/stdlib/libdoc/net/http/rdoc/index.html "Net::HTTP")

### Proxy Authentication for proxy_authentification_handler
It supports following parameters.

* proxy\_auth\_user (=> X-Auth-CouchDB-UserName)
* proxy\_auth\_roles (=> X-Auth-CouchDB-Roles)
* proxy\_auth\_token (=> X-Auth-CouchDB-Token)


Practical example - Basic/Digest Authentication over SSL
--------------------------------
The "cacert" parameter provides the SSL support.

The "cacerts" must contains the both certificate of CA and the web server.

    opts = {}
    opts["user"] = "*username*"
    opts["password"] = "xxxx"
    opts["cacert"] = "/etc/ssl/certs/cacerts_and_server_certs.pem"
    server = Couch::Server.new("localhost", "443", opts)

