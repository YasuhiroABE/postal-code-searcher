<!-- -*- mode: markdown ; coding: utf-8 -*- -->

Enhancement of Couch::Server Class 
==================================
オリジナルのCouch::Serverクラスは[Getting started with Ruby at Official CouchDB Wiki](http://wiki.apache.org/couchdb/Getting_started_with_Ruby "Official CouchDB Wiki")に掲載されています。

このクラスでは以下の認証方式をサポートする拡張を行なっています。

* Basic認証
* Digest認証 for Apache Proxy
* SSLクライアント認証 for Stunnel
* Proxy認証 for proxy\_authentification\_handler

get/put/post/deleteのメソッドの挙動はオリジナルと同じです。

基本的な使い方
--------------
オリジナルで準備されている第三引数を利用して、拡張を行なっています。

    opts = {}
    server = Couch::Server.new("localhost", "5984", opts)

各認証方式でサポートしているオプションについて解説していきます。

### Basic認証
以下のパラメータをサポートします。

* user
* password

#### 具体例

    opts = {}
    opts["user"] = "username"
    opts["password"] = "xxxxxx"
    server = Couch::Server.new("localhost", "5984", opts)

SSL(6984port, 443port, etc.)を使用するためには cacert オプションを利用します。
詳細は後半の説明を参照してください。

### Digest認証 for Apache Proxy
rubyのnet-http-digest\_authモジュールが必要です。

次のパラメータをサポートします。

* user
* password
* digest\_auth

#### 具体例
    opts = {}
    opts["user"] = "username"
    opts["password"] = "xxxxxx"
    opts["digest_auth"] = ""
    server = Couch::Server.new("localhost", "80", opts)

値には無関係に"digest\_auth"が設定されていれば有効になります。

SSL(6984port, 443port, etc.)を使用するためには cacert オプションを利用します。
詳細は後半の説明を参照してください。

### SSLクライアント認証 for Stunnel
次のパラメータをサポートします。

* cacert PEM形式ファイルへのパスを指定
* ssl\_verify\_mode (default: OpenSSL::SSL::VERIFY\_PEER)
* ssl\_verify\_depth (default: 5)
* ssl\_client\_cert OpenSSL::X509::Certificateのインスタンス
* ssl\_client\_key OpenSSL::PKey::RSAのインスタンス 

#### 具体例
    opts['user'] = "username"
    opts['password'] = "xxxxxx"
    opts['cacert'] = "/etc/ssl/certs/cacerts_and_server_certs.pem"
    opts['ssl_client_cert'] = OpenSSL::X509::Certificate.new(File.new("/etc/ssl/certs/client.cert.pem"))
    opts['ssl_client_key']  = OpenSSL::PKey::RSA.new(File.new("/etc/ssl/keys/client.key.pem"))
    server = Couch::Server.new("couchdb.example.org", "6984", opts)

ホスト名はServer CertificateのCommon Name (CN)と同じである必要があります。

ruby標準のopenssl, net/httpsライブラリに依存しています。
詳細は各ドキュメントを参照してください。

* [library net/https for ruby 1.9.2 @doc.okkez.net](http://doc.okkez.net/static/192/library/net=2fhttps.html "Net::HTTPSドキュメント")
* [library openssl for ruby 1.9.2 @doc.okkez.net](http://doc.okkez.net/static/192/library/openssl.html "OpenSSLドキュメント")

### Proxy認証 for proxy\_authentification\_handler
次のパラメータをサポートします。

* proxy\_auth\_user (=> X-Auth-CouchDB-UserName)
* proxy\_auth\_roles (=> X-Auth-CouchDB-Roles)
* proxy\_auth\_token (=> X-Auth-CouchDB-Token)

パラメータが指定されていた場合に、対応するヘッダに値がセットされます。


応用編  - SSLを利用したBasic認証
--------------------------------
cacertを指定する事で、Basic認証やDigest認証でSSLポートを利用する事も可能です。

    opts = {}
    opts["user"] = "*username*"
    opts["password"] = "xxxx"
    opts["cacert"] = "/etc/ssl/certs/cacerts_and_server_certs.pem"
    server = Couch::Server.new("localhost", "443", opts)


以上

