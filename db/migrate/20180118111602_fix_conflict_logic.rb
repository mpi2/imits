class FixConflictLogic < ActiveRecord::Migration

  def self.up
    add_column :mi_plans, :es_cell_qc_only, :boolean, :default => false
    
    sql = ""
    unless MiPlan::Status.find_by_name('Assigned for phenotyping')
      sql << "INSERT INTO mi_plan_statuses (name, code, order_by, description) VALUES ('Assigned for phenotyping', 'asg-phen', 9, 'Assigned - A consortium/Centre has indicated their intention to only phenotype this gene'); "
    end
    unless MiPlan::Status.find_by_name('Inspect - Phenotype Conflict')
      sql << "INSERT INTO mi_plan_statuses (name, code, order_by, description) VALUES ('Inspect - Phenotype Conflict', 'ins-phen', 8, 'Inspect - A phenotype attempt has already been recorded in iMITS'); "
    end
    unless MiPlan::Status.find_by_name('Assigned for ES Cell QC')
      sql << "INSERT INTO mi_plan_statuses (name, code, order_by, description) VALUES ('Assigned for ES Cell QC', 'asg-es', 7, 'Assigned - A consortium/Centre has indicated their intention to only QC ES Cells'); " 
    end

    sql << <<-EOF

      UPDATE mi_plans SET number_of_es_cells_passing_qc = 0 WHERE mi_plans.status_id = 8 AND created_at < '2017/01/01';

      UPDATE mi_plans SET es_cell_qc_only = true WHERE mi_plans.id IN
        (SELECT p2.id 
          FROM mi_plans p2 LEFT JOIN mi_attempts ON mi_attempts.mi_plan_id = mi_plans.id 
          WHERE mi_attempts.id IS NULL AND mi_plans.status_id in (8, 9) AND mi_plans.created_at < '2017/01/01' AND mi_plans.phenotype_only = false);      

      UPDATE mi_plan_status_stamps.status_id = #{MiPlan::Status.find_by_name('Assigned for phenotyping').id } WHERE mi_plan_status_stamps.id =
        (SELECT ss.id
        FROM mi_plan_status_stamps ss JOIN mi_plans ON mi_plans.id = ss.mi_plan_id JOIN mi_plan_statuses ON mi_plan_statuses.id = ss.status_id
        WHERE mi_plans.phenotype_only = true AND mi_plan_statuses.code IN ('asg', 'ins-gtc', 'ins-mip', 'ins-con', 'con', 'int');

      UPDATE mi_plans.status_id = #{MiPlan::Status.find_by_name('Assigned for phenotyping').id }
        FROM mi_plan_statuses
        WHERE mi_plan_statuses.id = mi_plans.status_id AND mi_plans.phenotype_only = true AND mi_plan_statuses.code IN ('asg', 'ins-gtc', 'ins-mip', 'ins-con', 'con', 'int');;

      UPDATE mi_plan_status_stamps.status_id = #{MiPlan::Status.find_by_name('Assigned for ES Cell QC').id } WHERE mi_plan_status_stamps.id =
        (SELECT ss.id
        FROM mi_plan_status_stamps ss JOIN mi_plans ON mi_plans.id = ss.mi_plan_id JOIN mi_plan_statuses ON mi_plan_statuses.id = ss.status_id
        WHERE mi_plans.es_cell_qc_only = true AND mi_plans.phenotype_only = false AND mi_plan_statuses.code IN ('asg', 'ins-gtc', 'ins-mip', 'ins-con', 'con', 'int');

      INSERT INTO mi_plans_status_stamps (mi_plan_id, status_id, created_at, updated_at) 
        SELECT mi_plans.id, 10, '#{Time.now.to_s}', '#{Time.now.to_s}' FROM mi_plans WHERE mi_plans.number_of_es_cells_passing_qc = 0 AND mi_plans.status_id != 10

      UPDATE mi_plans SET status_id = 10 WHERE mi_plans.number_of_es_cells_passing_qc = 0 AND mi_plans.status_id != 10      
    EOF
  
    ActiveRecord::Base.connection.execute(sql)


  end

  def self.down
    remove_column :mi_plans, :es_cell_qc_only
  end

end
