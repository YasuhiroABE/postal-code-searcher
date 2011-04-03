# -*- coding: utf-8 -*-

module YALTools

  # == Description
  #
  # YALTools::ProcJson module is a collection of methods related to the JSON processing.
  #
  # In the future, each method will be migrated into corresponding class method.
  #

  module ProcJson

    # Please see the following example.
    #
    # select_value_from_json({"_id"=>"x", "_rev"=>"y", "name"=>"z"}, ["_id","name"]) #=> {"_id"=>"x","name"=>"z"}
    def select_value_from_json(json, labels)
      ret = {}
      labels.each do |label|
        ret[label] = json[label] if json.has_key?(label)
      end
      ret
    end
    module_function :select_value_from_json
    
    # Please see the following example.
    #
    # exclude_value_from_json({"_id"=>"x", "_rev"=>"y", "name"=>"z"}, ["_rev"]) #=> {"_id"=>"x","name"=>"z"}
    def exclude_value_from_json(json, labels)
      ret = {}
      json.each do |k,v|
        ret[k] = v
        ret.delete(k) if labels.index(k.to_s) != nil
      end
      return ret
    end
    module_function :exclude_value_from_json
    
    # returns true or false.
    # If the +json+ contains the +pattern+ sequence, then it returns true.
    # === Examples
    #
    #   grep_json_p({"k1"=>{"k2"=>{"K3"=>"value"}}}, ["k1","k2"], false, false) #=> true
    #   grep_json_p({"k1"=>{"k2"=>{"K3"=>"value"}}}, ["k1","k2","K3","value"], false, false) #=> true
    #
    #   grep_json_p({"k1"=>{"k2"=>{"K3"=>"value"}}}, ["k1","k2","k3"], false, false) #=> false
    #
    #   grep_json_p({"k1"=>{"k2"=>{"K3"=>"value"}}}, ["k1","k2","k3"], true, false) #=> true
    #   grep_json_p({"k1"=>{"k2"=>{"K3"=>"value"}}}, ["k1","k2","k3"], false, true) #=> true
    #
    #   grep_json_p({"k1"=>{"k2"=>{"K3"=>"value"}}}, ["k1","k2","^K"], true, true) #=> true
    # 
    def grep_json_p(json, pattern, regexp_flag, ignore_case_flag)
      ret = false
      go_next = true
      rest_json = {}
      pat  = (pattern != nil) ? pattern.shift : nil
      ks = json.kind_of?(Hash) ? json.keys : [json]  ## [json] means the leaf of json tree.

      ## check the pattern
      case regexp_flag
      when true
        ks.each do |k|
          case ignore_case_flag
          when true
            if k =~ /#{pat}/i
              ret = true
              rest_json = json[k]
            end
          when false
            if k =~ /#{pat}/
              ret = true 
              rest_json = json[k]
            end
          end
        end
      when false
        case ignore_case_flag
        when true
          ks.each do |k|
            if k.upcase == pat.upcase
              ret = true
              rest_json = json[k]
            end
          end
        when false
          if ks.index(pat) != nil
            ret = true
            rest_json = json[pat]
          end
        end
      end
      
      return ret if pattern == []

      if json.kind_of?(Hash)
        ret = grep_json_p(rest_json, pattern, regexp_flag, ignore_case_flag)
      else
        ret = false
      end
      return ret
    end
    module_function :grep_json_p

    # returns true or false.
    #
    # It is a wrapper method against the +grep_json_p+ method.
    # This method handles the multiple patterns as +pattern_list+.
    #
    def grep_json(json, pattern_list, regexp_flag, ignore_case_flag)
      ret = false
      ret_flags = Array.new(pattern_list.size).map do |i| false ; end
      pattern_list.each_index do |i|
        ret_flags[i] = grep_json_p(json.clone, pattern_list[i].clone, regexp_flag, ignore_case_flag)
      end
      ret = true if ret_flags.index(false) == nil
      return ret
    end
    module_function :grep_json
  end
end
