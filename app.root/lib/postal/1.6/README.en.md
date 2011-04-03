<!-- -*- mode: markdown ; coding: utf-8 -*- -->

README
==============
Please refer the web site, http://lscouchdb.sourceforge.net/, about installation and command reference.

Prerequisites
-------------
* Ruby 1.9.2
* CouchDB 1.0.2

JRuby 1.6.0_RC2 also works well.
Detail information is available at the web site.

Directory Structure
-------------------

*  lib/yalt.rb - YALTools library
*  utils/conf/yalt.yaml
*  utils/conf/master\_pw.json
*  utils/conf/yalt.*hostname*.yaml (optional for shared filesystem)
*  utils/conf/master\_pw.*hostname*.json (optional for shared filesystem)
*  utils/sbin/ - for Database Management (most of them for server management)
*  utils/bin/ - for Document Management (most of them for runtime assistant)

### Other libraries included in this package

#### lib/couchdb.rb 
couchdb.rb is availabel from my GitHub repository (https://github.com/YasuhiroABE/CouchDB-Ruby\_Module\_Enhancement).

#### lib/net/http/digest\_auth.rb
Net::HTTP::DigestAuth is available from (http://seattlerb.rubyforge.org/net-http-digest\_auth/).

#### lib/deep\_merge.rb
This version of deep\_merge.rb is maintained by Steve Midgley and available from (https://github.com/peritor/deep\_merge).

__EOF__
