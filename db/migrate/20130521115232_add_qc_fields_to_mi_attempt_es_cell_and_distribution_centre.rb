class AddQcFieldsToMiAttemptEsCellAndDistributionCentre < ActiveRecord::Migration
  def up
    add_column :mi_attempts, :qc_critical_region_qpcr_id, :integer
    add_column :mi_attempts, :qc_loxp_srpcr_id, :integer
    add_column :mi_attempts, :qc_loxp_srpcr_and_sequencing_id, :integer
    add_foreign_key :mi_attempts, :qc_results, :column => :qc_critical_region_qpcr_id
    add_foreign_key :mi_attempts, :qc_results, :column => :qc_loxp_srpcr_id
    add_foreign_key :mi_attempts, :qc_results, :column => :qc_loxp_srpcr_and_sequencing_id

    add_column :targ_rep_es_cells, :user_loxp_srpcr_and_sequencing, :string
    add_column :targ_rep_es_cells, :user_karyotype_spread, :string
    add_column :targ_rep_es_cells, :user_karyotype_pcr, :string
    add_column :targ_rep_es_cells, :user_mouse_clinic_id, :integer
    add_foreign_key :targ_rep_es_cells, :centres, :column => :user_mouse_clinic_id

    add_column :targ_rep_distribution_qcs, :loxp_srpcr, :string
    add_column :targ_rep_distribution_qcs, :unspecified_repository_testing, :boolean
  end

  def down
    remove_foreign_key :mi_attempts, :column => :qc_critical_region_qpcr_id
    remove_foreign_key :mi_attempts, :column => :qc_loxp_srpcr_id
    remove_foreign_key :mi_attempts, :column => :qc_loxp_srpcr_and_sequencing_id
    remove_column :mi_attempts, :qc_critical_region_qpcr_id
    remove_column :mi_attempts, :qc_loxp_srpcr_id
    remove_column :mi_attempts, :qc_loxp_srpcr_and_sequencing_id

    remove_foreign_key :targ_rep_es_cells, :column => :user_mouse_clinic_id
    remove_column :targ_rep_es_cells, :user_loxp_srpcr_and_sequencing
    remove_column :targ_rep_es_cells, :user_karyotype_spread
    remove_column :targ_rep_es_cells, :user_karyotype_pcr
    remove_column :targ_rep_es_cells, :user_mouse_clinic_id


    remove_column :targ_rep_distribution_qcs, :loxp_srpcr
    remove_column :targ_rep_distribution_qcs, :unspecified_repository_testing
  end
end
