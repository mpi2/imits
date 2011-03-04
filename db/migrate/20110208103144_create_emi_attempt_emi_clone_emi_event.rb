class CreateEmiAttemptEmiCloneEmiEvent < ActiveRecord::Migration

  def self.up
    raise 'Invalid environment' unless Rails.env.development? || Rails.env.test?

    create_table "emi_attempt" do |t|
      t.boolean  "is_active",                                      :precision => 1,  :scale => 0
      t.integer  "event_id",                                       :precision => 38, :scale => 0
      t.datetime "actual_mi_date"
      t.integer  "attempt_number",                                 :precision => 38, :scale => 0
      t.decimal  "num_recipients"
      t.string   "num_blasts",                     :limit => 4000
      t.datetime "created_date"
      t.decimal  "creator_id"
      t.datetime "edit_date"
      t.string   "edited_by",                      :limit => 128
      t.integer  "number_born",                                    :precision => 38, :scale => 0
      t.integer  "total_chimeras",                                 :precision => 38, :scale => 0
      t.integer  "number_male_chimeras",                           :precision => 38, :scale => 0
      t.integer  "number_female_chimeras",                         :precision => 38, :scale => 0
      t.datetime "date_chimera_mated"
      t.integer  "number_chimera_mated",                           :precision => 38, :scale => 0
      t.integer  "number_chimera_mating_success",                  :precision => 38, :scale => 0
      t.datetime "date_f1_genotype"
      t.integer  "number_male_100_percent",                        :precision => 38, :scale => 0
      t.integer  "number_male_gt_80_percent",                      :precision => 38, :scale => 0
      t.integer  "number_male_40_to_80_percent",                   :precision => 38, :scale => 0
      t.integer  "number_male_lt_40_percent",                      :precision => 38, :scale => 0
      t.integer  "number_with_glt",                                :precision => 38, :scale => 0
      t.string   "comments",                       :limit => 4000
      t.integer  "status_dict_id",                                 :precision => 38, :scale => 0
      t.decimal  "num_transferred"
      t.string   "number_with_cct",                :limit => 4000
      t.decimal  "total_f1_mice"
      t.string   "blast_strain",                   :limit => 4000
      t.decimal  "number_f0_matings"
      t.decimal  "f0_matings_with_offspring"
      t.integer  "f1_germ_line_mice",              :limit => 10,   :precision => 10, :scale => 0
      t.integer  "number_lt_10_percent_glt",       :limit => 10,   :precision => 10, :scale => 0
      t.integer  "number_btw_10_50_percent_glt",   :limit => 10,   :precision => 10, :scale => 0
      t.integer  "number_gt_50_percent_glt",       :limit => 10,   :precision => 10, :scale => 0
      t.integer  "number_het_offspring",           :limit => 10,   :precision => 10, :scale => 0
      t.integer  "number_100_percent_glt",         :limit => 10,   :precision => 10, :scale => 0
      t.string   "test_cross_strain",              :limit => 200
      t.integer  "chimeras_with_glt_from_cct",     :limit => 10,   :precision => 10, :scale => 0
      t.integer  "chimeras_with_glt_from_genotyp", :limit => 10,   :precision => 10, :scale => 0
      t.string   "colony_name",                    :limit => 100
      t.string   "europhenome",                    :limit => 1
      t.string   "emma",                           :limit => 1
      t.string   "mmrrc",                          :limit => 1
      t.integer  "number_live_glt_offspring",      :limit => 10,   :precision => 10, :scale => 0
      t.boolean  "is_emma_sticky",                                 :precision => 1,  :scale => 0
      t.string   "back_cross_strain",              :limit => 100
      t.string   "production_centre_mi_id",        :limit => 100
      t.integer  "f1_black",                       :limit => 10,   :precision => 10, :scale => 0
      t.integer  "f1_non_black",                   :limit => 10,   :precision => 10, :scale => 0
      t.string   "mouse_allele_name",              :limit => 100
      t.string   "qc_five_prime_lr_pcr",           :limit => 20
      t.string   "qc_three_prime_lr_pcr",          :limit => 20
      t.string   "qc_tv_backbone_assay",           :limit => 20
      t.string   "qc_loxp_confirmation",           :limit => 20
      t.string   "qc_southern_blot",               :limit => 20
      t.string   "qc_loa_qpcr",                    :limit => 20
      t.string   "qc_homozygous_loa_sr_pcr",       :limit => 20
      t.string   "qc_neo_count_qpcr",              :limit => 20
      t.string   "qc_lacz_sr_pcr",                 :limit => 20
      t.string   "qc_mutant_specific_sr_pcr",      :limit => 20
      t.string   "qc_five_prime_cass_integrity",   :limit => 20
      t.string   "qc_neo_sr_pcr",                  :limit => 20
    end

    create_table "emi_clone" do |t|
      t.string   "clone_name",                :limit => 128,                                 :null => false
      t.datetime "created_date"
      t.integer  "creator_id"
      t.datetime "edit_date"
      t.string   "edited_by",                 :limit => 128
      t.integer  "pipeline_id",                                                              :null => false
      t.string   "gene_symbol",               :limit => 256
      t.string   "allele_name",               :limit => 256
      t.string   "ensembl_id",                :limit => 20
      t.string   "otter_id",                  :limit => 20
      t.string   "target_exon",               :limit => 20
      t.integer  "design_id"
      t.integer  "design_instance_id"
      t.string   "recombineering_bac_strain", :limit => 4000
      t.string   "es_cell_line_type",         :limit => 4000
      t.string   "genotype_pass_level",       :limit => 4000
      t.string   "es_cell_strain",            :limit => 100
      t.string   "es_cell_line",              :limit => 100
      t.boolean  "customer_priority",                         :precision => 1,  :scale => 0
    end

    add_index "emi_clone", ["clone_name"], :unique => true

    create_table "emi_event" do |t|
      t.integer  "centre_id",                                                             :null => false
      t.integer  "clone_id",                                                              :null => false
      t.boolean  "is_interested_only"
      t.datetime "proposed_mi_date"
      t.integer "creator_id"
      t.datetime "created_date"
      t.datetime "edit_date"
      t.string   "edited_by",              :limit => 128
      t.string   "comments",               :limit => 4000
      t.boolean  "is_failed"
      t.integer  "distribution_centre_id"
    end

    add_index "emi_event", ["centre_id", "clone_id"], :unique => true

    add_foreign_key "emi_attempt", "event_id", "emi_event"

    add_foreign_key "emi_event", "clone_id", "emi_clone"
  end

  def self.down
    raise 'Unsupported'
  end
end
