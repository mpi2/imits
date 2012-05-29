# encoding: utf-8

#Task #8408

#There are a number of MI's which belong to MGP Legacy plans, which have mi_date >= June 1 2011 - these need to be moved to MGP
#(with subproject MGP interest).
#
#Solution is to
#(1) Identify the MIs (choose consortium = MGP Legacy and mi_date >= 1 June 2011
#(2) Make an MGP MI plan with subproject MGPInterest and
#(3) Move the MI to the new MI Plan.

#usage
#bundle exec  rake db:production:clone
#bundle exec rake db:migrate db:seed
#/script/runner script/scratch/mgp_consortium_change2.rb > script/scratch/mgp_consortium_change2.log

VERBOSE = false
EXPECTED_COUNT = 1059

puts "START: " + DateTime.now.to_s
puts "Environment: #{Rails.env.to_s}"

plans = MiPlan.find(:all, :conditions => {
  :sub_project_id => MiPlan::SubProject.find_by_name!('MGP Legacy'),
  :consortium_id => Consortium.find_by_name!('MGP Legacy')
})

raise "Expected #{EXPECTED_COUNT} rows - found #{plans.size} rows" if plans.size != EXPECTED_COUNT

sub_project = MiPlan::SubProject.find_by_name!('MGP Interest')

puts "\nsub_project: " + sub_project.inspect if VERBOSE

MiPlan.audited_transaction do

  plans.each do |plan|

    plan.mi_attempts.each do |attempt|

      if attempt.mi_date.to_date >= Date.parse('2011-06-01').to_date
        attempt.consortium_name = 'MGP'
        attempt.save!

        attempt.mi_plan.sub_project = sub_project
        attempt.mi_plan.save!

        puts "Attempt: #{attempt.id} - Old plan: #{plan.id} - New plan: #{attempt.mi_plan.id} - Attempts count: #{plan.mi_attempts.size} - Date: #{attempt.mi_date.to_date.to_s}"

        raise "Cannot change subproject!" if attempt.mi_plan.sub_project_id != sub_project.id
      end

    end

  end

end

puts "END: " + DateTime.now.to_s
puts "done!"
