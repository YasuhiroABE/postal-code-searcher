<!-- -*- mode: markdown ; coding: utf-8 -*- -->

Sample Application of YALTools - Japan National Postal Code Searcher using CouchDB
==================================================================================
[Japanese]
このアーカイブはYALToolsを利用したYALToolsのサンプルアプリケーションです。

コードは ([www.yadiary.net/postal](http://www.yadiary.net/postal/)) で公開しているアプリケーションとほぼ同一で、
日本郵便が配布しているデータを元に郵便番号検索を行ないます。


インストール方法など詳しい説明は日本語で、([www.yadiary.net/postal/internals.html](http://www.yadiary.net/postal/internals.html)]にあります。

ここから先は英語で簡単なインストール方法などについて説明します。

[English]

The detailed description is available from ([www.yadiary.net/postal/internals.html](http://www.yadiary.net/postal/internals.html)], but Japanese only.

Prerequisites
-------------

* CouchDB 1.0.2
* Ruby 1.9.2-p0 or above

Installation
------------
In this section, it assumes that the installation directory is "/app".
First, please unpack the archive file and make up the directory structure like as "/app/{lib,data,contents}".

    $ sudo mkdir /app
    $ sudo tar xjf ~/postal-code-searcher.20110403.tar.bz2
    $ sudo mv postal-code-searcher/* .

If the "ruby" command is installed other than /usr/local/bin/ruby,
please execute the command, change\_ruby\_command\_name.sh, with the correct ruby filename.

    $ /app/lib/postal/1.6/sbin/change_ruby_command_name.sh /usr/bin/ruby1.9.2

### Setting up the account information to CouchDB
There are two configuration files, /app/lib/postal/1.6/utils/conf/yalt.yaml and /app/data/postal/1.6/yalt.yaml.
Both file format is completely same, but the required user role is different.

The "/app/lib/postal/1.6/utils/conf/yalt.yaml" is used to setup the database, so a database admin role or system admin role is required.

Next, the "/app/data/postal/1.6/yalt.yaml" is used by the FastCGI application scripts.
The user role should be a database reader or higher.

If you use the couchdb without user and password, it is the default configuration couchdb and couchbase and called the admin party, then both file will be like that.

    ----
    default.user:
      host: 127.0.0.1
      port: 5984

If an admins user, admin, and password, xxxxxx, are defined, then the file will be;

    ----
    default.user:
      host: 127.0.0.1
      port: 5984
      user: admin
      password: xxxxxx

Much more detail about yalt.yaml configuration file is available at ([API Reference of YALTools::MainWrapper](http://lscouchdb.yasundial.org/apidoc/YALTools/MainWrapper.html)).

The last configuration file, /app/data/postal/1.6/yapostal.yaml, is used for the name of database.
If the database name, *"postal2"*, is available in your couchdb database, there is nothing to change.

### Setting up the FastCGI environment for Apache2
If using the Ubuntu (10.04), please install the mod_fcgid module and one apache2 mpm module, apache2-mpm-worker or apache2-mpm-prefork.

    $ sudo apt-get install libapache2-mod-fcgid apache2-mpm-worker

Then add the following entry to /etc/apache2/sites-enabled/000-default;

    Alias /postal/ "/app/contents/postal/"
    <Directory "/app/contents/postal">
        Options +ExecCGI
        Order deny,allow
        Deny from all
        Allow from 127.0.0.0/255.0.0.0 ::1/128
    </Directory>

The configuration of *Allow* directive is depends on your environment, the location of the client browser.

### Setting up the FastCGI module for Ruby

    $ gem install -i /app/lib/postal/1.6/gems/ fcgi

### Populating the Japan national postal code database

    $ cd /app/lib/postal/1.6/sbin
    $ ../utils/sbin/mkdb postal2
    $ ./postalcsv2json.rb ../data/ken_all.201102.utf-8.csv | ../utils/bin/postdocs postal2

### Setting up the view definitions

    $ cd /app/lib/postal/1.6/utils
    $ bin/csv2json csv/view_defs.all.csv  | bin/putdesign postal2 all
    $ bin/lsviews postal2 all pref -g
    
After setting up the view data, few dozens of minutes later, the lsviews command will respond to like as;
    
    $ bin/lsviews postal2 all pref -g
    {"key":"三重県","value":2473}
    ....

It finished the setup, please try to knock on the application.

    $ curl http://localhost/postal/main.fcgi

If you get any error messages, please refer the error.log file of apache2.

Bundled Software and Licenses
-----------------------------
This application contains the following libraries.

* Blueprint CSS Framework 1.0: The MIT License, app.root/contents/postal/css/blueprint/LICENSE.
* jQuery 1.4.4: ([MIT License or GPL](http://jquery.org/license))
* FlexBox 0.9.6: ([Microsoft Public License](http://flexbox.codeplex.com/license))

Ruby libraries:

* couchdb.rb from http://wiki.apache.org/couchdb/Getting_started_with_Ruby: license is unknown.
* gettext 2.1.0: same as Ruby or LGPL
* locale 2.0.5: same as Ruby
* net-http-digest_auth 1.0: ([The MIT license](http://seattlerb.rubyforge.org/net-http-digest_auth/))
* deep_merge.rb ([The MIT license](https://github.com/peritor/deep_merge))

License
-------
Other code listed on the above section is licensed under the Apache License, Version 2.0.

    Copyright (C) 2010,2011 Yasuhiro ABE <yasu@yasundial.org>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
         http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
