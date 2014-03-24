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

ActiveRecord::Schema.define(:version => 20140318095417) do

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
    t.string   "name",          :limit => 100, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "contact_name",  :limit => 100
    t.string   "contact_email", :limit => 100
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

  create_table "contacts", :force => true do |t|
    t.string   "email",                              :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "report_to_public", :default => true
  end

  add_index "contacts", ["email"], :name => "index_contacts_on_email", :unique => true

  create_table "deleter_strains", :force => true do |t|
    t.string   "name",       :limit => 100, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deposited_materials", :force => true do |t|
    t.string   "name",       :limit => 50, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deposited_materials", ["name"], :name => "index_deposited_materials_on_name", :unique => true

  create_table "email_templates", :force => true do |t|
    t.string   "status"
    t.text     "welcome_body"
    t.text     "update_body"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "es_cells", :force => true do |t|
    t.string   "name",                               :limit => 100, :null => false
    t.string   "allele_symbol_superscript_template", :limit => 75
    t.string   "allele_type",                        :limit => 2
    t.integer  "pipeline_id",                                       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "gene_id",                                           :null => false
    t.string   "parental_cell_line"
    t.string   "ikmc_project_id",                    :limit => 100
    t.string   "mutation_subtype",                   :limit => 100
    t.integer  "allele_id",                                         :null => false
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
    t.string   "chr",                                :limit => 2
    t.integer  "start_coordinates"
    t.integer  "end_coordinates"
    t.string   "strand_name"
    t.string   "vega_ids"
    t.string   "ncbi_ids"
    t.string   "ensembl_ids"
    t.string   "ccds_ids"
    t.string   "marker_type"
  end

  add_index "genes", ["marker_symbol"], :name => "index_genes_on_marker_symbol", :unique => true
  add_index "genes", ["mgi_accession_id"], :name => "index_genes_on_mgi_accession_id", :unique => true

  create_table "intermediate_report", :force => true do |t|
    t.string   "consortium",                                                  :null => false
    t.string   "sub_project",                                                 :null => false
    t.string   "priority"
    t.string   "production_centre",                                           :null => false
    t.string   "gene",                                         :limit => 75,  :null => false
    t.string   "mgi_accession_id",                             :limit => 40
    t.string   "overall_status",                               :limit => 50
    t.string   "mi_plan_status",                               :limit => 50
    t.string   "mi_attempt_status",                            :limit => 50
    t.string   "phenotype_attempt_status",                     :limit => 50
    t.string   "ikmc_project_id"
    t.string   "mutation_sub_type",                            :limit => 100
    t.string   "allele_symbol",                                               :null => false
    t.string   "genetic_background",                                          :null => false
    t.date     "assigned_date"
    t.date     "assigned_es_cell_qc_in_progress_date"
    t.date     "assigned_es_cell_qc_complete_date"
    t.date     "micro_injection_in_progress_date"
    t.date     "chimeras_obtained_date"
    t.date     "genotype_confirmed_date"
    t.date     "micro_injection_aborted_date"
    t.date     "phenotype_attempt_registered_date"
    t.date     "rederivation_started_date"
    t.date     "rederivation_complete_date"
    t.date     "cre_excision_started_date"
    t.date     "cre_excision_complete_date"
    t.date     "phenotyping_started_date"
    t.date     "phenotyping_complete_date"
    t.date     "phenotype_attempt_aborted_date"
    t.integer  "distinct_genotype_confirmed_es_cells"
    t.integer  "distinct_old_non_genotype_confirmed_es_cells"
    t.integer  "mi_plan_id",                                                  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "total_pipeline_efficiency_gene_count"
    t.integer  "gc_pipeline_efficiency_gene_count"
    t.boolean  "is_bespoke_allele"
    t.date     "aborted_es_cell_qc_failed_date"
    t.string   "mi_attempt_colony_name"
    t.string   "mi_attempt_consortium"
    t.string   "mi_attempt_production_centre"
    t.string   "phenotype_attempt_colony_name"
  end

  create_table "mi_attempt_distribution_centres", :force => true do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "mi_attempt_id",                             :null => false
    t.integer  "deposited_material_id",                     :null => false
    t.integer  "centre_id",                                 :null => false
    t.boolean  "is_distributed_by_emma", :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "distribution_network"
  end

  create_table "mi_attempt_status_stamps", :force => true do |t|
    t.integer  "mi_attempt_id", :null => false
    t.integer  "status_id",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mi_attempt_status_stamps", ["status_id", "mi_attempt_id"], :name => "index_one_status_stamp_per_status_and_mi_attempt", :unique => true

  create_table "mi_attempt_statuses", :force => true do |t|
    t.string   "name",       :limit => 50, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_by"
    t.string   "code",       :limit => 10, :null => false
  end

  add_index "mi_attempt_statuses", ["name"], :name => "index_mi_attempt_statuses_on_name", :unique => true

  create_table "mi_attempts", :force => true do |t|
    t.integer  "es_cell_id"
    t.date     "mi_date",                                                                           :null => false
    t.integer  "status_id",                                                                         :null => false
    t.string   "colony_name",                                     :limit => 125
    t.integer  "updated_by_id"
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
    t.string   "mouse_allele_type",                               :limit => 3
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
    t.string   "genotyping_comment",                              :limit => 512
    t.integer  "legacy_es_cell_id"
    t.integer  "qc_lacz_count_qpcr_id",                                          :default => 1
    t.integer  "qc_critical_region_qpcr_id",                                     :default => 1
    t.integer  "qc_loxp_srpcr_id",                                               :default => 1
    t.integer  "qc_loxp_srpcr_and_sequencing_id",                                :default => 1
    t.date     "cassette_transmission_verified"
    t.boolean  "cassette_transmission_verified_auto_complete"
    t.integer  "mutagenesis_factor_id"
    t.integer  "crsp_total_embryos_injected"
    t.integer  "crsp_total_embryos_survived"
    t.integer  "crsp_total_transfered"
    t.integer  "crsp_no_founder_pups"
    t.integer  "founder_pcr_num_assays"
    t.integer  "founder_pcr_num_positive_results"
    t.integer  "founder_surveyor_num_assays"
    t.integer  "founder_surveyor_num_positive_results"
    t.integer  "founder_t7en1_num_assays"
    t.integer  "founder_t7en1_num_positive_results"
    t.integer  "crsp_total_num_mutant_founders"
    t.integer  "crsp_num_founders_selected_for_breading"
  end

  add_index "mi_attempts", ["colony_name"], :name => "index_mi_attempts_on_colony_name", :unique => true

  create_table "mi_plan_es_cell_qcs", :force => true do |t|
    t.integer  "number_starting_qc"
    t.integer  "number_passing_qc"
    t.integer  "mi_plan_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "mi_plan_es_qc_comments", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mi_plan_es_qc_comments", ["name"], :name => "index_mi_plan_es_qc_comments_on_name", :unique => true

  create_table "mi_plan_priorities", :force => true do |t|
    t.string   "name",        :limit => 10,  :null => false
    t.string   "description", :limit => 100
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mi_plan_priorities", ["name"], :name => "index_mi_plan_priorities_on_name", :unique => true

  create_table "mi_plan_status_stamps", :force => true do |t|
    t.integer  "mi_plan_id", :null => false
    t.integer  "status_id",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mi_plan_status_stamps", ["status_id", "mi_plan_id"], :name => "index_one_status_stamp_per_status_and_mi_plan", :unique => true

  create_table "mi_plan_statuses", :force => true do |t|
    t.string   "name",        :limit => 50, :null => false
    t.string   "description"
    t.integer  "order_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "code",        :limit => 10, :null => false
  end

  add_index "mi_plan_statuses", ["name"], :name => "index_mi_plan_statuses_on_name", :unique => true

  create_table "mi_plan_sub_projects", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mi_plans", :force => true do |t|
    t.integer  "gene_id",                                                          :null => false
    t.integer  "consortium_id",                                                    :null => false
    t.integer  "status_id",                                                        :null => false
    t.integer  "priority_id",                                                      :null => false
    t.integer  "production_centre_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "number_of_es_cells_starting_qc"
    t.integer  "number_of_es_cells_passing_qc"
    t.integer  "sub_project_id",                                                   :null => false
    t.boolean  "is_active",                                     :default => true,  :null => false
    t.boolean  "is_bespoke_allele",                             :default => false, :null => false
    t.boolean  "is_conditional_allele",                         :default => false, :null => false
    t.boolean  "is_deletion_allele",                            :default => false, :null => false
    t.boolean  "is_cre_knock_in_allele",                        :default => false, :null => false
    t.boolean  "is_cre_bac_allele",                             :default => false, :null => false
    t.text     "comment"
    t.boolean  "withdrawn",                                     :default => false, :null => false
    t.integer  "es_qc_comment_id"
    t.boolean  "phenotype_only",                                :default => false
    t.string   "completion_note",                :limit => 100
    t.boolean  "recovery"
    t.boolean  "conditional_tm1c",                              :default => false, :null => false
    t.boolean  "ignore_available_mice",                         :default => false, :null => false
    t.integer  "number_of_es_cells_received"
    t.date     "es_cells_received_on"
    t.integer  "es_cells_received_from_id"
    t.boolean  "point_mutation",                                :default => false, :null => false
    t.boolean  "conditional_point_mutation",                    :default => false, :null => false
    t.text     "allele_symbol_superscript"
    t.boolean  "report_to_public",                              :default => true,  :null => false
    t.text     "completion_comment"
    t.boolean  "mutagenesis_via_crispr_cas9",                   :default => false
  end

  add_index "mi_plans", ["gene_id", "consortium_id", "production_centre_id", "sub_project_id", "is_bespoke_allele", "is_conditional_allele", "is_deletion_allele", "is_cre_knock_in_allele", "is_cre_bac_allele", "conditional_tm1c", "phenotype_only", "mutagenesis_via_crispr_cas9"], :name => "mi_plan_logical_key", :unique => true

  create_table "mutagenesis_factors", :force => true do |t|
    t.integer "vector_id"
  end

  create_table "new_consortia_intermediate_report", :force => true do |t|
    t.string   "gene",                                             :limit => 75,  :null => false
    t.string   "consortium",                                                      :null => false
    t.date     "gene_interest_date"
    t.string   "production_centre"
    t.string   "mgi_accession_id",                                 :limit => 40
    t.string   "overall_status",                                   :limit => 50
    t.string   "mi_plan_status",                                   :limit => 50
    t.string   "mi_attempt_status",                                :limit => 50
    t.string   "phenotype_attempt_status",                         :limit => 50
    t.integer  "mi_plan_id"
    t.integer  "mi_attempt_id"
    t.integer  "phenotype_attempt_id"
    t.date     "assigned_date"
    t.date     "assigned_es_cell_qc_in_progress_date"
    t.date     "assigned_es_cell_qc_complete_date"
    t.date     "aborted_es_cell_qc_failed_date"
    t.string   "sub_project"
    t.string   "priority"
    t.boolean  "is_bespoke_allele"
    t.string   "ikmc_project_id"
    t.string   "mutation_sub_type",                                :limit => 100
    t.string   "allele_symbol"
    t.string   "genetic_background"
    t.string   "mi_attempt_colony_name"
    t.string   "mi_attempt_consortium"
    t.string   "mi_attempt_production_centre"
    t.string   "phenotype_attempt_colony_name"
    t.date     "micro_injection_in_progress_date"
    t.date     "chimeras_obtained_date"
    t.date     "genotype_confirmed_date"
    t.date     "micro_injection_aborted_date"
    t.date     "phenotype_attempt_registered_date"
    t.date     "rederivation_started_date"
    t.date     "rederivation_complete_date"
    t.date     "cre_excision_started_date"
    t.date     "cre_excision_complete_date"
    t.date     "phenotyping_started_date"
    t.date     "phenotyping_complete_date"
    t.date     "phenotype_attempt_aborted_date"
    t.integer  "distinct_genotype_confirmed_es_cells"
    t.integer  "distinct_old_genotype_confirmed_es_cells"
    t.integer  "distinct_non_genotype_confirmed_es_cells"
    t.integer  "distinct_old_non_genotype_confirmed_es_cells"
    t.integer  "total_pipeline_efficiency_gene_count"
    t.integer  "total_old_pipeline_efficiency_gene_count"
    t.integer  "gc_pipeline_efficiency_gene_count"
    t.integer  "gc_old_pipeline_efficiency_gene_count"
    t.datetime "created_at"
    t.string   "non_cre_ex_phenotype_attempt_status"
    t.date     "non_cre_ex_phenotype_attempt_registered_date"
    t.date     "non_cre_ex_rederivation_started_date"
    t.date     "non_cre_ex_rederivation_complete_date"
    t.date     "non_cre_ex_cre_excision_started_date"
    t.date     "non_cre_ex_cre_excision_complete_date"
    t.date     "non_cre_ex_phenotyping_started_date"
    t.date     "non_cre_ex_phenotyping_complete_date"
    t.date     "non_cre_ex_phenotype_attempt_aborted_date"
    t.string   "non_cre_ex_pa_mouse_allele_type"
    t.string   "non_cre_ex_pa_allele_symbol_superscript_template"
    t.string   "non_cre_ex_pa_allele_symbol_superscript"
    t.string   "non_cre_ex_mi_attempt_consortium"
    t.string   "non_cre_ex_mi_attempt_production_centre"
    t.string   "non_cre_ex_phenotype_attempt_colony_name"
    t.string   "cre_ex_phenotype_attempt_status"
    t.date     "cre_ex_phenotype_attempt_registered_date"
    t.date     "cre_ex_rederivation_started_date"
    t.date     "cre_ex_rederivation_complete_date"
    t.date     "cre_ex_cre_excision_started_date"
    t.date     "cre_ex_cre_excision_complete_date"
    t.date     "cre_ex_phenotyping_started_date"
    t.date     "cre_ex_phenotyping_complete_date"
    t.date     "cre_ex_phenotype_attempt_aborted_date"
    t.string   "cre_ex_pa_mouse_allele_type"
    t.string   "cre_ex_pa_allele_symbol_superscript_template"
    t.string   "cre_ex_pa_allele_symbol_superscript"
    t.string   "cre_ex_mi_attempt_consortium"
    t.string   "cre_ex_mi_attempt_production_centre"
    t.string   "cre_ex_phenotype_attempt_colony_name"
    t.date     "phenotyping_experiments_started_date"
    t.date     "non_cre_ex_phenotyping_experiments_started_date"
    t.date     "cre_ex_phenotyping_experiments_started_date"
  end

  create_table "new_gene_intermediate_report", :force => true do |t|
    t.string   "gene",                                             :limit => 75,  :null => false
    t.string   "consortium",                                                      :null => false
    t.date     "gene_interest_date"
    t.string   "production_centre"
    t.string   "mgi_accession_id",                                 :limit => 40
    t.string   "overall_status",                                   :limit => 50
    t.string   "mi_plan_status",                                   :limit => 50
    t.string   "mi_attempt_status",                                :limit => 50
    t.string   "phenotype_attempt_status",                         :limit => 50
    t.integer  "mi_plan_id"
    t.integer  "mi_attempt_id"
    t.integer  "phenotype_attempt_id"
    t.date     "assigned_date"
    t.date     "assigned_es_cell_qc_in_progress_date"
    t.date     "assigned_es_cell_qc_complete_date"
    t.date     "aborted_es_cell_qc_failed_date"
    t.string   "sub_project"
    t.string   "priority"
    t.boolean  "is_bespoke_allele"
    t.string   "ikmc_project_id"
    t.string   "mutation_sub_type",                                :limit => 100
    t.string   "allele_symbol"
    t.string   "genetic_background"
    t.string   "mi_attempt_colony_name"
    t.string   "mi_attempt_consortium"
    t.string   "mi_attempt_production_centre"
    t.string   "phenotype_attempt_colony_name"
    t.date     "micro_injection_in_progress_date"
    t.date     "chimeras_obtained_date"
    t.date     "genotype_confirmed_date"
    t.date     "micro_injection_aborted_date"
    t.date     "phenotype_attempt_registered_date"
    t.date     "rederivation_started_date"
    t.date     "rederivation_complete_date"
    t.date     "cre_excision_started_date"
    t.date     "cre_excision_complete_date"
    t.date     "phenotyping_started_date"
    t.date     "phenotyping_complete_date"
    t.date     "phenotype_attempt_aborted_date"
    t.integer  "distinct_genotype_confirmed_es_cells"
    t.integer  "distinct_old_genotype_confirmed_es_cells"
    t.integer  "distinct_non_genotype_confirmed_es_cells"
    t.integer  "distinct_old_non_genotype_confirmed_es_cells"
    t.integer  "total_pipeline_efficiency_gene_count"
    t.integer  "total_old_pipeline_efficiency_gene_count"
    t.integer  "gc_pipeline_efficiency_gene_count"
    t.integer  "gc_old_pipeline_efficiency_gene_count"
    t.integer  "most_advanced_mi_plan_id_by_consortia"
    t.integer  "most_advanced_mi_attempt_id_by_consortia"
    t.integer  "most_advanced_phenotype_attempt_id_by_consortia"
    t.datetime "created_at"
    t.string   "non_cre_ex_phenotype_attempt_status"
    t.date     "non_cre_ex_phenotype_attempt_registered_date"
    t.date     "non_cre_ex_rederivation_started_date"
    t.date     "non_cre_ex_rederivation_complete_date"
    t.date     "non_cre_ex_cre_excision_started_date"
    t.date     "non_cre_ex_cre_excision_complete_date"
    t.date     "non_cre_ex_phenotyping_started_date"
    t.date     "non_cre_ex_phenotyping_complete_date"
    t.date     "non_cre_ex_phenotype_attempt_aborted_date"
    t.string   "non_cre_ex_pa_mouse_allele_type"
    t.string   "non_cre_ex_pa_allele_symbol_superscript_template"
    t.string   "non_cre_ex_pa_allele_symbol_superscript"
    t.string   "non_cre_ex_mi_attempt_consortium"
    t.string   "non_cre_ex_mi_attempt_production_centre"
    t.string   "non_cre_ex_phenotype_attempt_colony_name"
    t.string   "cre_ex_phenotype_attempt_status"
    t.date     "cre_ex_phenotype_attempt_registered_date"
    t.date     "cre_ex_rederivation_started_date"
    t.date     "cre_ex_rederivation_complete_date"
    t.date     "cre_ex_cre_excision_started_date"
    t.date     "cre_ex_cre_excision_complete_date"
    t.date     "cre_ex_phenotyping_started_date"
    t.date     "cre_ex_phenotyping_complete_date"
    t.date     "cre_ex_phenotype_attempt_aborted_date"
    t.string   "cre_ex_pa_mouse_allele_type"
    t.string   "cre_ex_pa_allele_symbol_superscript_template"
    t.string   "cre_ex_pa_allele_symbol_superscript"
    t.string   "cre_ex_mi_attempt_consortium"
    t.string   "cre_ex_mi_attempt_production_centre"
    t.string   "cre_ex_phenotype_attempt_colony_name"
    t.date     "phenotyping_experiments_started_date"
    t.date     "non_cre_ex_phenotyping_experiments_started_date"
    t.date     "cre_ex_phenotyping_experiments_started_date"
  end

  create_table "new_intermediate_report", :force => true do |t|
    t.string   "gene",                                             :limit => 75,                     :null => false
    t.integer  "mi_plan_id",                                                                         :null => false
    t.string   "consortium",                                                                         :null => false
    t.string   "production_centre"
    t.string   "sub_project"
    t.string   "priority"
    t.string   "mgi_accession_id",                                 :limit => 40
    t.string   "overall_status",                                   :limit => 50
    t.string   "mi_plan_status",                                   :limit => 50
    t.string   "mi_attempt_status",                                :limit => 50
    t.string   "phenotype_attempt_status",                         :limit => 50
    t.string   "ikmc_project_id"
    t.string   "mutation_sub_type",                                :limit => 100
    t.string   "allele_symbol"
    t.string   "genetic_background"
    t.boolean  "is_bespoke_allele"
    t.string   "mi_attempt_colony_name"
    t.string   "mi_attempt_consortium"
    t.string   "mi_attempt_production_centre"
    t.string   "phenotype_attempt_colony_name"
    t.date     "assigned_date"
    t.date     "assigned_es_cell_qc_in_progress_date"
    t.date     "assigned_es_cell_qc_complete_date"
    t.date     "aborted_es_cell_qc_failed_date"
    t.date     "micro_injection_in_progress_date"
    t.date     "chimeras_obtained_date"
    t.date     "genotype_confirmed_date"
    t.date     "micro_injection_aborted_date"
    t.date     "phenotype_attempt_registered_date"
    t.date     "rederivation_started_date"
    t.date     "rederivation_complete_date"
    t.date     "cre_excision_started_date"
    t.date     "cre_excision_complete_date"
    t.date     "phenotyping_started_date"
    t.date     "phenotyping_complete_date"
    t.date     "phenotype_attempt_aborted_date"
    t.integer  "distinct_genotype_confirmed_es_cells"
    t.integer  "distinct_old_genotype_confirmed_es_cells"
    t.integer  "distinct_non_genotype_confirmed_es_cells"
    t.integer  "distinct_old_non_genotype_confirmed_es_cells"
    t.integer  "total_pipeline_efficiency_gene_count"
    t.integer  "total_old_pipeline_efficiency_gene_count"
    t.integer  "gc_pipeline_efficiency_gene_count"
    t.integer  "gc_old_pipeline_efficiency_gene_count"
    t.datetime "created_at"
    t.string   "non_cre_ex_phenotype_attempt_status"
    t.date     "non_cre_ex_phenotype_attempt_registered_date"
    t.date     "non_cre_ex_rederivation_started_date"
    t.date     "non_cre_ex_rederivation_complete_date"
    t.date     "non_cre_ex_cre_excision_started_date"
    t.date     "non_cre_ex_cre_excision_complete_date"
    t.date     "non_cre_ex_phenotyping_started_date"
    t.date     "non_cre_ex_phenotyping_complete_date"
    t.date     "non_cre_ex_phenotype_attempt_aborted_date"
    t.string   "non_cre_ex_pa_mouse_allele_type"
    t.string   "non_cre_ex_pa_allele_symbol_superscript_template"
    t.string   "non_cre_ex_pa_allele_symbol_superscript"
    t.string   "non_cre_ex_mi_attempt_consortium"
    t.string   "non_cre_ex_mi_attempt_production_centre"
    t.string   "non_cre_ex_phenotype_attempt_colony_name"
    t.string   "cre_ex_phenotype_attempt_status"
    t.date     "cre_ex_phenotype_attempt_registered_date"
    t.date     "cre_ex_rederivation_started_date"
    t.date     "cre_ex_rederivation_complete_date"
    t.date     "cre_ex_cre_excision_started_date"
    t.date     "cre_ex_cre_excision_complete_date"
    t.date     "cre_ex_phenotyping_started_date"
    t.date     "cre_ex_phenotyping_complete_date"
    t.date     "cre_ex_phenotype_attempt_aborted_date"
    t.string   "cre_ex_pa_mouse_allele_type"
    t.string   "cre_ex_pa_allele_symbol_superscript_template"
    t.string   "cre_ex_pa_allele_symbol_superscript"
    t.string   "cre_ex_mi_attempt_consortium"
    t.string   "cre_ex_mi_attempt_production_centre"
    t.string   "cre_ex_phenotype_attempt_colony_name"
    t.date     "phenotyping_experiments_started_date"
    t.date     "non_cre_ex_phenotyping_experiments_started_date"
    t.date     "cre_ex_phenotyping_experiments_started_date"
    t.boolean  "mutagenesis_via_crispr_cas9",                                     :default => false
  end

  create_table "notifications", :force => true do |t|
    t.datetime "welcome_email_sent"
    t.text     "welcome_email_text"
    t.datetime "last_email_sent"
    t.text     "last_email_text"
    t.integer  "gene_id",            :null => false
    t.integer  "contact_id",         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "phenotype_attempt_distribution_centres", :force => true do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "phenotype_attempt_id",                      :null => false
    t.integer  "deposited_material_id",                     :null => false
    t.integer  "centre_id",                                 :null => false
    t.boolean  "is_distributed_by_emma", :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "distribution_network"
  end

  create_table "phenotype_attempt_status_stamps", :force => true do |t|
    t.integer  "phenotype_attempt_id", :null => false
    t.integer  "status_id",            :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "phenotype_attempt_status_stamps", ["status_id", "phenotype_attempt_id"], :name => "index_one_status_stamp_per_status_and_phenotype_attempt", :unique => true

  create_table "phenotype_attempt_statuses", :force => true do |t|
    t.string   "name",       :limit => 50, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_by"
    t.string   "code",       :limit => 10, :null => false
  end

  create_table "phenotype_attempts", :force => true do |t|
    t.integer  "mi_attempt_id",                                                         :null => false
    t.integer  "status_id",                                                             :null => false
    t.boolean  "is_active",                                          :default => true,  :null => false
    t.boolean  "rederivation_started",                               :default => false, :null => false
    t.boolean  "rederivation_complete",                              :default => false, :null => false
    t.integer  "number_of_cre_matings_started",                      :default => 0,     :null => false
    t.integer  "number_of_cre_matings_successful",                   :default => 0,     :null => false
    t.boolean  "phenotyping_started",                                :default => false, :null => false
    t.boolean  "phenotyping_complete",                               :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mi_plan_id",                                                            :null => false
    t.string   "colony_name",                         :limit => 125,                    :null => false
    t.string   "mouse_allele_type",                   :limit => 3
    t.integer  "deleter_strain_id"
    t.integer  "colony_background_strain_id"
    t.boolean  "cre_excision_required",                              :default => true,  :null => false
    t.boolean  "tat_cre",                                            :default => false
    t.boolean  "report_to_public",                                   :default => true,  :null => false
    t.date     "phenotyping_experiments_started"
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
    t.integer  "qc_lacz_count_qpcr_id"
    t.integer  "qc_critical_region_qpcr_id"
    t.integer  "qc_loxp_srpcr_id"
    t.integer  "qc_loxp_srpcr_and_sequencing_id"
  end

  add_index "phenotype_attempts", ["colony_name"], :name => "index_phenotype_attempts_on_colony_name", :unique => true

  create_table "pipelines", :force => true do |t|
    t.string   "name",        :limit => 50, :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pipelines", ["name"], :name => "index_pipelines_on_name", :unique => true

  create_table "production_goals", :force => true do |t|
    t.integer  "consortium_id"
    t.integer  "year"
    t.integer  "month"
    t.integer  "mi_goal"
    t.integer  "gc_goal"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "production_goals", ["consortium_id", "year", "month"], :name => "index_production_goals_on_consortium_id_and_year_and_month", :unique => true

  create_table "qc_results", :force => true do |t|
    t.string   "description", :limit => 50, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "qc_results", ["description"], :name => "index_qc_results_on_description", :unique => true

  create_table "report_caches", :force => true do |t|
    t.text     "name",       :null => false
    t.text     "data",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "format",     :null => false
  end

  add_index "report_caches", ["name", "format"], :name => "index_report_caches_on_name_and_format", :unique => true

  create_table "solr_centre_map", :id => false, :force => true do |t|
    t.string "centre_name", :limit => 40
    t.string "pref"
    t.string "def"
  end

  create_table "solr_mi_attempts", :id => false, :force => true do |t|
    t.integer "id"
    t.text    "product_type"
    t.text    "type"
    t.string  "colony_name",                        :limit => 125
    t.string  "marker_symbol",                      :limit => 75
    t.string  "es_cell_name",                       :limit => 100
    t.integer "allele_id"
    t.string  "mgi_accession_id",                   :limit => 40
    t.string  "production_centre",                  :limit => 100
    t.string  "strain",                             :limit => 100
    t.text    "genbank_file_url"
    t.text    "allele_image_url"
    t.text    "simple_allele_image_url"
    t.string  "allele_type",                        :limit => 100
    t.string  "project_ids"
    t.text    "current_pa_status"
    t.text    "allele_name"
    t.text    "order_from_names"
    t.text    "order_from_urls"
    t.text    "best_status_pa_cre_ex_not_required"
    t.text    "best_status_pa_cre_ex_required"
  end

  create_table "solr_options", :id => false, :force => true do |t|
    t.text "key"
    t.text "value"
    t.text "mode"
  end

  create_table "solr_phenotype_attempts", :id => false, :force => true do |t|
    t.integer "id"
    t.text    "product_type"
    t.text    "type"
    t.string  "colony_name",                        :limit => 125
    t.text    "allele_type"
    t.text    "allele_name"
    t.text    "order_from_names"
    t.text    "order_from_urls"
    t.integer "allele_id"
    t.string  "strain",                             :limit => 100
    t.string  "mgi_accession_id",                   :limit => 40
    t.string  "production_centre",                  :limit => 100
    t.text    "allele_image_url"
    t.text    "simple_allele_image_url"
    t.text    "genbank_file_url"
    t.text    "project_ids"
    t.string  "marker_symbol",                      :limit => 75
    t.string  "parent_mi_attempt_colony_name",      :limit => 125
    t.text    "best_status_pa_cre_ex_required"
    t.text    "best_status_pa_cre_ex_not_required"
    t.string  "current_pa_status",                  :limit => 50
  end

  create_table "solr_update_queue_items", :force => true do |t|
    t.integer  "mi_attempt_id"
    t.integer  "phenotype_attempt_id"
    t.text     "action"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "allele_id"
    t.integer  "gene_id"
  end

  add_index "solr_update_queue_items", ["allele_id"], :name => "index_solr_update_queue_items_on_allele_id", :unique => true
  add_index "solr_update_queue_items", ["mi_attempt_id"], :name => "index_solr_update_queue_items_on_mi_attempt_id", :unique => true
  add_index "solr_update_queue_items", ["phenotype_attempt_id"], :name => "index_solr_update_queue_items_on_phenotype_attempt_id", :unique => true

  create_table "strains", :force => true do |t|
    t.string   "name",                    :limit => 100, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "mgi_strain_accession_id", :limit => 100
    t.string   "mgi_strain_name",         :limit => 100
  end

  add_index "strains", ["name"], :name => "index_strains_on_name", :unique => true

  create_table "targ_rep_alleles", :force => true do |t|
    t.integer  "gene_id"
    t.string   "assembly",            :limit => 50,  :default => "NCBIM37",                 :null => false
    t.string   "chromosome",          :limit => 2,                                          :null => false
    t.string   "strand",              :limit => 1,                                          :null => false
    t.integer  "homology_arm_start"
    t.integer  "homology_arm_end"
    t.integer  "loxp_start"
    t.integer  "loxp_end"
    t.integer  "cassette_start"
    t.integer  "cassette_end"
    t.string   "cassette",            :limit => 100
    t.string   "backbone",            :limit => 100
    t.string   "subtype_description"
    t.string   "floxed_start_exon"
    t.string   "floxed_end_exon"
    t.integer  "project_design_id"
    t.string   "reporter"
    t.integer  "mutation_method_id"
    t.integer  "mutation_type_id"
    t.integer  "mutation_subtype_id"
    t.string   "cassette_type",       :limit => 50
    t.datetime "created_at",                                                                :null => false
    t.datetime "updated_at",                                                                :null => false
    t.integer  "intron"
    t.string   "type",                               :default => "TargRep::TargetedAllele"
  end

  create_table "targ_rep_centre_pipelines", :force => true do |t|
    t.string   "name"
    t.text     "centres"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "targ_rep_crisprs", :force => true do |t|
    t.integer  "mutagenesis_factor_id", :null => false
    t.string   "sequence",              :null => false
    t.string   "chr"
    t.integer  "start"
    t.integer  "end"
    t.datetime "created_at"
  end

  create_table "targ_rep_distribution_qcs", :force => true do |t|
    t.string   "five_prime_sr_pcr"
    t.string   "three_prime_sr_pcr"
    t.float    "karyotype_low"
    t.float    "karyotype_high"
    t.string   "copy_number"
    t.string   "five_prime_lr_pcr"
    t.string   "three_prime_lr_pcr"
    t.string   "thawing"
    t.string   "loa"
    t.string   "loxp"
    t.string   "lacz"
    t.string   "chr1"
    t.string   "chr8a"
    t.string   "chr8b"
    t.string   "chr11a"
    t.string   "chr11b"
    t.string   "chry"
    t.integer  "es_cell_id"
    t.integer  "es_cell_distribution_centre_id"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.string   "loxp_srpcr"
    t.string   "unspecified_repository_testing"
    t.string   "neo_qpcr"
  end

  add_index "targ_rep_distribution_qcs", ["es_cell_distribution_centre_id", "es_cell_id"], :name => "index_distribution_qcs_centre_es_cell", :unique => true

  create_table "targ_rep_es_cell_distribution_centres", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "targ_rep_es_cells", :force => true do |t|
    t.integer  "allele_id",                                                              :null => false
    t.integer  "targeting_vector_id"
    t.string   "parental_cell_line"
    t.string   "mgi_allele_symbol_superscript",         :limit => 75
    t.string   "name",                                  :limit => 100,                   :null => false
    t.string   "comment"
    t.string   "contact"
    t.string   "ikmc_project_id"
    t.string   "mgi_allele_id",                         :limit => 50
    t.integer  "pipeline_id"
    t.boolean  "report_to_public",                                     :default => true, :null => false
    t.string   "strain",                                :limit => 25
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
    t.string   "allele_type",                           :limit => 2
    t.string   "mutation_subtype",                      :limit => 100
    t.string   "allele_symbol_superscript_template",    :limit => 75
    t.integer  "legacy_id"
    t.datetime "created_at",                                                             :null => false
    t.datetime "updated_at",                                                             :null => false
    t.boolean  "production_centre_auto_update",                        :default => true
    t.string   "user_qc_loxp_srpcr_and_sequencing"
    t.string   "user_qc_karyotype_spread"
    t.string   "user_qc_karyotype_pcr"
    t.integer  "user_qc_mouse_clinic_id"
    t.string   "user_qc_chr1"
    t.string   "user_qc_chr11"
    t.string   "user_qc_chr8"
    t.string   "user_qc_chry"
    t.string   "user_qc_lacz_qpcr"
    t.integer  "ikmc_project_foreign_id"
  end

  add_index "targ_rep_es_cells", ["allele_id"], :name => "es_cells_allele_id_fk"
  add_index "targ_rep_es_cells", ["name"], :name => "targ_rep_index_es_cells_on_name", :unique => true
  add_index "targ_rep_es_cells", ["pipeline_id"], :name => "es_cells_pipeline_id_fk"

  create_table "targ_rep_genbank_files", :force => true do |t|
    t.integer  "allele_id",        :null => false
    t.text     "escell_clone"
    t.text     "targeting_vector"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "targ_rep_genbank_files", ["allele_id"], :name => "genbank_files_allele_id_fk"

  create_table "targ_rep_ikmc_project_statuses", :force => true do |t|
    t.string  "name"
    t.string  "product_type"
    t.integer "order_by"
  end

  create_table "targ_rep_ikmc_projects", :force => true do |t|
    t.string   "name",        :null => false
    t.integer  "status_id"
    t.integer  "pipeline_id", :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "targ_rep_mutation_methods", :force => true do |t|
    t.string   "name",       :limit => 100, :null => false
    t.string   "code",       :limit => 100, :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "targ_rep_mutation_subtypes", :force => true do |t|
    t.string   "name",       :limit => 100, :null => false
    t.string   "code",       :limit => 100, :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "targ_rep_mutation_types", :force => true do |t|
    t.string   "name",       :limit => 100, :null => false
    t.string   "code",       :limit => 100, :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "targ_rep_pipelines", :force => true do |t|
    t.string   "name",                                :null => false
    t.string   "description"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.integer  "legacy_id"
    t.boolean  "report_to_public", :default => true
    t.boolean  "gene_trap",        :default => false
  end

  add_index "targ_rep_pipelines", ["name"], :name => "index_targ_rep_pipelines_on_name", :unique => true

  create_table "targ_rep_targeting_vectors", :force => true do |t|
    t.integer  "allele_id",               :null => false
    t.string   "name",                    :null => false
    t.string   "ikmc_project_id"
    t.string   "intermediate_vector"
    t.boolean  "report_to_public",        :null => false
    t.integer  "pipeline_id"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
    t.integer  "ikmc_project_foreign_id"
  end

  add_index "targ_rep_targeting_vectors", ["allele_id"], :name => "targeting_vectors_allele_id_fk"
  add_index "targ_rep_targeting_vectors", ["name"], :name => "index_targvec", :unique => true
  add_index "targ_rep_targeting_vectors", ["pipeline_id"], :name => "targeting_vectors_pipeline_id_fk"

  create_table "tracking_goals", :force => true do |t|
    t.integer  "production_centre_id"
    t.date     "date"
    t.string   "goal_type"
    t.integer  "goal"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.integer  "consortium_id"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                         :default => "",    :null => false
    t.string   "encrypted_password",             :limit => 128, :default => "",    :null => false
    t.datetime "remember_created_at"
    t.integer  "production_centre_id",                                             :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.boolean  "is_contactable",                                :default => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer  "es_cell_distribution_centre_id"
    t.integer  "legacy_id"
    t.boolean  "admin",                                         :default => false
    t.boolean  "active",                                        :default => true
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

  add_foreign_key "mi_attempt_distribution_centres", "centres", :name => "mi_attempt_distribution_centres_centre_id_fk"
  add_foreign_key "mi_attempt_distribution_centres", "deposited_materials", :name => "mi_attempt_distribution_centres_deposited_material_id_fk"
  add_foreign_key "mi_attempt_distribution_centres", "mi_attempts", :name => "mi_attempt_distribution_centres_mi_attempt_id_fk"

  add_foreign_key "mi_attempt_status_stamps", "mi_attempt_statuses", :name => "mi_attempt_status_stamps_mi_attempt_status_id_fk", :column => "status_id"

  add_foreign_key "mi_attempts", "mi_attempt_statuses", :name => "mi_attempts_mi_attempt_status_id_fk", :column => "status_id"
  add_foreign_key "mi_attempts", "mi_plans", :name => "mi_attempts_mi_plan_id_fk"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_critical_region_qpcr_id_fk", :column => "qc_critical_region_qpcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_five_prime_cassette_integrity_id_fk", :column => "qc_five_prime_cassette_integrity_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_five_prime_lr_pcr_id_fk", :column => "qc_five_prime_lr_pcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_homozygous_loa_sr_pcr_id_fk", :column => "qc_homozygous_loa_sr_pcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_lacz_sr_pcr_id_fk", :column => "qc_lacz_sr_pcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_loa_qpcr_id_fk", :column => "qc_loa_qpcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_loxp_confirmation_id_fk", :column => "qc_loxp_confirmation_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_loxp_srpcr_and_sequencing_id_fk", :column => "qc_loxp_srpcr_and_sequencing_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_loxp_srpcr_id_fk", :column => "qc_loxp_srpcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_mutant_specific_sr_pcr_id_fk", :column => "qc_mutant_specific_sr_pcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_neo_count_qpcr_id_fk", :column => "qc_neo_count_qpcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_neo_sr_pcr_id_fk", :column => "qc_neo_sr_pcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_southern_blot_id_fk", :column => "qc_southern_blot_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_three_prime_lr_pcr_id_fk", :column => "qc_three_prime_lr_pcr_id"
  add_foreign_key "mi_attempts", "qc_results", :name => "mi_attempts_qc_tv_backbone_assay_id_fk", :column => "qc_tv_backbone_assay_id"
  add_foreign_key "mi_attempts", "strains", :name => "mi_attempts_blast_strain_id_fk", :column => "blast_strain_id"
  add_foreign_key "mi_attempts", "strains", :name => "mi_attempts_colony_background_strain_id_fk", :column => "colony_background_strain_id"
  add_foreign_key "mi_attempts", "strains", :name => "mi_attempts_test_cross_strain_id_fk", :column => "test_cross_strain_id"
  add_foreign_key "mi_attempts", "users", :name => "mi_attempts_updated_by_id_fk", :column => "updated_by_id"

  add_foreign_key "mi_plan_es_cell_qcs", "mi_plans", :name => "mi_plan_es_cell_qcs_mi_plan_id_fk"

  add_foreign_key "mi_plan_status_stamps", "mi_plan_statuses", :name => "mi_plan_status_stamps_mi_plan_status_id_fk", :column => "status_id"
  add_foreign_key "mi_plan_status_stamps", "mi_plans", :name => "mi_plan_status_stamps_mi_plan_id_fk"

  add_foreign_key "mi_plans", "centres", :name => "mi_plans_production_centre_id_fk", :column => "production_centre_id"
  add_foreign_key "mi_plans", "consortia", :name => "mi_plans_consortium_id_fk"
  add_foreign_key "mi_plans", "genes", :name => "mi_plans_gene_id_fk"
  add_foreign_key "mi_plans", "mi_plan_es_qc_comments", :name => "mi_plans_es_qc_comment_id_fk", :column => "es_qc_comment_id"
  add_foreign_key "mi_plans", "mi_plan_priorities", :name => "mi_plans_mi_plan_priority_id_fk", :column => "priority_id"
  add_foreign_key "mi_plans", "mi_plan_statuses", :name => "mi_plans_mi_plan_status_id_fk", :column => "status_id"
  add_foreign_key "mi_plans", "mi_plan_sub_projects", :name => "mi_plans_sub_project_id_fk", :column => "sub_project_id"

  add_foreign_key "notifications", "contacts", :name => "notifications_contact_id_fk"
  add_foreign_key "notifications", "genes", :name => "notifications_gene_id_fk"

  add_foreign_key "phenotype_attempt_distribution_centres", "centres", :name => "phenotype_attempt_distribution_centres_centre_id_fk"
  add_foreign_key "phenotype_attempt_distribution_centres", "deposited_materials", :name => "phenotype_attempt_distribution_centres_deposited_material_id_fk"
  add_foreign_key "phenotype_attempt_distribution_centres", "phenotype_attempts", :name => "phenotype_attempt_distribution_centres_phenotype_attempt_id_fk"

  add_foreign_key "phenotype_attempt_status_stamps", "phenotype_attempt_statuses", :name => "phenotype_attempt_status_stamps_status_id_fk", :column => "status_id"
  add_foreign_key "phenotype_attempt_status_stamps", "phenotype_attempts", :name => "phenotype_attempt_status_stamps_phenotype_attempt_id_fk"

  add_foreign_key "phenotype_attempts", "mi_plans", :name => "phenotype_attempts_mi_plan_id_fk"
  add_foreign_key "phenotype_attempts", "phenotype_attempt_statuses", :name => "phenotype_attempts_status_id_fk", :column => "status_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_critical_region_qpcr_id_fk", :column => "qc_critical_region_qpcr_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_five_prime_cassette_integrity_id_fk", :column => "qc_five_prime_cassette_integrity_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_five_prime_lr_pcr_id_fk", :column => "qc_five_prime_lr_pcr_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_homozygous_loa_sr_pcr_id_fk", :column => "qc_homozygous_loa_sr_pcr_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_lacz_count_qpcr_id_fk", :column => "qc_lacz_count_qpcr_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_lacz_sr_pcr_id_fk", :column => "qc_lacz_sr_pcr_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_loa_qpcr_id_fk", :column => "qc_loa_qpcr_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_loxp_confirmation_id_fk", :column => "qc_loxp_confirmation_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_loxp_srpcr_and_sequencing_id_fk", :column => "qc_loxp_srpcr_and_sequencing_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_loxp_srpcr_id_fk", :column => "qc_loxp_srpcr_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_mutant_specific_sr_pcr_id_fk", :column => "qc_mutant_specific_sr_pcr_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_neo_count_qpcr_id_fk", :column => "qc_neo_count_qpcr_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_neo_sr_pcr_id_fk", :column => "qc_neo_sr_pcr_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_southern_blot_id_fk", :column => "qc_southern_blot_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_three_prime_lr_pcr_id_fk", :column => "qc_three_prime_lr_pcr_id"
  add_foreign_key "phenotype_attempts", "qc_results", :name => "phenotype_attempts_qc_tv_backbone_assay_id_fk", :column => "qc_tv_backbone_assay_id"
  add_foreign_key "phenotype_attempts", "strains", :name => "phenotype_attempts_colony_background_strain_id_fk", :column => "colony_background_strain_id"

  add_foreign_key "targ_rep_es_cells", "centres", :name => "targ_rep_es_cells_user_qc_mouse_clinic_id_fk", :column => "user_qc_mouse_clinic_id"

  add_foreign_key "users", "targ_rep_es_cell_distribution_centres", :name => "users_es_cell_distribution_centre_id_fk", :column => "es_cell_distribution_centre_id"

end
