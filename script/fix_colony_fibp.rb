#!/usr/bin/env ruby

#- find the MI for colony MFQK (gene Fibp)
#- find its MI Plan
#- alter the consortium for that particular plan from BaSH to MGP
#- set a subproject code for that particular plan to MGP Interest.

consortia = {:from => 'BaSH', :to => 'MGP'}
sub_project = {:from => 'MGPinterest', :to => 'MGPinterest'}

require 'pp'

marker_symbol = 'Fibp'
colony_name = 'MFQK'

puts "#### env: #{Rails.env}"

ApplicationModel.audited_transaction do

  mi_attempts = MiAttempt.find_all_by_colony_name colony_name

  raise "#### mi_attempts.size: #{mi_attempts.size}" if mi_attempts.size != 1

  mi_attempt = mi_attempts[0]

  raise "#### mi_attempt.mi_plan.gene.marker_symbol: #{mi_attempt.mi_plan.gene.marker_symbol}" if mi_attempt.mi_plan.gene.marker_symbol != marker_symbol

  if mi_attempt.mi_plan.consortium.name == consortia[:to] && mi_attempt.mi_plan.sub_project.name == sub_project[:to]
    puts "#### already done!"
    exit
  end

  mi_plan = mi_attempt.mi_plan

  mgp_legacy_consortium = Consortium.find_by_name consortia[:to]
  mi_plan.consortium = mgp_legacy_consortium

  mgp_legacy_sub_project = MiPlan::SubProject.find_by_name sub_project[:to]
  mi_plan.sub_project = mgp_legacy_sub_project

  mi_plan.save!

  mi_attempt.reload

  raise "error in mi_attempt.mi_plan.consortium #{mi_attempt.mi_plan.consortium.name}" if mi_attempt.mi_plan.consortium.name != mgp_legacy_consortium.name
  raise "error in mi_attempt.mi_plan.sub_project #{mi_attempt.mi_plan.sub_project.name}" if mi_attempt.mi_plan.sub_project.name != mgp_legacy_sub_project.name
end

puts "done!"

