class AddPhenotypeOnlyToMiPlan < ActiveRecord::Migration
  def self.up
    add_column :mi_plans, :phenotype_only, :boolean, :default => false
  end

  def self.down
    remove_column :mi_plans, :phenotype_only
  end
end
