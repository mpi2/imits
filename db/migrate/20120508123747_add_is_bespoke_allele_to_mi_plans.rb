class AddIsBespokeAlleleToMiPlans < ActiveRecord::Migration
  def self.up
    add_column :mi_plans, :is_bespoke_allele, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :mi_plans, :is_bespoke_allele
  end
end
