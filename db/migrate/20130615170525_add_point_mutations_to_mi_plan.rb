class AddPointMutationsToMiPlan < ActiveRecord::Migration
  def up
    add_column :mi_plans, :point_mutation, :boolean, :default => false, :null => false
    add_column :mi_plans, :conditional_point_mutation, :boolean, :default => false, :null => false
    add_column :mi_plans, :allele_symbol_superscript, :text
  end

  def down
    remove_column :mi_plans, :point_mutation
    remove_column :mi_plans, :conditional_point_mutation
    remove_column :mi_plans, :allele_symbol_superscript
  end
end
