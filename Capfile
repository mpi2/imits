load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

require 'bundler/capistrano'

load 'config/deploy'

set :stages, ["staging", "production"]
set :default_stage, "staging"
require "capistrano/ext/multistage"

require File.dirname(__FILE__) + '/config/deploy/natcmp.rb'
require File.dirname(__FILE__) + '/config/deploy/gitflow.rb'
