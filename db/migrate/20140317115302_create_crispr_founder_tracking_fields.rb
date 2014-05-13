class CreateCrisprFounderTrackingFields < ActiveRecord::Migration

  def self.up
    add_column :mi_attempts, :crsp_total_embryos_injected, :integer
    add_column :mi_attempts, :crsp_total_embryos_survived, :integer
    add_column :mi_attempts, :crsp_total_transfered, :integer
    add_column :mi_attempts, :crsp_no_founder_pups, :integer

    add_column :mi_attempts, :founder_pcr_num_assays, :integer
    add_column :mi_attempts, :founder_pcr_num_positive_results, :integer
    add_column :mi_attempts, :founder_surveyor_num_assays, :integer
    add_column :mi_attempts, :founder_surveyor_num_positive_results, :integer
    add_column :mi_attempts, :founder_t7en1_num_assays, :integer
    add_column :mi_attempts, :founder_t7en1_num_positive_results, :integer

    add_column :mi_attempts, :crsp_total_num_mutant_founders, :integer
    add_column :mi_attempts, :crsp_num_founders_selected_for_breading, :integer
  end

  def self.down
    remove_column :mi_attempts, :crsp_total_embryos_injected
    remove_column :mi_attempts, :crsp_total_embryos_survived
    remove_column :mi_attempts, :crsp_total_transfered
    remove_column :mi_attempts, :crsp_no_founder_pups

    remove_column :mi_attempts, :founder_pcr_num_assays
    remove_column :mi_attempts, :founder_pcr_num_positive_results
    remove_column :mi_attempts, :founder_surveyor_num_assays
    remove_column :mi_attempts, :founder_surveyor_num_positive_results
    remove_column :mi_attempts, :founder_t7en1_num_assays
    remove_column :mi_attempts, :founder_t7en1_num_positive_results

    remove_column :mi_attempts, :crsp_total_num_mutant_founders
    remove_column :mi_attempts, :crsp_num_founders_selected_for_breading
  end
end
