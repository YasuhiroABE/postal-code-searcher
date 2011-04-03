# -*- coding: utf-8 -*-
# == Description
#
# YALTools is the top level module which is developed by Yasuhiro ABE.
#
# Please refer each page of classes and modules.
#
# http://lscouchdb.sourceforge.net/images/lscouchdb.class_diagram.png
#
# == License
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
#

module YALTools
  require "date"
  require "json"
  require "uri"
  require "yaml"
  require "couchdb"

  require "yalt/exceptions"
  require "yalt/main"
  require "yalt/mainwrapper"
  require "yalt/crypt"
  require "yalt/procjson"
  require "yalt/cmdline"
  require "yalt/jsonrows"
  require "yalt/formatter"
  require "yalt/yaview"
end

