<!-- -*- mode: markdown ; coding: utf-8 -*- -->

README
======
インストール、コマンドの使い方などについては http://lscouchdb.sourceforge.net/ を参照してください。

前提要件
--------
* Ruby 1.9.2 
* CouchDB 1.0.2

JRuby 1.6_RC2での稼働も確認しています。
JRuby 1.6のセットアップについてはWebサイトを参照してください

ディレクトリ構造
----------------

*  utils/conf/yalt.yaml - 接続用設定ファイル
*  utils/conf/yalt.*hostname*.yaml - 接続用設定ファイル (存在する場合、yalt.yamlの代りに使用)
*  utils/conf/master\_pw.json - デフォルトの暗号化用共通鍵ファイル
*  utils/sbin/ - DB管理系のコマンド (主にSetup時に利用)
*  utils/bin/ - 文書操作系のコマンド (主にRuntime環境で利用)

### 含まれている外部ライブラリ

#### lib/couchdb.rb 
This library is availabel from my GitHub repository, [https://github.com/YasuhiroABE/CouchDB-Ruby\_Module\_Enhancement](https://github.com/YasuhiroABE/CouchDB-Ruby\_Module\_Enhancement).

#### lib/net/http/digest\_auth.rb
Net::HTTP::DigestAuth is available from [http://seattlerb.rubyforge.org/net-http-digest\_auth/](http://seattlerb.rubyforge.org/net-http-digest\_auth/) under the MIT license.

#### lib/deep\_merge.rb
This version of deep\_merge.rb is maintained by Steve Midgley and available from [https://github.com/peritor/deep\_merge](https://github.com/peritor/deep\_merge) under the MIT license.

インストール
------------
任意のディレクトリにパッケージを展開します。

"utils/conf/yalt.yaml"設定ファイルをCouchDBの認証情報に合わせて編集します。



以上
