#!/usr/bin/env ruby

ApplicationModel.audited_transaction do
  mi_plan_sets = []
  change_to_sub_project = MiPlan::SubProject.find_by_name('MGPinterest')

  ['MGP Legacy'].each do |sub_project_name|
    sub_project = MiPlan::SubProject.find_by_name(sub_project_name)
    mi_plan_sets << MiPlan.find_all_by_sub_project_id(sub_project.id)
  end

  mi_plan_sets.each do |mi_plans|
    puts mi_plans.count
    mi_plans.each do |mi_plan|
      mi_plan.sub_project = change_to_sub_project
      if !mi_plan.sub_project.valid?
        puts 'error! sub_project could not be saved'
      else
        mi_plan.save!
      end
    end
  end
 # raise 'TEST'
end