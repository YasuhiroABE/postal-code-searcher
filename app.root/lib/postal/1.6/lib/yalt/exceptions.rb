# -*- coding: utf-8 -*-
#
# == Description
# 
# The "exceptions.rb" defines exceptions using in YALTools.
#
# All exceptions should be a sub-class of RuntimeError.
# 

module YALTools
    
  # [name] LabelNotFoundError
  # [when] The given label name is not found on the yalt.yaml file.
  class LabelNotFoundError < RuntimeError ; end
  
  # [name] ServerConnectionError
  # [when] The "/" does not return the version information.
  class ServerConnectionError < RuntimeError ; end
end
