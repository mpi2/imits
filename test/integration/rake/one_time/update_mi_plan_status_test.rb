# encoding: utf-8

require 'test_helper'

module Rake 
  module OneTime
    
    # to test change #5330 which switches all appearances of 'Declined' to 'Inspect' in the mi_plan_status table
    
    class UpdateMiPlanStatusTest < ExternalScriptTestCase
            
        debug = false
        trace = debug ? '--trace' : ''

        should 'work' do

          MiPlan::Status.all(:order => 'id').each do |status|
            puts "BEFORE: #{status.id}: '#{status.name}': '#{status.description}'" if debug
          end

          puts "" if debug
         
          run_script "bundle exec rake one_time:update_mi_plan_status #{trace}"
          
          MiPlan::Status.reset_column_information
          
          MiPlan::Status.all(:order => 'id').each do |status|
            puts " AFTER: #{status.id}: '#{status.name}': '#{status.description}'" if debug
            assert ! status.name.match(/^Declined/), "Declined should be changed to Inspect in mi_plan_status.name!"
            assert ! status.description.match(/^Declined/), "Declined should be changed to Inspect in mi_plan_status.description!"
          end
          
      end
  
    end
  end
end
