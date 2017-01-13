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

ActiveRecord::Schema.define(:version => 201604011125302) do

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
    t.string   "code"
    t.string   "superscript"
  end

  add_index "centres", ["name"], :name => "index_centres_on_name", :unique => true

  create_table "colonies", :force => true do |t|
    t.string  "name",                                                           :null => false
    t.integer "mi_attempt_id"
    t.boolean "genotype_confirmed",                          :default => false
    t.boolean "report_to_public",                            :default => false
    t.boolean "unwanted_allele",                             :default => false
    t.text    "allele_description"
    t.string  "mgi_allele_id"
    t.string  "allele_name"
    t.integer "mouse_allele_mod_id"
    t.string  "mgi_allele_symbol_superscript"
    t.string  "allele_symbol_superscript_template"
    t.string  "allele_type"
    t.integer "background_strain_id"
    t.text    "allele_description_summary"
    t.text    "auto_allele_description"
    t.boolean "mgi_allele_symbol_without_impc_abbreviation", :default => false
    t.boolean "private",                                     :default => false, :null => false
    t.string  "crispr_allele_category"
  end

  add_index "colonies", ["name", "mi_attempt_id", "mouse_allele_mod_id"], :name => "mouse_allele_mod_colony_name_uniqueness_index", :unique => true

  create_table "colony_distribution_centres", :force => true do |t|
    t.integer  "colony_id",                                        :null => false
    t.integer  "deposited_material_id",                            :null => false
    t.string   "distribution_network"
    t.integer  "centre_id",                                        :null => false
    t.date     "start_date"
    t.date     "end_date"
    t.string   "reconciled",            :default => "not checked", :null => false
    t.datetime "reconciled_at"
    t.boolean  "available",             :default => true,          :null => false
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
  end

  create_table "colony_qcs", :force => true do |t|
    t.integer "colony_id",                        :null => false
    t.string  "qc_southern_blot",                 :null => false
    t.string  "qc_five_prime_lr_pcr",             :null => false
    t.string  "qc_five_prime_cassette_integrity", :null => false
    t.string  "qc_tv_backbone_assay",             :null => false
    t.string  "qc_neo_count_qpcr",                :null => false
    t.string  "qc_lacz_count_qpcr",               :null => false
    t.string  "qc_neo_sr_pcr",                    :null => false
    t.string  "qc_loa_qpcr",                      :null => false
    t.string  "qc_homozygous_loa_sr_pcr",         :null => false
    t.string  "qc_lacz_sr_pcr",                   :null => false
    t.string  "qc_mutant_specific_sr_pcr",        :null => false
    t.string  "qc_loxp_confirmation",             :null => false
    t.string  "qc_three_prime_lr_pcr",            :null => false
    t.string  "qc_critical_region_qpcr",          :null => false
    t.string  "qc_loxp_srpcr",                    :null => false
    t.string  "qc_loxp_srpcr_and_sequencing",     :null => false
  end

  add_index "colony_qcs", ["colony_id"], :name => "index_colony_qcs_on_colony_id", :unique => true

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
    t.string   "name",          :limit => 100, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "excision_type"
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
    t.string   "feature_type"
    t.string   "synonyms"
    t.integer  "komp_repo_geneid"
    t.string   "marker_name"
    t.string   "cm_position"
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

  create_table "intermediate_report_summary_by_centre", :force => true do |t|
    t.string  "catagory",                               :null => false
    t.string  "approach",                               :null => false
    t.string  "allele_type",                            :null => false
    t.integer "mi_plan_id"
    t.integer "mi_attempt_id"
    t.integer "modified_mouse_allele_mod_id"
    t.integer "mouse_allele_mod_id"
    t.integer "phenotyping_production_id"
    t.string  "production_centre"
    t.string  "gene"
    t.string  "mgi_accession_id"
    t.string  "mi_attempt_external_ref"
    t.string  "mi_attempt_colony_name"
    t.string  "mouse_allele_mod_colony_name"
    t.string  "phenotyping_production_colony_name"
    t.string  "mi_plan_status"
    t.date    "gene_interest_date"
    t.date    "assigned_date"
    t.date    "assigned_es_cell_qc_in_progress_date"
    t.date    "assigned_es_cell_qc_complete_date"
    t.date    "aborted_es_cell_qc_failed_date"
    t.string  "mi_attempt_status"
    t.date    "micro_injection_aborted_date"
    t.date    "micro_injection_in_progress_date"
    t.date    "chimeras_obtained_date"
    t.date    "founder_obtained_date"
    t.date    "genotype_confirmed_date"
    t.string  "mouse_allele_mod_status"
    t.date    "mouse_allele_mod_registered_date"
    t.date    "rederivation_started_date"
    t.date    "rederivation_complete_date"
    t.date    "cre_excision_started_date"
    t.date    "cre_excision_complete_date"
    t.string  "phenotyping_status"
    t.date    "phenotyping_registered_date"
    t.date    "phenotyping_rederivation_started_date"
    t.date    "phenotyping_rederivation_complete_date"
    t.date    "phenotyping_experiments_started_date"
    t.date    "phenotyping_started_date"
    t.date    "phenotyping_complete_date"
    t.date    "phenotype_attempt_aborted_date"
    t.date    "created_at"
  end

  add_index "intermediate_report_summary_by_centre", ["allele_type"], :name => "irscen_allele_type"
  add_index "intermediate_report_summary_by_centre", ["approach"], :name => "irscen_approach"
  add_index "intermediate_report_summary_by_centre", ["catagory"], :name => "irscen_catagory"
  add_index "intermediate_report_summary_by_centre", ["gene", "production_centre"], :name => "irscen_gene_centre"
  add_index "intermediate_report_summary_by_centre", ["mi_attempt_id"], :name => "irscen_mi_attempts"
  add_index "intermediate_report_summary_by_centre", ["mi_plan_id"], :name => "irscen_mi_plans"
  add_index "intermediate_report_summary_by_centre", ["mouse_allele_mod_id"], :name => "irscen_mouse_allele_mods"
  add_index "intermediate_report_summary_by_centre", ["phenotyping_production_id"], :name => "irscen_phenotyping_productions"

  create_table "intermediate_report_summary_by_centre_and_consortia", :force => true do |t|
    t.string  "catagory",                               :null => false
    t.string  "approach",                               :null => false
    t.string  "allele_type",                            :null => false
    t.integer "mi_plan_id"
    t.integer "mi_attempt_id"
    t.integer "modified_mouse_allele_mod_id"
    t.integer "mouse_allele_mod_id"
    t.integer "phenotyping_production_id"
    t.string  "consortium"
    t.string  "production_centre"
    t.string  "gene"
    t.string  "mgi_accession_id"
    t.string  "mi_attempt_external_ref"
    t.string  "mi_attempt_colony_name"
    t.string  "mouse_allele_mod_colony_name"
    t.string  "phenotyping_production_colony_name"
    t.string  "mi_plan_status"
    t.date    "gene_interest_date"
    t.date    "assigned_date"
    t.date    "assigned_es_cell_qc_in_progress_date"
    t.date    "assigned_es_cell_qc_complete_date"
    t.date    "aborted_es_cell_qc_failed_date"
    t.string  "mi_attempt_status"
    t.date    "micro_injection_aborted_date"
    t.date    "micro_injection_in_progress_date"
    t.date    "chimeras_obtained_date"
    t.date    "founder_obtained_date"
    t.date    "genotype_confirmed_date"
    t.string  "mouse_allele_mod_status"
    t.date    "mouse_allele_mod_registered_date"
    t.date    "rederivation_started_date"
    t.date    "rederivation_complete_date"
    t.date    "cre_excision_started_date"
    t.date    "cre_excision_complete_date"
    t.string  "phenotyping_status"
    t.date    "phenotyping_registered_date"
    t.date    "phenotyping_rederivation_started_date"
    t.date    "phenotyping_rederivation_complete_date"
    t.date    "phenotyping_experiments_started_date"
    t.date    "phenotyping_started_date"
    t.date    "phenotyping_complete_date"
    t.date    "phenotype_attempt_aborted_date"
    t.date    "created_at"
  end

  add_index "intermediate_report_summary_by_centre_and_consortia", ["allele_type"], :name => "irscc_allele_type"
  add_index "intermediate_report_summary_by_centre_and_consortia", ["approach"], :name => "irscc_approach"
  add_index "intermediate_report_summary_by_centre_and_consortia", ["catagory"], :name => "irscc_catagory"
  add_index "intermediate_report_summary_by_centre_and_consortia", ["gene", "production_centre", "consortium"], :name => "irscen_gene_centre_consortia"
  add_index "intermediate_report_summary_by_centre_and_consortia", ["mi_attempt_id"], :name => "irscc_mi_attempts"
  add_index "intermediate_report_summary_by_centre_and_consortia", ["mi_plan_id"], :name => "irscc_mi_plans"
  add_index "intermediate_report_summary_by_centre_and_consortia", ["mouse_allele_mod_id"], :name => "irscc_mouse_allele_mods"
  add_index "intermediate_report_summary_by_centre_and_consortia", ["phenotyping_production_id"], :name => "irscc_phenotyping_productions"

  create_table "intermediate_report_summary_by_consortia", :force => true do |t|
    t.string  "catagory",                               :null => false
    t.string  "approach",                               :null => false
    t.string  "allele_type",                            :null => false
    t.integer "mi_plan_id"
    t.integer "mi_attempt_id"
    t.integer "modified_mouse_allele_mod_id"
    t.integer "mouse_allele_mod_id"
    t.integer "phenotyping_production_id"
    t.string  "consortium"
    t.string  "gene"
    t.string  "mgi_accession_id"
    t.string  "mi_attempt_external_ref"
    t.string  "mi_attempt_colony_name"
    t.string  "mouse_allele_mod_colony_name"
    t.string  "phenotyping_production_colony_name"
    t.string  "mi_plan_status"
    t.date    "gene_interest_date"
    t.date    "assigned_date"
    t.date    "assigned_es_cell_qc_in_progress_date"
    t.date    "assigned_es_cell_qc_complete_date"
    t.date    "aborted_es_cell_qc_failed_date"
    t.string  "mi_attempt_status"
    t.date    "micro_injection_aborted_date"
    t.date    "micro_injection_in_progress_date"
    t.date    "chimeras_obtained_date"
    t.date    "founder_obtained_date"
    t.date    "genotype_confirmed_date"
    t.string  "mouse_allele_mod_status"
    t.date    "mouse_allele_mod_registered_date"
    t.date    "rederivation_started_date"
    t.date    "rederivation_complete_date"
    t.date    "cre_excision_started_date"
    t.date    "cre_excision_complete_date"
    t.string  "phenotyping_status"
    t.date    "phenotyping_registered_date"
    t.date    "phenotyping_rederivation_started_date"
    t.date    "phenotyping_rederivation_complete_date"
    t.date    "phenotyping_experiments_started_date"
    t.date    "phenotyping_started_date"
    t.date    "phenotyping_complete_date"
    t.date    "phenotype_attempt_aborted_date"
    t.date    "created_at"
  end

  add_index "intermediate_report_summary_by_consortia", ["allele_type"], :name => "irsc_allele_type"
  add_index "intermediate_report_summary_by_consortia", ["approach"], :name => "irsc_approach"
  add_index "intermediate_report_summary_by_consortia", ["catagory"], :name => "irsc_catagory"
  add_index "intermediate_report_summary_by_consortia", ["gene", "consortium"], :name => "irscen_gene_consortia"
  add_index "intermediate_report_summary_by_consortia", ["mi_attempt_id"], :name => "irsc_mi_attempts"
  add_index "intermediate_report_summary_by_consortia", ["mi_plan_id"], :name => "irsc_mi_plans"
  add_index "intermediate_report_summary_by_consortia", ["mouse_allele_mod_id"], :name => "irsc_mouse_allele_mods"
  add_index "intermediate_report_summary_by_consortia", ["phenotyping_production_id"], :name => "irsc_phenotyping_productions"

  create_table "intermediate_report_summary_by_gene", :force => true do |t|
    t.string  "catagory",                               :null => false
    t.string  "approach",                               :null => false
    t.string  "allele_type",                            :null => false
    t.integer "mi_plan_id"
    t.integer "mi_attempt_id"
    t.integer "modified_mouse_allele_mod_id"
    t.integer "mouse_allele_mod_id"
    t.integer "phenotyping_production_id"
    t.string  "gene"
    t.string  "mgi_accession_id"
    t.string  "mi_attempt_external_ref"
    t.string  "mi_attempt_colony_name"
    t.string  "mouse_allele_mod_colony_name"
    t.string  "phenotyping_production_colony_name"
    t.string  "mi_plan_status"
    t.date    "assigned_date"
    t.date    "assigned_es_cell_qc_in_progress_date"
    t.date    "assigned_es_cell_qc_complete_date"
    t.date    "aborted_es_cell_qc_failed_date"
    t.string  "mi_attempt_status"
    t.date    "micro_injection_aborted_date"
    t.date    "micro_injection_in_progress_date"
    t.date    "chimeras_obtained_date"
    t.date    "founder_obtained_date"
    t.date    "genotype_confirmed_date"
    t.string  "mouse_allele_mod_status"
    t.date    "mouse_allele_mod_registered_date"
    t.date    "rederivation_started_date"
    t.date    "rederivation_complete_date"
    t.date    "cre_excision_started_date"
    t.date    "cre_excision_complete_date"
    t.string  "phenotyping_status"
    t.date    "phenotyping_registered_date"
    t.date    "phenotyping_rederivation_started_date"
    t.date    "phenotyping_rederivation_complete_date"
    t.date    "phenotyping_experiments_started_date"
    t.date    "phenotyping_started_date"
    t.date    "phenotyping_complete_date"
    t.date    "phenotype_attempt_aborted_date"
    t.date    "created_at"
  end

  add_index "intermediate_report_summary_by_gene", ["allele_type"], :name => "irsg_allele_type"
  add_index "intermediate_report_summary_by_gene", ["approach"], :name => "irsg_approach"
  add_index "intermediate_report_summary_by_gene", ["catagory"], :name => "irsg_catagory"
  add_index "intermediate_report_summary_by_gene", ["gene"], :name => "irsg_gene"
  add_index "intermediate_report_summary_by_gene", ["mi_attempt_id"], :name => "irsg_mi_attempts"
  add_index "intermediate_report_summary_by_gene", ["mi_plan_id"], :name => "irsg_mi_plans"
  add_index "intermediate_report_summary_by_gene", ["mouse_allele_mod_id"], :name => "irsg_mouse_allele_mods"
  add_index "intermediate_report_summary_by_gene", ["phenotyping_production_id"], :name => "irsg_phenotyping_productions"

  create_table "intermediate_report_summary_by_mi_plan", :force => true do |t|
    t.string  "catagory",                               :null => false
    t.string  "approach",                               :null => false
    t.string  "allele_type",                            :null => false
    t.integer "mi_plan_id"
    t.integer "mi_attempt_id"
    t.integer "modified_mouse_allele_mod_id"
    t.integer "mouse_allele_mod_id"
    t.integer "phenotyping_production_id"
    t.string  "consortium"
    t.string  "production_centre"
    t.string  "sub_project"
    t.string  "priority"
    t.string  "gene"
    t.string  "mgi_accession_id"
    t.string  "mi_attempt_external_ref"
    t.string  "mi_attempt_colony_name"
    t.string  "mouse_allele_mod_colony_name"
    t.string  "phenotyping_production_colony_name"
    t.string  "mi_plan_status"
    t.date    "assigned_date"
    t.date    "assigned_es_cell_qc_in_progress_date"
    t.date    "assigned_es_cell_qc_complete_date"
    t.date    "aborted_es_cell_qc_failed_date"
    t.string  "mi_attempt_status"
    t.date    "micro_injection_aborted_date"
    t.date    "micro_injection_in_progress_date"
    t.date    "chimeras_obtained_date"
    t.date    "founder_obtained_date"
    t.date    "genotype_confirmed_date"
    t.string  "mouse_allele_mod_status"
    t.date    "mouse_allele_mod_registered_date"
    t.date    "rederivation_started_date"
    t.date    "rederivation_complete_date"
    t.date    "cre_excision_started_date"
    t.date    "cre_excision_complete_date"
    t.string  "phenotyping_status"
    t.date    "phenotyping_registered_date"
    t.date    "phenotyping_rederivation_started_date"
    t.date    "phenotyping_rederivation_complete_date"
    t.date    "phenotyping_experiments_started_date"
    t.date    "phenotyping_started_date"
    t.date    "phenotyping_complete_date"
    t.date    "phenotype_attempt_aborted_date"
    t.integer "mi_aborted_count"
    t.date    "mi_aborted_max_date"
    t.integer "allele_mod_aborted_count"
    t.date    "allele_mod_aborted_max_date"
    t.date    "created_at"
  end

  add_index "intermediate_report_summary_by_mi_plan", ["allele_type"], :name => "irsmp_allele_type"
  add_index "intermediate_report_summary_by_mi_plan", ["approach"], :name => "irsmp_approach"
  add_index "intermediate_report_summary_by_mi_plan", ["catagory"], :name => "irsmp_catagory"
  add_index "intermediate_report_summary_by_mi_plan", ["mi_attempt_id"], :name => "irsmp_mi_attempts"
  add_index "intermediate_report_summary_by_mi_plan", ["mi_plan_id"], :name => "irsmp_mi_plans"
  add_index "intermediate_report_summary_by_mi_plan", ["mouse_allele_mod_id"], :name => "irsmp_mouse_allele_mods"
  add_index "intermediate_report_summary_by_mi_plan", ["phenotyping_production_id"], :name => "irsmp_phenotyping_productions"

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
    t.date     "mi_date",                                                                                           :null => false
    t.integer  "status_id",                                                                                         :null => false
    t.string   "external_ref",                                    :limit => 125
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
    t.boolean  "report_to_public",                                               :default => true,                  :null => false
    t.boolean  "is_active",                                                      :default => true,                  :null => false
    t.boolean  "is_released_from_genotyping",                                    :default => false,                 :null => false
    t.text     "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mi_plan_id",                                                                                        :null => false
    t.string   "genotyping_comment",                              :limit => 512
    t.integer  "legacy_es_cell_id"
    t.date     "cassette_transmission_verified"
    t.boolean  "cassette_transmission_verified_auto_complete"
    t.integer  "mutagenesis_factor_id"
    t.integer  "crsp_total_embryos_injected"
    t.integer  "crsp_total_embryos_survived"
    t.integer  "crsp_total_transfered"
    t.integer  "crsp_no_founder_pups"
    t.integer  "crsp_num_founders_selected_for_breading"
    t.integer  "allele_id"
    t.integer  "real_allele_id"
    t.integer  "founder_num_assays"
    t.text     "assay_type"
    t.boolean  "experimental",                                                   :default => false,                 :null => false
    t.string   "allele_target"
    t.integer  "parent_colony_id"
    t.string   "mrna_nuclease"
    t.float    "mrna_nuclease_concentration"
    t.string   "protein_nuclease"
    t.float    "protein_nuclease_concentration"
    t.string   "delivery_method"
    t.float    "voltage"
    t.integer  "number_of_pulses"
    t.string   "crsp_embryo_transfer_day",                                       :default => "Same Day"
    t.integer  "crsp_embryo_2_cell"
    t.string   "privacy",                                                        :default => "Share all Allele(s)", :null => false
  end

  add_index "mi_attempts", ["external_ref"], :name => "index_mi_attempts_on_colony_name", :unique => true

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
    t.integer  "priority_id"
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

  create_table "mouse_allele_mod_status_stamps", :force => true do |t|
    t.integer  "mouse_allele_mod_id", :null => false
    t.integer  "status_id",           :null => false
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "mouse_allele_mod_statuses", :force => true do |t|
    t.string  "name",     :limit => 50, :null => false
    t.integer "order_by",               :null => false
    t.string  "code",     :limit => 4,  :null => false
  end

  create_table "mouse_allele_mods", :force => true do |t|
    t.integer  "mi_plan_id",                                          :null => false
    t.integer  "status_id",                                           :null => false
    t.boolean  "rederivation_started",             :default => false, :null => false
    t.boolean  "rederivation_complete",            :default => false, :null => false
    t.integer  "number_of_cre_matings_started",    :default => 0,     :null => false
    t.integer  "number_of_cre_matings_successful", :default => 0,     :null => false
    t.boolean  "cre_excision",                     :default => true,  :null => false
    t.boolean  "tat_cre",                          :default => false
    t.integer  "deleter_strain_id"
    t.boolean  "is_active",                        :default => true,  :null => false
    t.boolean  "report_to_public",                 :default => true,  :null => false
    t.integer  "phenotype_attempt_id"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.integer  "allele_id"
    t.integer  "real_allele_id"
    t.integer  "parent_colony_id"
  end

  create_table "mutagenesis_factor_vectors", :force => true do |t|
    t.integer "mutagenesis_factor_id", :null => false
    t.integer "vector_id"
    t.float   "concentration"
    t.string  "preparation"
  end

  create_table "mutagenesis_factors", :force => true do |t|
    t.string  "external_ref"
    t.boolean "individually_set_grna_concentrations",     :default => false, :null => false
    t.boolean "guides_generated_in_plasmid",              :default => false, :null => false
    t.float   "grna_concentration"
    t.integer "no_g0_where_mutation_detected"
    t.integer "no_nhej_g0_mutants"
    t.integer "no_deletion_g0_mutants"
    t.integer "no_hr_g0_mutants"
    t.integer "no_hdr_g0_mutants"
    t.integer "no_hdr_g0_mutants_all_donors_inserted"
    t.integer "no_hdr_g0_mutants_subset_donors_inserted"
    t.boolean "private",                                  :default => false, :null => false
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

  create_table "phenotype_attempt_ids", :force => true do |t|
  end

  create_table "phenotyping_production_status_stamps", :force => true do |t|
    t.integer  "phenotyping_production_id", :null => false
    t.integer  "status_id",                 :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "phenotyping_production_statuses", :force => true do |t|
    t.string  "name",     :limit => 50, :null => false
    t.integer "order_by",               :null => false
    t.string  "code",     :limit => 4,  :null => false
  end

  create_table "phenotyping_productions", :force => true do |t|
    t.integer  "mi_plan_id",                                         :null => false
    t.integer  "status_id",                                          :null => false
    t.string   "colony_name"
    t.date     "phenotyping_experiments_started"
    t.boolean  "phenotyping_started",             :default => false, :null => false
    t.boolean  "phenotyping_complete",            :default => false, :null => false
    t.boolean  "is_active",                       :default => true,  :null => false
    t.boolean  "report_to_public",                :default => true,  :null => false
    t.integer  "phenotype_attempt_id"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.date     "ready_for_website"
    t.integer  "parent_colony_id"
    t.integer  "colony_background_strain_id"
    t.boolean  "rederivation_started",            :default => false, :null => false
    t.boolean  "rederivation_complete",           :default => false, :null => false
    t.integer  "cohort_production_centre_id"
  end

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
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "crispr_mi_goal"
    t.integer  "crispr_gc_goal"
    t.integer  "total_mi_goal"
    t.integer  "total_gc_goal"
  end

  add_index "production_goals", ["consortium_id", "year", "month"], :name => "index_production_goals_on_consortium_id_and_year_and_month", :unique => true

  create_table "qc_results", :force => true do |t|
    t.string   "description", :limit => 50, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "qc_results", ["description"], :name => "index_qc_results_on_description", :unique => true

  create_table "reagent_names", :force => true do |t|
    t.string "name",        :null => false
    t.text   "description"
  end

  create_table "reagents", :force => true do |t|
    t.integer "mi_attempt_id", :null => false
    t.integer "reagent_id",    :null => false
    t.float   "concentration"
  end

  create_table "report_caches", :force => true do |t|
    t.text     "name",       :null => false
    t.text     "data",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "format",     :null => false
  end

  add_index "report_caches", ["name", "format"], :name => "index_report_caches_on_name_and_format", :unique => true

  create_table "strains", :force => true do |t|
    t.string   "name",                    :limit => 100, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "mgi_strain_accession_id", :limit => 100
    t.string   "mgi_strain_name",         :limit => 100
  end

  add_index "strains", ["name"], :name => "index_strains_on_name", :unique => true

  create_table "targ_rep_allele_sequence_annotations", :force => true do |t|
    t.string  "mutation_type"
    t.string  "expected"
    t.string  "actual"
    t.text    "comment"
    t.integer "oligos_start_coordinate"
    t.integer "oligos_end_coordinate"
    t.integer "mutation_length"
    t.integer "genomic_start_coordinate"
    t.integer "genomic_end_coordinate"
    t.integer "allele_id"
  end

  create_table "targ_rep_alleles", :force => true do |t|
    t.integer  "gene_id"
    t.string   "assembly",                                      :default => "GRCm38",                  :null => false
    t.string   "chromosome",                     :limit => 2,                                          :null => false
    t.string   "strand",                         :limit => 1,                                          :null => false
    t.integer  "homology_arm_start"
    t.integer  "homology_arm_end"
    t.integer  "loxp_start"
    t.integer  "loxp_end"
    t.integer  "cassette_start"
    t.integer  "cassette_end"
    t.string   "cassette",                       :limit => 100
    t.string   "backbone",                       :limit => 100
    t.string   "subtype_description"
    t.string   "floxed_start_exon"
    t.string   "floxed_end_exon"
    t.integer  "project_design_id"
    t.string   "reporter"
    t.integer  "mutation_method_id"
    t.integer  "mutation_type_id"
    t.integer  "mutation_subtype_id"
    t.string   "cassette_type",                  :limit => 50
    t.datetime "created_at",                                                                           :null => false
    t.datetime "updated_at",                                                                           :null => false
    t.integer  "intron"
    t.string   "type",                                          :default => "TargRep::TargetedAllele"
    t.boolean  "has_issue",                                     :default => false,                     :null => false
    t.text     "issue_description"
    t.text     "sequence"
    t.string   "taqman_critical_del_assay_id"
    t.string   "taqman_upstream_del_assay_id"
    t.string   "taqman_downstream_del_assay_id"
    t.string   "wildtype_oligos_sequence"
    t.boolean  "private",                                       :default => false,                     :null => false
    t.integer  "production_centre_id"
  end

  create_table "targ_rep_centre_pipelines", :force => true do |t|
    t.string   "name"
    t.text     "centres"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "targ_rep_crisprs", :force => true do |t|
    t.integer  "mutagenesis_factor_id",                    :null => false
    t.string   "sequence",                                 :null => false
    t.string   "chr"
    t.integer  "start"
    t.integer  "end"
    t.datetime "created_at"
    t.boolean  "truncated_guide",       :default => false
    t.float    "grna_concentration"
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
    t.integer  "real_allele_id"
  end

  add_index "targ_rep_es_cells", ["allele_id"], :name => "es_cells_allele_id_fk"
  add_index "targ_rep_es_cells", ["name"], :name => "targ_rep_index_es_cells_on_name", :unique => true
  add_index "targ_rep_es_cells", ["pipeline_id"], :name => "es_cells_pipeline_id_fk"

  create_table "targ_rep_genbank_files", :force => true do |t|
    t.integer  "allele_id",           :null => false
    t.text     "escell_clone"
    t.text     "targeting_vector"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "allele_genbank_file"
  end

  add_index "targ_rep_genbank_files", ["allele_id"], :name => "genbank_files_allele_id_fk"

  create_table "targ_rep_genotype_primers", :force => true do |t|
    t.string  "sequence",                 :null => false
    t.string  "name"
    t.integer "genomic_start_coordinate"
    t.integer "genomic_end_coordinate"
    t.integer "mutagenesis_factor_id"
    t.integer "allele_id"
  end

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
    t.string   "name",          :limit => 100, :null => false
    t.string   "code",          :limit => 100, :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.string   "allele_prefix", :limit => 5
  end

  create_table "targ_rep_mutation_subtypes", :force => true do |t|
    t.string   "name",       :limit => 100, :null => false
    t.string   "code",       :limit => 100, :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "targ_rep_mutation_types", :force => true do |t|
    t.string   "name",        :limit => 100, :null => false
    t.string   "code",        :limit => 100, :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.string   "allele_code", :limit => 5
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

  create_table "targ_rep_real_alleles", :force => true do |t|
    t.integer "gene_id",                        :null => false
    t.string  "allele_name",      :limit => 40, :null => false
    t.string  "allele_type",      :limit => 10
    t.string  "mgi_accession_id"
  end

  add_index "targ_rep_real_alleles", ["gene_id", "allele_name"], :name => "real_allele_logical_key", :unique => true

  create_table "targ_rep_sequence_annotation", :force => true do |t|
    t.integer "coordinate_start"
    t.string  "expected_sequence"
    t.string  "actual_sequence"
    t.integer "allele_id"
  end

  create_table "targ_rep_targeting_vectors", :force => true do |t|
    t.integer  "allele_id",                                                     :null => false
    t.string   "name",                                                          :null => false
    t.string   "ikmc_project_id"
    t.string   "intermediate_vector"
    t.boolean  "report_to_public",                                              :null => false
    t.integer  "pipeline_id"
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
    t.integer  "ikmc_project_foreign_id"
    t.string   "mgi_allele_name_prediction",    :limit => 40
    t.string   "allele_type_prediction",        :limit => 10
    t.boolean  "production_centre_auto_update",               :default => true, :null => false
  end

  add_index "targ_rep_targeting_vectors", ["allele_id"], :name => "targeting_vectors_allele_id_fk"
  add_index "targ_rep_targeting_vectors", ["name"], :name => "index_targvec", :unique => true
  add_index "targ_rep_targeting_vectors", ["pipeline_id"], :name => "targeting_vectors_pipeline_id_fk"

  create_table "trace_call_vcf_modifications", :force => true do |t|
    t.integer  "trace_call_id", :null => false
    t.string   "mod_type",      :null => false
    t.string   "chr",           :null => false
    t.integer  "start",         :null => false
    t.integer  "end",           :null => false
    t.text     "ref_seq",       :null => false
    t.text     "alt_seq",       :null => false
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "trace_calls", :force => true do |t|
    t.integer  "colony_id",                      :null => false
    t.integer  "mutagenesis_factor_id",          :null => false
    t.text     "file_alignment"
    t.text     "file_filtered_analysis_vcf"
    t.text     "file_variant_effect_output_txt"
    t.text     "file_reference_fa"
    t.text     "file_mutant_fa"
    t.text     "file_primer_reads_fa"
    t.text     "file_alignment_data_yaml"
    t.text     "file_trace_output"
    t.text     "file_trace_error"
    t.text     "file_exception_details"
    t.integer  "file_return_code"
    t.text     "file_merged_variants_vcf"
    t.string   "exon_id"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  create_table "trace_files", :force => true do |t|
    t.integer  "colony_id",                                :null => false
    t.boolean  "is_het",                :default => false, :null => false
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.string   "trace_file_name"
    t.string   "trace_content_type"
    t.integer  "trace_file_size"
    t.datetime "trace_updated_at"
    t.integer  "mutagenesis_factor_id"
  end

  create_table "traces", :force => true do |t|
    t.string   "style"
    t.binary   "file_contents"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "trace_file_id", :null => false
  end

  create_table "tracking_goals", :force => true do |t|
    t.integer  "production_centre_id"
    t.date     "date"
    t.string   "goal_type"
    t.integer  "goal"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.integer  "consortium_id"
    t.integer  "crispr_goal",          :default => 0
    t.integer  "total_goal",           :default => 0
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

  add_foreign_key "colonies", "mi_attempts", :name => "colonies_mi_attempt_fk"
  add_foreign_key "colonies", "mouse_allele_mods", :name => "colonies_mouse_allele_mod_fk"

  add_foreign_key "colony_qcs", "colonies", :name => "colony_qcs_colonies_fk"

  add_foreign_key "mi_attempt_status_stamps", "mi_attempt_statuses", :name => "mi_attempt_status_stamps_mi_attempt_status_id_fk", :column => "status_id"

  add_foreign_key "mi_attempts", "mi_attempt_statuses", :name => "mi_attempts_mi_attempt_status_id_fk", :column => "status_id"
  add_foreign_key "mi_attempts", "mi_plans", :name => "mi_attempts_mi_plan_id_fk"
  add_foreign_key "mi_attempts", "strains", :name => "mi_attempts_blast_strain_id_fk", :column => "blast_strain_id"
  add_foreign_key "mi_attempts", "strains", :name => "mi_attempts_test_cross_strain_id_fk", :column => "test_cross_strain_id"
  add_foreign_key "mi_attempts", "targ_rep_alleles", :name => "mi_attempts_targ_rep_allele_id_fk", :column => "allele_id"
  add_foreign_key "mi_attempts", "targ_rep_real_alleles", :name => "mi_attempts_targ_rep_real_allele_id_fk", :column => "real_allele_id"
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

  add_foreign_key "mouse_allele_mod_status_stamps", "mouse_allele_mod_statuses", :name => "mouse_allele_mod_status_stamps_status_id_fk", :column => "status_id"
  add_foreign_key "mouse_allele_mod_status_stamps", "mouse_allele_mods", :name => "fk_mouse_allele_mods"

  add_foreign_key "mouse_allele_mods", "mi_plans", :name => "mouse_allele_mods_mi_plan_id_fk"
  add_foreign_key "mouse_allele_mods", "mouse_allele_mod_statuses", :name => "mouse_allele_mods_status_id_fk", :column => "status_id"
  add_foreign_key "mouse_allele_mods", "phenotype_attempt_ids", :name => "mouse_allele_mods_phenotype_attempt_id_fk", :column => "phenotype_attempt_id"
  add_foreign_key "mouse_allele_mods", "strains", :name => "mouse_allele_mods_deleter_strain_id_fk", :column => "deleter_strain_id"
  add_foreign_key "mouse_allele_mods", "targ_rep_alleles", :name => "mouse_allele_mods_targ_rep_allele_id_fk", :column => "allele_id"
  add_foreign_key "mouse_allele_mods", "targ_rep_real_alleles", :name => "mouse_allele_mods_targ_rep_real_allele_id_fk", :column => "real_allele_id"

  add_foreign_key "notifications", "contacts", :name => "notifications_contact_id_fk"
  add_foreign_key "notifications", "genes", :name => "notifications_gene_id_fk"

  add_foreign_key "phenotyping_production_status_stamps", "phenotyping_production_statuses", :name => "phenotyping_production_status_stamps_status_id_fk", :column => "status_id"
  add_foreign_key "phenotyping_production_status_stamps", "phenotyping_productions", :name => "fk_phenotyping_productions"

  add_foreign_key "phenotyping_productions", "mi_plans", :name => "phenotyping_productions_mi_plan_id_fk"
  add_foreign_key "phenotyping_productions", "phenotype_attempt_ids", :name => "phenotyping_productions_phenotype_attempt_id_fk", :column => "phenotype_attempt_id"
  add_foreign_key "phenotyping_productions", "phenotyping_production_statuses", :name => "phenotyping_productions_status_id_fk", :column => "status_id"

  add_foreign_key "targ_rep_allele_sequence_annotations", "targ_rep_alleles", :name => "targ_rep_allele_sequence_annotations_allele_id_fk", :column => "allele_id"

  add_foreign_key "targ_rep_es_cells", "centres", :name => "targ_rep_es_cells_user_qc_mouse_clinic_id_fk", :column => "user_qc_mouse_clinic_id"
  add_foreign_key "targ_rep_es_cells", "targ_rep_real_alleles", :name => "targ_rep_es_cells_targ_rep_real_allele_id_fk", :column => "real_allele_id"

  add_foreign_key "targ_rep_genotype_primers", "mutagenesis_factors", :name => "targ_rep_genotype_primers_mutagenesis_factor_id_fk"
  add_foreign_key "targ_rep_genotype_primers", "targ_rep_alleles", :name => "targ_rep_genotype_primers_allele_id_fk", :column => "allele_id"

  add_foreign_key "targ_rep_real_alleles", "genes", :name => "targ_rep_real_alleles_gene_id_fk"

  add_foreign_key "trace_call_vcf_modifications", "trace_files", :name => "trace_call_vcf_modifications_trace_calls_fk", :column => "trace_call_id"

  add_foreign_key "trace_files", "colonies", :name => "trace_calls_colonies_fk"

  add_foreign_key "users", "targ_rep_es_cell_distribution_centres", :name => "users_es_cell_distribution_centre_id_fk", :column => "es_cell_distribution_centre_id"

end
