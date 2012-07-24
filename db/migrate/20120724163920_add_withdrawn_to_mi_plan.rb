class AddWithdrawnToMiPlan < ActiveRecord::Migration
  def self.up
    add_column :mi_plans, :withdrawn, :boolean, :null => false, :default => false
    execute "UPDATE mi_plans SET withdrawn = 't' FROM mi_plans p INNER JOIN mi_plan_statuses ON mi_plan_statuses.id = p.status_id WHERE mi_plan_statuses.name = 'Withdrawn'"
  end

  def self.down
    remove_column :mi_plans, :withdrawn
  end
end
