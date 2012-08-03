class AddWithdrawnToMiPlans < ActiveRecord::Migration
  def self.up
    add_column :mi_plans, :withdrawn, :boolean, :null => false, :default => false
    execute "UPDATE mi_plans SET withdrawn = 't' FROM mi_plan_statuses " +
            "WHERE mi_plans.status_id = mi_plan_statuses.id " +
            "AND mi_plan_statuses.name = 'Withdrawn'"
  end

  def self.down
    remove_column :mi_plans, :withdrawn
  end
end
