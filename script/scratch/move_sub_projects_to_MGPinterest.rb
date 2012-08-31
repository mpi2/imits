#!/usr/bin/env ruby

ApplicationModel.audited_transaction do

  sub_project = MiPlan::SubProject.find_by_name('MGP Legacy')
  change_to_sub_project = MiPlan::SubProject.find_by_name('MGPinterest')
  mi_plans = MiPlan.find_all_by_sub_project_id(sub_project.id)
  puts mi_plans.count
  mi_plans.each do |mi_plan|
    mi_plan.sub_project = change_to_sub_project
    if !mi_plan.sub_project.valid?
      puts 'error! sub_project could not be saved'
    else
      mi_plan.save!
    end
  end
  raise 'TEST'
end