# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111202105057) do

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "associated_id"
    t.string   "associated_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "audited_changes"
    t.integer  "version",         :default => 0
    t.string   "comment"
    t.string   "remote_address"
    t.datetime "created_at"
  end

  add_index "audits", ["associated_id", "associated_type"], :name => "associated_index"
  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
  add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
  add_index "audits", ["user_id", "user_type"], :name => "user_index"

  create_table "centres", :force => true do |t|
    t.string   "name",       :limit => 100, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "centres", ["name"], :name => "index_centres_on_name", :unique => true

  create_table "consortia", :force => true do |t|
    t.string   "name",         :null => false
    t.string   "funding"
    t.text     "participants"
    t.string   "contact"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "consortia", ["name"], :name => "index_consortia_on_name", :unique => true

  create_table "deposited_materials", :force => true do |t|
    t.string   "name",       :limit => 50, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deposited_materials", ["name"], :name => "index_deposited_materials_on_name", :unique => true

  create_table "es_cells", :force => true do |t|
    t.string   "name",                               :limit => 100, :null => false
    t.string   "allele_symbol_superscript_template", :limit => 75
    t.string   "allele_type",                        :limit => 1
    t.integer  "pipeline_id",                                       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "gene_id",                                           :null => false
    t.string   "parental_cell_line"
  end

  add_index "es_cells", ["name"], :name => "index_es_cells_on_name", :unique => true

  create_table "genes", :force => true do |t|
    t.string   "marker_symbol",                      :limit => 75, :null => false
    t.string   "mgi_accession_id",                   :limit => 40
    t.integer  "ikmc_projects_count"
    t.integer  "conditional_es_cells_count"
    t.integer  "non_conditional_es_cells_count"
    t.integer  "deletion_es_cells_count"
    t.integer  "other_targeted_mice_count"
    t.integer  "other_condtional_mice_count"
    t.integer  "mutation_published_as_lethal_count"
    t.integer  "publications_for_gene_count"
    t.integer  "go_annotations_for_gene_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "genes", ["marker_symbol"], :name => "index_genes_on_marker_symbol", :unique => true

  create_table "mi_attempt_status_stamps", :force => true do |t|
    t.integer  "mi_attempt_id",        :null => false
    t.integer  "mi_attempt_status_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mi_attempt_statuses", :force => true do |t|
    t.string   "description", :limit => 50, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mi_attempt_statuses", ["description"], :name => "index_mi_attempt_statuses_on_description", :unique => true

  create_table "mi_attempts", :force => true do |t|
    t.integer  "es_cell_id",                                                                        :null => false
    t.date     "mi_date",                                                                           :null => false
    t.integer  "mi_attempt_status_id",                                                              :null => false
    t.string   "colony_name",                                     :limit => 125
    t.integer  "distribution_centre_id"
    t.integer  "updated_by_id"
    t.integer  "deposited_material_id",                                                             :null => false
    t.integer  "blast_strain_id"
    t.integer  "total_blasts_injected"
    t.integer  "total_transferred"
    t.integer  "number_surrogates_receiving"
    t.integer  "total_pups_born"
    t.integer  "total_female_chimeras"
    t.integer  "total_male_chimeras"
    t.integer  "total_chimeras"
    t.integer  "number_of_males_with_0_to_39_percent_chimerism"
    t.integer  "number_of_males_with_40_to_79_percent_chimerism"
    t.integer  "number_of_males_with_80_to_99_percent_chimerism"
    t.integer  "number_of_males_with_100_percent_chimerism"
    t.boolean  "is_suitable_for_emma",                                           :default => false, :null => false
    t.boolean  "is_emma_sticky",                                                 :default => false, :null => false
    t.integer  "colony_background_strain_id"
    t.integer  "test_cross_strain_id"
    t.date     "date_chimeras_mated"
    t.integer  "number_of_chimera_matings_attempted"
    t.integer  "number_of_chimera_matings_successful"
    t.integer  "number_of_chimeras_with_glt_from_cct"
    t.integer  "number_of_chimeras_with_glt_from_genotyping"
    t.integer  "number_of_chimeras_with_0_to_9_percent_glt"
    t.integer  "number_of_chimeras_with_10_to_49_percent_glt"
    t.integer  "number_of_chimeras_with_50_to_99_percent_glt"
    t.integer  "number_of_chimeras_with_100_percent_glt"
    t.integer  "total_f1_mice_from_matings"
    t.integer  "number_of_cct_offspring"
    t.integer  "number_of_het_offspring"
    t.integer  "number_of_live_glt_offspring"
    t.string   "mouse_allele_type",                               :limit => 1
    t.integer  "qc_southern_blot_id"
    t.integer  "qc_five_prime_lr_pcr_id"
    t.integer  "qc_five_prime_cassette_integrity_id"
    t.integer  "qc_tv_backbone_assay_id"
    t.integer  "qc_neo_count_qpcr_id"
    t.integer  "qc_neo_sr_pcr_id"
    t.integer  "qc_loa_qpcr_id"
    t.integer  "qc_homozygous_loa_sr_pcr_id"
    t.integer  "qc_lacz_sr_pcr_id"
    t.integer  "qc_mutant_specific_sr_pcr_id"
    t.integer  "qc_loxp_confirmation_id"
    t.integer  "qc_three_prime_lr_pcr_id"
    t.boolean  "report_to_public",                                               :default => true,  :null => false
    t.boolean  "is_active",                                                      :default => true,  :null => false
    t.boolean  "is_released_from_genotyping",                                    :default => false, :null => false
    t.text     "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mi_plan_id",                                                                        :null => false
  end

  add_index "mi_attempts", ["colony_name"], :name => "index_mi_attempts_on_colony_name", :unique => true

  create_table "mi_plan_priorities", :force => true do |t|
    t.string   "name",        :limit => 10,  :null => false
    t.string   "description", :limit => 100
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mi_plan_priorities", ["name"], :name => "index_mi_plan_priorities_on_name", :unique => true

  create_table "mi_plan_status_stamps", :force => true do |t|
    t.integer  "mi_plan_id",        :null => false
    t.integer  "mi_plan_status_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mi_plan_statuses", :force => true do |t|
    t.string   "name",        :limit => 50, :null => false
    t.string   "description"
    t.integer  "order_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mi_plan_statuses", ["name"], :name => "index_mi_plan_statuses_on_name", :unique => true

  create_table "mi_plan_sub_projects", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mi_plans", :force => true do |t|
    t.integer  "gene_id",                        :null => false
    t.integer  "consortium_id",                  :null => false
    t.integer  "mi_plan_status_id",              :null => false
    t.integer  "mi_plan_priority_id",            :null => false
    t.integer  "production_centre_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "number_of_es_cells_starting_qc"
    t.integer  "number_of_es_cells_passing_qc"
    t.integer  "sub_project_id",                 :null => false
  end

  add_index "mi_plans", ["gene_id", "consortium_id", "production_centre_id"], :name => "mi_plan_logical_key", :unique => true

  create_table "pipelines", :force => true do |t|
    t.string   "name",        :limit => 50, :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pipelines", ["name"], :name => "index_pipelines_on_name", :unique => true

  create_table "qc_results", :force => true do |t|
    t.string   "description", :limit => 50, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "qc_results", ["description"], :name => "index_qc_results_on_description", :unique => true

  create_table "report_caches", :force => true do |t|
    t.text     "name",       :null => false
    t.text     "csv_data",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "report_caches", ["name"], :name => "index_report_caches_on_name", :unique => true

  create_table "strain_blast_strains", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "strain_blast_strains", ["id"], :name => "index_strain_blast_strains_on_id", :unique => true

  create_table "strain_colony_background_strains", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "strain_colony_background_strains", ["id"], :name => "index_strain_colony_background_strains_on_id", :unique => true

  create_table "strain_test_cross_strains", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "strain_test_cross_strains", ["id"], :name => "index_strain_test_cross_strains_on_id", :unique => true

  create_table "strains", :force => true do |t|
    t.string   "name",       :limit => 50, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "strains", ["name"], :name => "index_strains_on_name", :unique => true

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "",    :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "",    :null => false
    t.datetime "remember_created_at"
    t.integer  "production_centre_id",                                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.boolean  "is_contactable",                      :default => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

  add_foreign_key "es_cells", "genes", :name => "es_cells_gene_id_fk"
  add_foreign_key "es_cells", "pipelines", :name => "es_cells_pipeline_id_fk"

  add_foreign_key "mi_attempt_status_stamps", "mi_attempt_statuses", :name => "mi_attempt_status_stamps_mi_attempt_status_id_fk"
  add_foreign_key "mi_attempt_status_stamps", "mi_attempts", :name => "mi_attempt_status_stamps_mi_attempt_id_fk"

  add_foreign_key "mi_attempts", "centres", :name => "mi_attempts_distribution_centre_id_fk", :column => "distribution_centre_id"
  add_foreign_key "mi_attempts", "deposited_materials", :name => "mi_attempts_deposited_material_id_fk"
  add_foreign_key "mi_attempts", "es_cells", :name => "mi_attempts_es_cell_id_fk"
  add_foreign_key "mi_attempts", "mi_attempt_statuses", :name => "mi_attempts_mi_attempt_status_id_fk"
  add_foreign_key "mi_attempts", "mi_plans", :name => "mi_attempts_mi_plan_id_fk"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_five_prime_cassette_integrity_id_fk", :column => "qc_five_prime_cassette_integrity_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_five_prime_lr_pcr_id_fk", :column => "qc_five_prime_lr_pcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_homozygous_loa_sr_pcr_id_fk", :column => "qc_homozygous_loa_sr_pcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_lacz_sr_pcr_id_fk", :column => "qc_lacz_sr_pcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_loa_qpcr_id_fk", :column => "qc_loa_qpcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_loxp_confirmation_id_fk", :column => "qc_loxp_confirmation_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_mutant_specific_sr_pcr_id_fk", :column => "qc_mutant_specific_sr_pcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_neo_count_qpcr_id_fk", :column => "qc_neo_count_qpcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_neo_sr_pcr_id_fk", :column => "qc_neo_sr_pcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_southern_blot_id_fk", :column => "qc_southern_blot_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_three_prime_lr_pcr_id_fk", :column => "qc_three_prime_lr_pcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_tv_backbone_assay_id_fk", :column => "qc_tv_backbone_assay_id"
  add_foreign_key "mi_attempts", "strain_blast_strains", :name => "mi_attempts_blast_strain_id_fk", :column => "blast_strain_id"
  add_foreign_key "mi_attempts", "strain_colony_background_strains", :name => "mi_attempts_colony_background_strain_id_fk", :column => "colony_background_strain_id"
  add_foreign_key "mi_attempts", "strain_test_cross_strains", :name => "mi_attempts_test_cross_strain_id_fk", :column => "test_cross_strain_id"
  add_foreign_key "mi_attempts", "users", :name => "mi_attempts_updated_by_id_fk", :column => "updated_by_id"

  add_foreign_key "mi_plan_status_stamps", "mi_plan_statuses", :name => "mi_plan_status_stamps_mi_plan_status_id_fk"
  add_foreign_key "mi_plan_status_stamps", "mi_plans", :name => "mi_plan_status_stamps_mi_plan_id_fk"

  add_foreign_key "mi_plans", "centres", :name => "mi_plans_production_centre_id_fk", :column => "production_centre_id"
  add_foreign_key "mi_plans", "consortia", :name => "mi_plans_consortium_id_fk"
  add_foreign_key "mi_plans", "genes", :name => "mi_plans_gene_id_fk"
  add_foreign_key "mi_plans", "mi_plan_priorities", :name => "mi_plans_mi_plan_priority_id_fk"
  add_foreign_key "mi_plans", "mi_plan_statuses", :name => "mi_plans_mi_plan_status_id_fk"
  add_foreign_key "mi_plans", "mi_plan_sub_projects", :name => "mi_plans_sub_project_id_fk", :column => "sub_project_id"

  add_foreign_key "strain_blast_strains", "strains", :name => "strain_blast_strains_id_fk", :column => "id"

  add_foreign_key "strain_colony_background_strains", "strains", :name => "strain_colony_background_strains_id_fk", :column => "id"

  add_foreign_key "strain_test_cross_strains", "strains", :name => "strain_test_cross_strains_id_fk", :column => "id"

end
