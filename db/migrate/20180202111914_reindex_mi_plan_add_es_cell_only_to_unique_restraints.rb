class ReindexMiPlanAddEsCellOnlyToUniqueRestraints < ActiveRecord::Migration
  def self.up
    remove_index :mi_plans, :name => :mi_plan_logical_key
    add_index :mi_plans, [:gene_id, :consortium_id, :production_centre_id, :sub_project_id, :is_bespoke_allele, :is_conditional_allele, :is_deletion_allele, :is_cre_knock_in_allele, :is_cre_bac_allele, :conditional_tm1c, :phenotype_only, :mutagenesis_via_crispr_cas9, :es_cell_qc_only], :unique => true, :name => :mi_plan_logical_key
  end

  def self.down
    remove_index :mi_plans, :name => :mi_plan_logical_key
    add_index :mi_plans, [:gene_id, :consortium_id, :production_centre_id, :sub_project_id, :is_bespoke_allele, :is_conditional_allele, :is_deletion_allele, :is_cre_knock_in_allele, :is_cre_bac_allele, :conditional_tm1c, :phenotype_only, :mutagenesis_via_crispr_cas9], :unique => true, :name => :mi_plan_logical_key
  end
end
