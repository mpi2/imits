class AddMiPlanIdToPhenotypeAttempts < ActiveRecord::Migration
  def self.up
    add_column(:phenotype_attempts, :mi_plan_id, :integer, :null => false)
  end

  def self.down
    remove_column(:phenotype_attempts, :mi_plan_id)
  end
end
