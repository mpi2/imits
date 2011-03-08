load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

require 'bundler/capistrano'

load 'config/deploy' # remove this line to skip loading any of the default tasks

set :stages, ["staging", "production"]
set :default_stage, "staging"
require "capistrano/ext/multistage"

set :branch, 'sprint0004'

$: << File.dirname(__FILE__) # Make Rubygems-overriden 'require' method find things locally
require "config/deploy/natcmp.rb"
require "config/deploy/gitflow.rb"
