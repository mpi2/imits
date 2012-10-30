class TargRepCreateEsCellTable < ActiveRecord::Migration
  def self.up
    create_table "targ_rep_es_cells" do |t|
      t.integer  "allele_id",                          :null => false
      t.integer  "targeting_vector_id"
      t.string   "parental_cell_line"
      t.string   "allele_symbol_superscript",          :limit => 75
      t.string   "name",                               :limit => 100, :null => false
      t.string   "comment"
      t.string   "contact"
      t.string   "ikmc_project_id"
      t.string   "mgi_allele_id",                      :limit => 50
      t.integer  "pipeline_id"
      t.boolean  "report_to_public",                   :default => true, :null => false
      t.string   "strain",                             :limit => 25
      t.string   "production_qc_five_prime_screen"
      t.string   "production_qc_three_prime_screen"
      t.string   "production_qc_loxp_screen"
      t.string   "production_qc_loss_of_allele"
      t.string   "production_qc_vector_integrity"      
      t.string   "user_qc_map_test"
      t.string   "user_qc_karyotype"
      t.string   "user_qc_tv_backbone_assay"
      t.string   "user_qc_loxp_confirmation"
      t.string   "user_qc_southern_blot"
      t.string   "user_qc_loss_of_wt_allele"
      t.string   "user_qc_neo_count_qpcr"
      t.string   "user_qc_lacz_sr_pcr"
      t.string   "user_qc_mutant_specific_sr_pcr"
      t.string   "user_qc_five_prime_cassette_integrity"
      t.string   "user_qc_neo_sr_pcr"
      t.string   "user_qc_five_prime_lr_pcr"
      t.string   "user_qc_three_prime_lr_pcr"
      t.text     "user_qc_comment"

      ## From iMits
      t.string   "allele_type",                        :limit => 2
      t.string   "mutation_subtype",                   :limit => 100
      t.string   "allele_symbol_superscript_template", :limit => 75

      ## iMits ID for the migration
      t.integer  "legacy_id"

      t.timestamps
    end

  add_index "targ_rep_es_cells", ["allele_id"], :name => "es_cells_allele_id_fk"
  add_index "targ_rep_es_cells", ["name"], :name => "targ_rep_index_es_cells_on_name", :unique => true
  add_index "targ_rep_es_cells", ["pipeline_id"], :name => "es_cells_pipeline_id_fk"

  end

  def self.down
    drop_table "targ_rep_es_cells"
  end
end
