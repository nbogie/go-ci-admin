#!/usr/bin/env ruby
require File.dirname(__FILE__) + "/go_updater"
abort "$0 pipeline_name auth_file" unless ARGV.size == 2
pipeline_name=ARGV[0]
auth_file = ARGV[1] 

user="apiinternal"
secret=File.read(auth_file).chomp
updater = GoUpdater.new(user, secret)
updater.delete_pipeline(pipeline_name)
