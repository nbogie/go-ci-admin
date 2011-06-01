#!/usr/bin/env ruby

require File.dirname(__FILE__) + "/go_updater"

abort "$0 projectname branchname git_repo_url auth_file" unless ARGV.size == 4

#returns "hotfix", "rc", or "develop"
def determine_branch_type(branch)
  return branch if (branch.downcase == "develop")
  branch =~ /^([a-zA-Z]+)-/
  if $1 && (%w(rc hotfix).member? $1.downcase)
    return $1.downcase
  else
    raise "unrecognised branch prefix in '#{branch}'.  Should be hotfix or rc"
  end
end

project_name = ARGV[0]
branch       = ARGV[1] #this should be stripped of origin/
               # e.g. "hotfix-1.3.1" or "feature/zombies"
git_repo_url = ARGV[2] 
auth_file    = ARGV[3] 
branch_type=determine_branch_type(branch)

pipeline_name= "%s_%s" % [project_name, branch]

#TODO: Remove certain things from job names, such as / characters.

user="apiinternal"
secret=File.read(auth_file).chomp
updater = GoUpdater.new(user, secret)
updater.add_pipeline_for_branch(project_name, git_repo_url, branch, branch_type)

