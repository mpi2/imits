class FixMiPlanSubProjectDefaults < ActiveRecord::Migration
  def self.up
    #sub_project = MiPlan::SubProject.find_by_name!('')
    #
    #MiPlan.all.each do |mi_plan|
    #  begin
    #    mi_plan.sub_project = sub_project        
    #    mi_plan.save!
    #  rescue Exception => e
    #    e2 = RuntimeError.new("(#{e.class.name}): On\n\n#{mi_plan.to_json}\n\n#{e.message}")
    #    e2.set_backtrace(e.backtrace)
    #    raise e2
    #  end
    #end
    
#    execute("UPDATE mi_plans SET sub_project_id = mi_plan_sub_projects.id FROM mi_plan_sub_projects WHERE mi_plan_sub_projects.name = ''")
    execute("UPDATE mi_plans SET sub_project_id = 1")
    execute('alter table mi_plans alter column sub_project_id set not null')
  end

  def self.down
    execute('alter table mi_plans alter column sub_project_id drop not null')
#    execute('update mi_plans set sub_project_id = null')
  end
end
