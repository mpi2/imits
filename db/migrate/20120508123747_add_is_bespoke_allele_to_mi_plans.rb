class AddIsBespokeAlleleToMiPlans < ActiveRecord::Migration
  def self.up
    add_column :mi_plans, :is_bespoke_allele, :boolean
  end

  def self.down
    remove_column :is_bespoke_allele, :boolean
  end
end
