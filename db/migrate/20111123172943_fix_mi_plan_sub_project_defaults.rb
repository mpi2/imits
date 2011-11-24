class FixMiPlanSubProjectDefaults < ActiveRecord::Migration
  def self.up
    execute('update mi_plans set sub_project_id = 1')
    execute('alter table mi_plans alter column sub_project_id set not null')
  end

  def self.down
    execute('alter table mi_plans alter column sub_project_id drop not null')
  end
end
