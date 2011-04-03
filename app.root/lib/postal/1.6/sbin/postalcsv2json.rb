#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
##
$:.unshift File.join([File.dirname($0),"..","lib"])

require 'csv'
require 'json'
require 'digest/sha1'

require 'optparse'
def option_parser
  ret = {
    :csv_file => "",
    :check_rev => false,
    :debug=>false,
  }
  OptionParser.new do |opts|
    opts.banner = <<-HELP

  Usage: #{File::basename($0)} [-c] ken_all.csv

  It reads each line from the postal code database ,named ken_all.csv, provided 
  by the Japan Postal Services and converts the line into a json format string.
HELP
    opts.separator ''
    opts.on('-c', '--check_rev', "Check the '_rev' fileld from DB for each data.") { |c|
      ret[:check_rev] = c
    }
    opts.on('-d', '--debug', 'Enable the debug mode') { |d|
      ret[:debug] = d
    }
    opts.on_tail('-h', '--help', 'Show this message') {
      $stderr.puts opts
      exit(1)
    }
    begin
      opts.parse!(ARGV)
      ret[:csv_file] = ARGV[0] if ARGV.length == 1
    rescue
      $stderr.puts opts
      $stderr.puts
      $stderr.puts "[error] #{$!}"
      exit(1)
    end

    if ret[:csv_file].empty?
      $stderr.puts opts
      exit(1)
    end
  end
  return ret
end

@opts = option_parser
@lsdoc = File::join([File::dirname($0),"..","utils","bin","lsdoc"])

CSV.open(ARGV[0], 'r').each do |row|
  entry = {}
  entry['type'] = "pcode"
  entry['x0401'] = row[0]
  entry['p'] = row[6]
  entry['pk'] = row[3]
  entry['c'] = row[7]
  entry['ck'] = row[4]
  entry['s'] = row[8]
  entry['sk'] = row[5]
  entry['code'] = row[2]
  entry['ocode'] = row[1].strip
  entry['codep'] = row[2][0,3]
  entry['codes'] = row[2][3,4]
  entry['op1'] = row[9]
  entry['op2'] = row[10]
  entry['op3'] = row[11]
  entry['op4'] = row[12]
  entry['op5'] = row[13]
  entry['op6'] = row[14]
  entry['_id'] = Digest::SHA1::hexdigest(row[0]+row[1]+row[2]+row[3]+row[4]+row[5]+row[6]+row[7]+row[8])

  begin
    if @opts[:check_rev]
      json = {}
      open("| #{@lsdoc} /postal2/#{entry['_id']}").each_line do |l|
        json = JSON::parse(l)
      end
      entry['_rev'] = json['_rev'] if json.has_key?('_rev')
    end
    $stdout.puts entry.to_json
  rescue
    $stderr.puts $! if @opts[:debug]
    exit(1)
  end
end

