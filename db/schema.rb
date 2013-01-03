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

ActiveRecord::Schema.define(:version => 20130103113250) do

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

  create_table "contacts", :force => true do |t|
    t.string   "email",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
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
  end

  add_index "genes", ["marker_symbol"], :name => "index_genes_on_marker_symbol", :unique => true
  add_index "genes", ["mgi_accession_id"], :name => "index_genes_on_mgi_accession_id", :unique => true

  create_table "intermediate_report", :force => true do |t|
    t.string   "consortium",                                                  :null => false
    t.string   "sub_project",                                                 :null => false
    t.string   "priority"
    t.string   "production_centre",                            :limit => 100, :null => false
    t.string   "gene",                                         :limit => 75,  :null => false
    t.string   "mgi_accession_id",                             :limit => 40
    t.string   "overall_status",                               :limit => 50
    t.string   "mi_plan_status",                               :limit => 50
    t.string   "mi_attempt_status",                            :limit => 50
    t.string   "phenotype_attempt_status",                     :limit => 50
    t.integer  "ikmc_project_id"
    t.string   "mutation_sub_type",                            :limit => 100
    t.string   "allele_symbol",                                :limit => 75,  :null => false
    t.string   "genetic_background",                           :limit => 50,  :null => false
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
    t.integer  "es_cell_id",                                                                        :null => false
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
    t.string   "mouse_allele_type",                               :limit => 2
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
  end

  add_index "mi_attempts", ["colony_name"], :name => "index_mi_attempts_on_colony_name", :unique => true

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
    t.integer  "gene_id",                                           :null => false
    t.integer  "consortium_id",                                     :null => false
    t.integer  "status_id",                                         :null => false
    t.integer  "priority_id",                                       :null => false
    t.integer  "production_centre_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "number_of_es_cells_starting_qc"
    t.integer  "number_of_es_cells_passing_qc"
    t.integer  "sub_project_id",                                    :null => false
    t.boolean  "is_active",                      :default => true,  :null => false
    t.boolean  "is_bespoke_allele",              :default => false, :null => false
    t.boolean  "is_conditional_allele",          :default => false, :null => false
    t.boolean  "is_deletion_allele",             :default => false, :null => false
    t.boolean  "is_cre_knock_in_allele",         :default => false, :null => false
    t.boolean  "is_cre_bac_allele",              :default => false, :null => false
    t.text     "comment"
    t.boolean  "withdrawn",                      :default => false, :null => false
    t.integer  "es_qc_comment_id"
  end

  add_index "mi_plans", ["gene_id", "consortium_id", "production_centre_id", "sub_project_id"], :name => "mi_plan_logical_key", :unique => true

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
    t.integer  "mi_attempt_id",                                                      :null => false
    t.integer  "status_id",                                                          :null => false
    t.boolean  "is_active",                                       :default => true,  :null => false
    t.boolean  "rederivation_started",                            :default => false, :null => false
    t.boolean  "rederivation_complete",                           :default => false, :null => false
    t.integer  "number_of_cre_matings_started",                   :default => 0,     :null => false
    t.integer  "number_of_cre_matings_successful",                :default => 0,     :null => false
    t.boolean  "phenotyping_started",                             :default => false, :null => false
    t.boolean  "phenotyping_complete",                            :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mi_plan_id",                                                         :null => false
    t.string   "colony_name",                      :limit => 125,                    :null => false
    t.string   "mouse_allele_type",                :limit => 2
    t.integer  "deleter_strain_id"
    t.integer  "colony_background_strain_id"
    t.boolean  "cre_excision_required",                           :default => true,  :null => false
  end

  add_index "phenotype_attempts", ["colony_name"], :name => "index_phenotype_attempts_on_colony_name", :unique => true

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
    t.text     "data",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "format",     :null => false
  end

  add_index "report_caches", ["name", "format"], :name => "index_report_caches_on_name_and_format", :unique => true

  create_table "solr_update_queue_items", :force => true do |t|
    t.integer  "mi_attempt_id"
    t.integer  "phenotype_attempt_id"
    t.text     "action"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "allele_id"
  end

  add_index "solr_update_queue_items", ["allele_id"], :name => "index_solr_update_queue_items_on_allele_id", :unique => true
  add_index "solr_update_queue_items", ["mi_attempt_id"], :name => "index_solr_update_queue_items_on_mi_attempt_id", :unique => true
  add_index "solr_update_queue_items", ["phenotype_attempt_id"], :name => "index_solr_update_queue_items_on_phenotype_attempt_id", :unique => true

  create_table "strains", :force => true do |t|
    t.string   "name",       :limit => 50, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "strains", ["name"], :name => "index_strains_on_name", :unique => true

  create_table "targ_rep_alleles", :force => true do |t|
    t.integer  "gene_id"
    t.string   "assembly",            :limit => 50,  :default => "NCBIM37", :null => false
    t.string   "chromosome",          :limit => 2,                          :null => false
    t.string   "strand",              :limit => 1,                          :null => false
    t.integer  "homology_arm_start",                                        :null => false
    t.integer  "homology_arm_end",                                          :null => false
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
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "targ_rep_distribution_qcs", ["es_cell_distribution_centre_id", "es_cell_id"], :name => "index_distribution_qcs_centre_es_cell", :unique => true

  create_table "targ_rep_es_cell_distribution_centres", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.datetime "created_at"
    t.datetime "updated_at"
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

  create_table "targ_rep_mutation_methods", :force => true do |t|
    t.string   "name",       :limit => 100, :null => false
    t.string   "code",       :limit => 100, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "targ_rep_mutation_subtypes", :force => true do |t|
    t.string   "name",       :limit => 100, :null => false
    t.string   "code",       :limit => 100, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "targ_rep_mutation_types", :force => true do |t|
    t.string   "name",       :limit => 100, :null => false
    t.string   "code",       :limit => 100, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "targ_rep_pipelines", :force => true do |t|
    t.string   "name",        :null => false
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "legacy_id"
  end

  add_index "targ_rep_pipelines", ["name"], :name => "index_targ_rep_pipelines_on_name", :unique => true

  create_table "targ_rep_targeting_vectors", :force => true do |t|
    t.integer  "allele_id",                             :null => false
    t.string   "name",                                  :null => false
    t.string   "ikmc_project_id"
    t.string   "intermediate_vector"
    t.boolean  "report_to_public",    :default => true, :null => false
    t.integer  "pipeline_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "targ_rep_targeting_vectors", ["allele_id"], :name => "targeting_vectors_allele_id_fk"
  add_index "targ_rep_targeting_vectors", ["name"], :name => "index_targvec", :unique => true
  add_index "targ_rep_targeting_vectors", ["pipeline_id"], :name => "targeting_vectors_pipeline_id_fk"

  create_table "users", :force => true do |t|
    t.string   "email",                                         :default => "",    :null => false
    t.string   "encrypted_password",             :limit => 128, :default => "",    :null => false
    t.datetime "remember_created_at"
    t.integer  "production_centre_id",                                             :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.boolean  "is_contactable",                                :default => false
    t.integer  "es_cell_distribution_centre_id"
    t.integer  "legacy_id"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

  add_foreign_key "mi_attempt_distribution_centres", "centres", :name => "mi_attempt_distribution_centres_centre_id_fk"
  add_foreign_key "mi_attempt_distribution_centres", "deposited_materials", :name => "mi_attempt_distribution_centres_deposited_material_id_fk"
  add_foreign_key "mi_attempt_distribution_centres", "mi_attempts", :name => "mi_attempt_distribution_centres_mi_attempt_id_fk"

  add_foreign_key "mi_attempt_status_stamps", "mi_attempt_statuses", :name => "mi_attempt_status_stamps_mi_attempt_status_id_fk", :column => "status_id"
  add_foreign_key "mi_attempt_status_stamps", "mi_attempts", :name => "mi_attempt_status_stamps_mi_attempt_id_fk"

  add_foreign_key "mi_attempts", "mi_attempt_statuses", :name => "mi_attempts_mi_attempt_status_id_fk", :column => "status_id"
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
  add_foreign_key "mi_attempts", "strains", :name => "mi_attempts_blast_strain_id_fk", :column => "blast_strain_id"
  add_foreign_key "mi_attempts", "strains", :name => "mi_attempts_colony_background_strain_id_fk", :column => "colony_background_strain_id"
  add_foreign_key "mi_attempts", "strains", :name => "mi_attempts_test_cross_strain_id_fk", :column => "test_cross_strain_id"
  add_foreign_key "mi_attempts", "users", :name => "mi_attempts_updated_by_id_fk", :column => "updated_by_id"

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

  add_foreign_key "phenotype_attempts", "mi_attempts", :name => "phenotype_attempts_mi_attempt_id_fk"
  add_foreign_key "phenotype_attempts", "mi_plans", :name => "phenotype_attempts_mi_plan_id_fk"
  add_foreign_key "phenotype_attempts", "phenotype_attempt_statuses", :name => "phenotype_attempts_status_id_fk", :column => "status_id"
  add_foreign_key "phenotype_attempts", "strains", :name => "phenotype_attempts_colony_background_strain_id_fk", :column => "colony_background_strain_id"

  add_foreign_key "users", "targ_rep_es_cell_distribution_centres", :name => "users_es_cell_distribution_centre_id_fk", :column => "es_cell_distribution_centre_id"

end
