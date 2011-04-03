# -*- coding: utf-8 -*-

module YALTools

  # == Description
  #
  # YALTools::JsonFormatter module provides a human readable fancy format.
  #
  # == Usage
  #
  #    hash = @couch.get("/_all_dbs")
  #    puts YALTools::JsonFormatter::parse(hash)
  #
  
  module JsonFormatter

    #
    # The +depth+ argument is used for an initial indent size.
    #
    # The +indent_unit+ argument is an indent string.
    #
    def parse(i, depth=0, indent_unit="  ")
      indent = indent_unit.to_s * depth.to_i
      msg = ""
      case i
      when Array
        msg += "[\n"
        max = i.size
        count = 1
        i.each do |c|
          msg += parse(c,depth+1, indent_unit)
          msg += ",\n" if max != count
          
          count += 1
        end
        msg += "\n#{indent}]"
      when Hash
        max = i.size
        count = 1
        msg += "#{indent}{\n"
        i.each do |k,v|
          msg += "#{indent_unit.to_s * (depth.to_i + 1)}#{indent}\"#{k}\":"
          msg += parse(v, depth+1, indent_unit)
          msg += "," if max != count
          msg += "\n"

          count += 1
        end
        msg += "#{indent}}"
      else
        msg += "#{indent}\"#{i}\""
      end
      return msg
    end
    module_function :parse
  end
end
