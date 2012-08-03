class AddAlleleTypesToMiPlans < ActiveRecord::Migration
  def self.up
    add_column :mi_plans, :is_conditional_allele, :boolean, :default => false, :null => false
    add_column :mi_plans, :is_deletion_allele, :boolean, :default => false, :null => false
    add_column :mi_plans, :is_cre_knock_in_allele, :boolean, :default => false, :null => false
    add_column :mi_plans, :is_cre_bac_allele, :boolean, :default => false, :null => false
    add_column :mi_plans, :comment, :text
  end

  def self.down
    remove_column :mi_plans, :is_conditional_allele
    remove_column :mi_plans, :is_deletion_allele
    remove_column :mi_plans, :is_cre_knock_in_allele
    remove_column :mi_plans, :is_cre_bac_allele
    remove_column :mi_plans, :comment
  end
end
