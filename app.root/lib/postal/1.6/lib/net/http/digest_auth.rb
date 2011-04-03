# -*- coding: utf-8 -*-
require 'net/http'
require 'digest'
require 'cgi'

# This copyright notice was copied by Yasuhiro ABE from http://seattlerb.rubyforge.org/net-http-digest_auth/
#
# Copyright © 2010 Eric Hodel
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ‘Software’), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

##
# An implementation of RFC 2617 Digest Access Authentication.
#
# http://www.rfc-editor.org/rfc/rfc2617.txt
#
# Here is a sample usage of DigestAuth on Net::HTTP:
#
#   require 'uri'
#   require 'net/http'
#   require 'net/http/digest_auth'
#
#   uri = URI.parse 'http://localhost:8000/'
#   uri.user = 'username'
#   uri.password = 'password'
#
#   h = Net::HTTP.new uri.host, uri.port
#
#   req = Net::HTTP::Get.new uri.request_uri
#
#   res = h.request req
#
#   digest_auth = Net::HTTP::DigestAuth.new
#   auth = digest_auth.auth_header uri, res['www-authenticate'], 'GET'
#
#   req = Net::HTTP::Get.new uri.request_uri
#   req.add_field 'Authorization', auth
#
#   res = h.request req

class Net::HTTP::DigestAuth

  ##
  # Version of Net::HTTP::DigestAuth you are using

  VERSION = '1.0'

  ##
  # Creates a new DigestAuth header creator.
  #
  # +cnonce+ is the client nonce value.  This should be an MD5 hexdigest of a
  # secret value.

  def initialize cnonce = make_cnonce
    @nonce_count = -1
    @cnonce = cnonce
  end

  ##
  # Creates a digest auth header for +uri+ from the +www_authenticate+ header
  # for HTTP method +method+.
  #
  # The result of this method should be sent along with the HTTP request as
  # the "Authorization" header.  In Net::HTTP this will look like:
  #
  #   request.add_field 'Authorization', digest_auth.auth_header # ...
  #
  # See Net::HTTP::DigestAuth for a complete example.
  #
  # IIS servers handle the "qop" parameter of digest authentication
  # differently so you may need to set +iis+ to true for such servers.

  def auth_header uri, www_authenticate, method, iis = false
    @nonce_count += 1

    user     = CGI.unescape uri.user
    password = CGI.unescape uri.password

    www_authenticate =~ /^(\w+) (.*)/

    params = {}
    $2.gsub(/(\w+)="(.*?)"/) { params[$1] = $2 }

    a_1 = Digest::MD5.hexdigest "#{user}:#{params['realm']}:#{password}"
    a_2 = Digest::MD5.hexdigest "#{method}:#{uri.request_uri}"

    request_digest = [
      a_1,
      params['nonce'],
      ('%08x' % @nonce_count),
      @cnonce,
      params['qop'],
      a_2
    ].join ':'

    header = [
      "Digest username=\"#{user}\"",
      "realm=\"#{params['realm']}\"",
      if iis then
        "qop=\"#{params['qop']}\""
      else
        "qop=#{params['qop']}"
      end,
      "uri=\"#{uri.request_uri}\"",
      "nonce=\"#{params['nonce']}\"",
      "nc=#{'%08x' % @nonce_count}",
      "cnonce=\"#{@cnonce}\"",
      "response=\"#{Digest::MD5.hexdigest request_digest}\""
    ]

    header.join ', '
  end

  ##
  # Creates a client nonce value that is used across all requests based on the
  # current time.

  def make_cnonce
    Digest::MD5.hexdigest "%x" % (Time.now.to_i + rand(65535))
  end

end

