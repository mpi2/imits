class ReindexMiPlanAddPhenotypeOnlyToUniqueRestraints < ActiveRecord::Migration
  def self.up
    remove_index :mi_plans, :name => :mi_plan_logical_key
    add_index :mi_plans, [:gene_id, :consortium_id, :production_centre_id, :sub_project_id, :is_bespoke_allele, :is_conditional_allele, :is_deletion_allele, :is_cre_knock_in_allele, :is_cre_bac_allele, :phenotype_only], :unique => true, :name => :mi_plan_logical_key
  end

  def self.down
    remove_index :mi_plans, :name => :mi_plan_logical_key
    add_index :mi_plans, [:gene_id, :consortium_id, :production_centre_id, :sub_project_id, :is_bespoke_allele, :is_conditional_allele, :is_deletion_allele, :is_cre_knock_in_allele, :is_cre_bac_allele], :unique => true, :name => :mi_plan_logical_key
  end
end
