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

ActiveRecord::Schema.define(:version => 20140710144500) do

  create_table "assemblies", :id => false, :force => true do |t|
    t.text "id",         :null => false
    t.text "species_id", :null => false
  end

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

  create_table "bac_clone_loci", :id => false, :force => true do |t|
    t.integer "bac_clone_id", :null => false
    t.text    "assembly_id",  :null => false
    t.integer "chr_start",    :null => false
    t.integer "chr_end",      :null => false
    t.integer "chr_id",       :null => false
  end

  create_table "bac_clones", :force => true do |t|
    t.text "name",           :null => false
    t.text "bac_library_id", :null => false
  end

  add_index "bac_clones", ["name", "bac_library_id"], :name => "bac_clones_name_bac_library_id_key", :unique => true

  create_table "bac_libraries", :id => false, :force => true do |t|
    t.text "id",         :null => false
    t.text "species_id", :null => false
  end

  create_table "backbones", :force => true do |t|
    t.text "name",                           :null => false
    t.text "description",    :default => "", :null => false
    t.text "antibiotic_res", :default => "", :null => false
    t.text "gateway_type",   :default => "", :null => false
  end

  add_index "backbones", ["name"], :name => "backbones_name_key", :unique => true

  create_table "cached_reports", :id => false, :force => true do |t|
    t.string   "id",           :limit => 36,                    :null => false
    t.text     "report_class",                                  :null => false
    t.text     "params",                                        :null => false
    t.datetime "expires",                                       :null => false
    t.boolean  "complete",                   :default => false, :null => false
  end

  add_index "cached_reports", ["report_class", "params"], :name => "cached_reports_report_class_params_idx"

  create_table "cassette_function", :id => false, :force => true do |t|
    t.text    "id",                      :null => false
    t.boolean "promoter"
    t.boolean "conditional"
    t.boolean "cre"
    t.boolean "well_has_cre"
    t.boolean "well_has_no_recombinase"
  end

  create_table "cassettes", :force => true do |t|
    t.text    "name",                                 :null => false
    t.text    "description",       :default => "",    :null => false
    t.boolean "promoter",                             :null => false
    t.text    "phase_match_group"
    t.integer "phase"
    t.boolean "conditional",       :default => false, :null => false
    t.boolean "cre",               :default => false, :null => false
    t.text    "resistance"
  end

  add_index "cassettes", ["name"], :name => "cassettes_name_key", :unique => true

  create_table "cell_lines", :force => true do |t|
    t.text "name", :default => "", :null => false
  end

  create_table "centres", :force => true do |t|
    t.string   "name",          :limit => 100, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "contact_name",  :limit => 100
    t.string   "contact_email", :limit => 100
  end

  add_index "centres", ["name"], :name => "index_centres_on_name", :unique => true

  create_table "chromosomes", :force => true do |t|
    t.text "species_id", :null => false
    t.text "name",       :null => false
  end

  add_index "chromosomes", ["species_id", "name"], :name => "new_chromosomes_species_id_name_key", :unique => true

  create_table "colony_count_types", :id => false, :force => true do |t|
    t.text "id", :null => false
  end

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

  create_table "crispr_designs", :force => true do |t|
    t.integer "crispr_id"
    t.integer "crispr_pair_id"
    t.integer "design_id",                         :null => false
    t.boolean "plated",         :default => false, :null => false
  end

  add_index "crispr_designs", ["design_id", "crispr_id"], :name => "unique_crispr_design", :unique => true
  add_index "crispr_designs", ["design_id", "crispr_pair_id"], :name => "unique_crispr_pair_design", :unique => true

  create_table "crispr_es_qc_runs", :id => false, :force => true do |t|
    t.string   "id",                 :limit => 36, :null => false
    t.text     "sequencing_project",               :null => false
    t.datetime "created_at",                       :null => false
    t.integer  "created_by_id",                    :null => false
    t.text     "species_id",                       :null => false
    t.text     "sub_project"
  end

  create_table "crispr_es_qc_wells", :force => true do |t|
    t.string  "crispr_es_qc_run_id", :limit => 36,                    :null => false
    t.integer "well_id",                                              :null => false
    t.text    "fwd_read"
    t.text    "rev_read"
    t.integer "crispr_chr_id",                                        :null => false
    t.integer "crispr_start",                                         :null => false
    t.integer "crispr_end",                                           :null => false
    t.text    "comment"
    t.text    "analysis_data",                                        :null => false
    t.boolean "accepted",                          :default => false, :null => false
    t.text    "vcf_file"
  end

  create_table "crispr_loci", :id => false, :force => true do |t|
    t.integer "crispr_id",   :null => false
    t.text    "assembly_id", :null => false
    t.integer "chr_id",      :null => false
    t.integer "chr_start",   :null => false
    t.integer "chr_end",     :null => false
    t.integer "chr_strand",  :null => false
  end

  create_table "crispr_loci_types", :id => false, :force => true do |t|
    t.text "id", :null => false
  end

  create_table "crispr_off_target_summaries", :force => true do |t|
    t.integer "crispr_id", :null => false
    t.boolean "outlier",   :null => false
    t.text    "algorithm", :null => false
    t.text    "summary"
  end

  create_table "crispr_off_targets", :force => true do |t|
    t.integer "crispr_id",           :null => false
    t.text    "crispr_loci_type_id", :null => false
    t.text    "assembly_id",         :null => false
    t.integer "build_id",            :null => false
    t.integer "chr_start",           :null => false
    t.integer "chr_end",             :null => false
    t.integer "chr_strand",          :null => false
    t.text    "chromosome"
    t.text    "algorithm",           :null => false
  end

  create_table "crispr_pairs", :force => true do |t|
    t.integer "left_crispr_id",     :null => false
    t.integer "right_crispr_id",    :null => false
    t.integer "spacer",             :null => false
    t.text    "off_target_summary"
  end

  add_index "crispr_pairs", ["left_crispr_id", "right_crispr_id"], :name => "unique_pair", :unique => true

  create_table "crispr_primer_types", :id => false, :force => true do |t|
    t.text "primer_name", :null => false
  end

  create_table "crispr_primers", :primary_key => "crispr_oligo_id", :force => true do |t|
    t.integer "crispr_pair_id"
    t.integer "crispr_id"
    t.text    "primer_name",                                  :null => false
    t.text    "primer_seq",                                   :null => false
    t.decimal "tm",             :precision => 5, :scale => 3
    t.decimal "gc_content",     :precision => 5, :scale => 3
  end

  add_index "crispr_primers", ["crispr_id", "primer_name"], :name => "crispr_id and primer name must be unique", :unique => true
  add_index "crispr_primers", ["crispr_pair_id", "primer_name"], :name => "crispr_pair_id and primer name must be unique", :unique => true

  create_table "crispr_primers_loci", :id => false, :force => true do |t|
    t.integer "crispr_oligo_id", :null => false
    t.text    "assembly_id",     :null => false
    t.integer "chr_id",          :null => false
    t.integer "chr_start",       :null => false
    t.integer "chr_end",         :null => false
    t.integer "chr_strand",      :null => false
  end

  create_table "crisprs", :force => true do |t|
    t.text    "seq",                 :null => false
    t.text    "species_id",          :null => false
    t.text    "crispr_loci_type_id", :null => false
    t.text    "comment"
    t.boolean "pam_right"
    t.integer "wge_crispr_id"
  end

  add_index "crisprs", ["wge_crispr_id"], :name => "crisprs_wge_crispr_id_key", :unique => true

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

  create_table "design_attempts", :force => true do |t|
    t.text     "design_parameters"
    t.text     "gene_id"
    t.text     "status"
    t.text     "fail"
    t.text     "error"
    t.text     "design_ids"
    t.text     "species_id",        :null => false
    t.integer  "created_by",        :null => false
    t.datetime "created_at",        :null => false
    t.text     "comment"
    t.text     "candidate_oligos"
    t.text     "candidate_regions"
  end

  create_table "design_comment_categories", :force => true do |t|
    t.text "name", :null => false
  end

  add_index "design_comment_categories", ["name"], :name => "design_comment_categories_name_key", :unique => true

  create_table "design_comments", :force => true do |t|
    t.integer  "design_comment_category_id",                    :null => false
    t.integer  "design_id",                                     :null => false
    t.text     "comment_text",               :default => "",    :null => false
    t.boolean  "is_public",                  :default => false, :null => false
    t.integer  "created_by",                                    :null => false
    t.datetime "created_at",                                    :null => false
  end

  create_table "design_oligo_loci", :id => false, :force => true do |t|
    t.integer "design_oligo_id", :null => false
    t.text    "assembly_id",     :null => false
    t.integer "chr_start",       :null => false
    t.integer "chr_end",         :null => false
    t.integer "chr_strand",      :null => false
    t.integer "chr_id",          :null => false
  end

  create_table "design_oligo_types", :id => false, :force => true do |t|
    t.text "id", :null => false
  end

  create_table "design_oligos", :force => true do |t|
    t.integer "design_id",            :null => false
    t.text    "design_oligo_type_id", :null => false
    t.text    "seq",                  :null => false
  end

  add_index "design_oligos", ["design_id", "design_oligo_type_id"], :name => "design_oligos_design_id_design_oligo_type_id_key", :unique => true

  create_table "design_targets", :force => true do |t|
    t.text    "marker_symbol"
    t.text    "ensembl_gene_id",      :null => false
    t.text    "ensembl_exon_id",      :null => false
    t.integer "exon_size",            :null => false
    t.integer "exon_rank"
    t.text    "canonical_transcript"
    t.text    "species_id",           :null => false
    t.text    "assembly_id",          :null => false
    t.integer "build_id",             :null => false
    t.integer "chr_id",               :null => false
    t.integer "chr_start",            :null => false
    t.integer "chr_end",              :null => false
    t.integer "chr_strand",           :null => false
    t.boolean "automatically_picked", :null => false
    t.text    "comment"
    t.text    "gene_id"
  end

  add_index "design_targets", ["ensembl_exon_id", "build_id"], :name => "design_targets_unique_target", :unique => true

  create_table "design_types", :id => false, :force => true do |t|
    t.text "id", :null => false
  end

  create_table "designs", :force => true do |t|
    t.text     "name"
    t.integer  "created_by",                                :null => false
    t.datetime "created_at",                                :null => false
    t.text     "design_type_id",                            :null => false
    t.integer  "phase"
    t.text     "validated_by_annotation",                   :null => false
    t.text     "target_transcript"
    t.text     "species_id",                                :null => false
    t.text     "design_parameters"
    t.boolean  "cassette_first",          :default => true, :null => false
    t.integer  "global_arm_shortened"
  end

  add_index "designs", ["target_transcript"], :name => "designs_target_transcript_idx"

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

  create_table "gene_design", :id => false, :force => true do |t|
    t.text     "gene_id",      :null => false
    t.integer  "design_id",    :null => false
    t.integer  "created_by",   :null => false
    t.datetime "created_at",   :null => false
    t.text     "gene_type_id", :null => false
  end

  add_index "gene_design", ["design_id"], :name => "gene_design_design_id_idx"
  add_index "gene_design", ["gene_id"], :name => "gene_design_gene_id_idx"

  create_table "gene_types", :id => false, :force => true do |t|
    t.text    "id",          :null => false
    t.text    "description"
    t.boolean "local",       :null => false
  end

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
  end

  add_index "genes", ["marker_symbol"], :name => "index_genes_on_marker_symbol", :unique => true
  add_index "genes", ["mgi_accession_id"], :name => "index_genes_on_mgi_accession_id", :unique => true

  create_table "genotyping_primer_types", :id => false, :force => true do |t|
    t.text "id", :null => false
  end

  create_table "genotyping_primers", :force => true do |t|
    t.text    "genotyping_primer_type_id",                               :null => false
    t.integer "design_id",                                               :null => false
    t.text    "seq",                                                     :null => false
    t.decimal "tm",                        :precision => 5, :scale => 3
    t.decimal "gc_content",                :precision => 5, :scale => 3
  end

  create_table "genotyping_primers_loci", :id => false, :force => true do |t|
    t.integer "genotyping_primer_id", :null => false
    t.text    "assembly_id",          :null => false
    t.integer "chr_id",               :null => false
    t.integer "chr_start",            :null => false
    t.integer "chr_end",              :null => false
    t.integer "chr_strand",           :null => false
  end

  create_table "genotyping_result_types", :id => false, :force => true do |t|
    t.text "id", :null => false
  end

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
    t.integer  "founder_loa_num_assays"
    t.integer  "founder_loa_num_positive_results"
    t.integer  "allele_id"
    t.integer  "real_allele_id"
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
    t.integer  "mi_plan_id",                                                            :null => false
    t.integer  "mi_attempt_id",                                                         :null => false
    t.integer  "status_id",                                                             :null => false
    t.boolean  "rederivation_started",                               :default => false, :null => false
    t.boolean  "rederivation_complete",                              :default => false, :null => false
    t.integer  "number_of_cre_matings_started",                      :default => 0,     :null => false
    t.integer  "number_of_cre_matings_successful",                   :default => 0,     :null => false
    t.boolean  "no_modification_required",                           :default => false
    t.boolean  "cre_excision",                                       :default => true,  :null => false
    t.boolean  "tat_cre",                                            :default => false
    t.string   "mouse_allele_type",                   :limit => 3
    t.string   "allele_category"
    t.integer  "deleter_strain_id"
    t.integer  "colony_background_strain_id"
    t.string   "colony_name",                         :limit => 125,                    :null => false
    t.boolean  "is_active",                                          :default => true,  :null => false
    t.boolean  "report_to_public",                                   :default => true,  :null => false
    t.integer  "phenotype_attempt_id"
    t.datetime "created_at",                                                            :null => false
    t.datetime "updated_at",                                                            :null => false
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
    t.integer  "allele_id"
    t.integer  "real_allele_id"
    t.string   "allele_name"
    t.string   "allele_mgi_accession_id"
  end

  create_table "mutagenesis_factors", :force => true do |t|
    t.integer "vector_id"
  end

  create_table "mutation_design_types", :id => false, :force => true do |t|
    t.text "mutation_id", :null => false
    t.text "design_type", :null => false
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

  create_table "new_intermediate_report_summary_by_centre_and_consortia", :force => true do |t|
    t.integer  "mi_plan_id"
    t.integer  "mi_attempt_id"
    t.integer  "mouse_allele_mod_id"
    t.integer  "phenotyping_production_id"
    t.string   "overall_status",                                :limit => 50
    t.string   "mi_plan_status",                                :limit => 50
    t.string   "mi_attempt_status",                             :limit => 50
    t.string   "phenotype_attempt_status",                      :limit => 50
    t.string   "consortium",                                                   :null => false
    t.string   "production_centre"
    t.string   "gene",                                          :limit => 75,  :null => false
    t.string   "mgi_accession_id",                              :limit => 40
    t.date     "gene_interest_date"
    t.string   "mi_attempt_colony_name"
    t.string   "mouse_allele_mod_colony_name"
    t.string   "production_colony_name"
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
    t.date     "phenotyping_experiments_started_date"
    t.date     "phenotyping_complete_date"
    t.date     "phenotype_attempt_aborted_date"
    t.string   "phenotyping_mi_attempt_consortium"
    t.string   "phenotyping_mi_attempt_production_centre"
    t.string   "tm1b_phenotype_attempt_status"
    t.date     "tm1b_phenotype_attempt_registered_date"
    t.date     "tm1b_rederivation_started_date"
    t.date     "tm1b_rederivation_complete_date"
    t.date     "tm1b_cre_excision_started_date"
    t.date     "tm1b_cre_excision_complete_date"
    t.date     "tm1b_phenotyping_started_date"
    t.date     "tm1b_phenotyping_experiments_started_date"
    t.date     "tm1b_phenotyping_complete_date"
    t.date     "tm1b_phenotype_attempt_aborted_date"
    t.string   "tm1b_colony_name"
    t.string   "tm1b_phenotyping_production_colony_name"
    t.string   "tm1b_phenotyping_mi_attempt_consortium"
    t.string   "tm1b_phenotyping_mi_attempt_production_centre"
    t.string   "tm1a_phenotype_attempt_status"
    t.date     "tm1a_phenotype_attempt_registered_date"
    t.date     "tm1a_rederivation_started_date"
    t.date     "tm1a_rederivation_complete_date"
    t.date     "tm1a_cre_excision_started_date"
    t.date     "tm1a_cre_excision_complete_date"
    t.date     "tm1a_phenotyping_started_date"
    t.date     "tm1a_phenotyping_experiments_started_date"
    t.date     "tm1a_phenotyping_complete_date"
    t.date     "tm1a_phenotype_attempt_aborted_date"
    t.string   "tm1a_colony_name"
    t.string   "tm1a_phenotyping_production_colony_name"
    t.string   "tm1a_phenotyping_mi_attempt_consortium"
    t.string   "tm1a_phenotyping_mi_attempt_production_centre"
    t.integer  "distinct_genotype_confirmed_es_cells"
    t.integer  "distinct_old_genotype_confirmed_es_cells"
    t.integer  "distinct_non_genotype_confirmed_es_cells"
    t.integer  "distinct_old_non_genotype_confirmed_es_cells"
    t.integer  "total_pipeline_efficiency_gene_count"
    t.integer  "total_old_pipeline_efficiency_gene_count"
    t.integer  "gc_pipeline_efficiency_gene_count"
    t.integer  "gc_old_pipeline_efficiency_gene_count"
    t.datetime "created_at"
    t.string   "sub_project"
    t.string   "mutation_sub_type",                             :limit => 100
  end

  create_table "new_intermediate_report_summary_by_consortia", :force => true do |t|
    t.integer  "mi_plan_id"
    t.integer  "mi_attempt_id"
    t.integer  "mouse_allele_mod_id"
    t.integer  "phenotyping_production_id"
    t.string   "overall_status",                                :limit => 50
    t.string   "mi_plan_status",                                :limit => 50
    t.string   "mi_attempt_status",                             :limit => 50
    t.string   "phenotype_attempt_status",                      :limit => 50
    t.string   "consortium",                                                   :null => false
    t.string   "gene",                                          :limit => 75,  :null => false
    t.string   "mgi_accession_id",                              :limit => 40
    t.date     "gene_interest_date"
    t.string   "mi_attempt_colony_name"
    t.string   "mouse_allele_mod_colony_name"
    t.string   "production_colony_name"
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
    t.date     "phenotyping_experiments_started_date"
    t.date     "phenotyping_complete_date"
    t.date     "phenotype_attempt_aborted_date"
    t.string   "phenotyping_mi_attempt_consortium"
    t.string   "phenotyping_mi_attempt_production_centre"
    t.string   "tm1b_phenotype_attempt_status"
    t.date     "tm1b_phenotype_attempt_registered_date"
    t.date     "tm1b_rederivation_started_date"
    t.date     "tm1b_rederivation_complete_date"
    t.date     "tm1b_cre_excision_started_date"
    t.date     "tm1b_cre_excision_complete_date"
    t.date     "tm1b_phenotyping_started_date"
    t.date     "tm1b_phenotyping_experiments_started_date"
    t.date     "tm1b_phenotyping_complete_date"
    t.date     "tm1b_phenotype_attempt_aborted_date"
    t.string   "tm1b_colony_name"
    t.string   "tm1b_phenotyping_production_colony_name"
    t.string   "tm1b_phenotyping_mi_attempt_consortium"
    t.string   "tm1b_phenotyping_mi_attempt_production_centre"
    t.string   "tm1a_phenotype_attempt_status"
    t.date     "tm1a_phenotype_attempt_registered_date"
    t.date     "tm1a_rederivation_started_date"
    t.date     "tm1a_rederivation_complete_date"
    t.date     "tm1a_cre_excision_started_date"
    t.date     "tm1a_cre_excision_complete_date"
    t.date     "tm1a_phenotyping_started_date"
    t.date     "tm1a_phenotyping_experiments_started_date"
    t.date     "tm1a_phenotyping_complete_date"
    t.date     "tm1a_phenotype_attempt_aborted_date"
    t.string   "tm1a_colony_name"
    t.string   "tm1a_phenotyping_production_colony_name"
    t.string   "tm1a_phenotyping_mi_attempt_consortium"
    t.string   "tm1a_phenotyping_mi_attempt_production_centre"
    t.integer  "distinct_genotype_confirmed_es_cells"
    t.integer  "distinct_old_genotype_confirmed_es_cells"
    t.integer  "distinct_non_genotype_confirmed_es_cells"
    t.integer  "distinct_old_non_genotype_confirmed_es_cells"
    t.integer  "total_pipeline_efficiency_gene_count"
    t.integer  "total_old_pipeline_efficiency_gene_count"
    t.integer  "gc_pipeline_efficiency_gene_count"
    t.integer  "gc_old_pipeline_efficiency_gene_count"
    t.datetime "created_at"
    t.string   "sub_project"
    t.string   "mutation_sub_type",                             :limit => 100
  end

  create_table "new_intermediate_report_summary_by_mi_plan", :force => true do |t|
    t.integer  "mi_plan_id",                                                                      :null => false
    t.string   "overall_status",                                :limit => 50
    t.string   "mi_plan_status",                                :limit => 50
    t.string   "mi_attempt_status",                             :limit => 50
    t.string   "phenotype_attempt_status",                      :limit => 50
    t.string   "consortium",                                                                      :null => false
    t.string   "production_centre"
    t.string   "sub_project"
    t.string   "priority"
    t.string   "gene"
    t.string   "mgi_accession_id",                              :limit => 40
    t.boolean  "is_bespoke_allele"
    t.string   "ikmc_project_id"
    t.string   "mutation_sub_type",                             :limit => 100
    t.string   "allele_symbol"
    t.string   "genetic_background"
    t.string   "mi_attempt_colony_name"
    t.string   "mouse_allele_mod_colony_name"
    t.string   "production_colony_name"
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
    t.date     "phenotyping_experiments_started_date"
    t.date     "phenotyping_complete_date"
    t.date     "phenotype_attempt_aborted_date"
    t.string   "phenotyping_mi_attempt_consortium"
    t.string   "phenotyping_mi_attempt_production_centre"
    t.string   "tm1b_phenotype_attempt_status"
    t.date     "tm1b_phenotype_attempt_registered_date"
    t.date     "tm1b_rederivation_started_date"
    t.date     "tm1b_rederivation_complete_date"
    t.date     "tm1b_cre_excision_started_date"
    t.date     "tm1b_cre_excision_complete_date"
    t.date     "tm1b_phenotyping_started_date"
    t.date     "tm1b_phenotyping_experiments_started_date"
    t.date     "tm1b_phenotyping_complete_date"
    t.date     "tm1b_phenotype_attempt_aborted_date"
    t.string   "tm1b_colony_name"
    t.string   "tm1b_phenotyping_production_colony_name"
    t.string   "tm1b_phenotyping_mi_attempt_consortium"
    t.string   "tm1b_phenotyping_mi_attempt_production_centre"
    t.string   "tm1a_phenotype_attempt_status"
    t.date     "tm1a_phenotype_attempt_registered_date"
    t.date     "tm1a_rederivation_started_date"
    t.date     "tm1a_rederivation_complete_date"
    t.date     "tm1a_cre_excision_started_date"
    t.date     "tm1a_cre_excision_complete_date"
    t.date     "tm1a_phenotyping_started_date"
    t.date     "tm1a_phenotyping_experiments_started_date"
    t.date     "tm1a_phenotyping_complete_date"
    t.date     "tm1a_phenotype_attempt_aborted_date"
    t.string   "tm1a_colony_name"
    t.string   "tm1a_phenotyping_production_colony_name"
    t.string   "tm1a_phenotyping_mi_attempt_consortium"
    t.string   "tm1a_phenotyping_mi_attempt_production_centre"
    t.integer  "distinct_genotype_confirmed_es_cells"
    t.integer  "distinct_old_genotype_confirmed_es_cells"
    t.integer  "distinct_non_genotype_confirmed_es_cells"
    t.integer  "distinct_old_non_genotype_confirmed_es_cells"
    t.integer  "total_pipeline_efficiency_gene_count"
    t.integer  "total_old_pipeline_efficiency_gene_count"
    t.integer  "gc_pipeline_efficiency_gene_count"
    t.integer  "gc_old_pipeline_efficiency_gene_count"
    t.datetime "created_at"
    t.boolean  "mutagenesis_via_crispr_cas9",                                  :default => false
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

  create_table "nucleases", :id => false, :force => true do |t|
    t.integer "id",   :null => false
    t.text    "name", :null => false
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
    t.integer  "mouse_allele_mod_id"
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
    t.string   "allele_name"
    t.string   "jax_mgi_accession_id"
    t.date     "ready_for_website"
    t.integer  "allele_id"
    t.integer  "real_allele_id"
  end

  add_index "phenotype_attempts", ["colony_name"], :name => "index_phenotype_attempts_on_colony_name", :unique => true

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
    t.integer  "mouse_allele_mod_id",                                :null => false
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
  end

  create_table "pipelines", :force => true do |t|
    t.string   "name",        :limit => 50, :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pipelines", ["name"], :name => "index_pipelines_on_name", :unique => true

  create_table "plate_comments", :force => true do |t|
    t.integer  "plate_id",      :null => false
    t.text     "comment_text",  :null => false
    t.integer  "created_by_id", :null => false
    t.datetime "created_at",    :null => false
  end

  create_table "plate_types", :id => false, :force => true do |t|
    t.text "id",                          :null => false
    t.text "description", :default => "", :null => false
  end

  create_table "plates", :force => true do |t|
    t.text     "name",                          :null => false
    t.text     "description",   :default => "", :null => false
    t.text     "type_id",                       :null => false
    t.integer  "created_by_id",                 :null => false
    t.datetime "created_at",                    :null => false
    t.text     "species_id",                    :null => false
    t.boolean  "is_virtual"
    t.text     "barcode"
    t.text     "sponsor_id"
  end

  add_index "plates", ["name"], :name => "plates_name_key", :unique => true

  create_table "primer_band_types", :id => false, :force => true do |t|
    t.text "id", :null => false
  end

  create_table "process_bac", :id => false, :force => true do |t|
    t.integer "process_id",   :null => false
    t.text    "bac_plate",    :null => false
    t.integer "bac_clone_id", :null => false
  end

  create_table "process_backbone", :id => false, :force => true do |t|
    t.integer "process_id",  :null => false
    t.integer "backbone_id", :null => false
  end

  create_table "process_cassette", :id => false, :force => true do |t|
    t.integer "process_id",  :null => false
    t.integer "cassette_id", :null => false
  end

  create_table "process_cell_line", :id => false, :force => true do |t|
    t.integer "process_id",   :null => false
    t.integer "cell_line_id"
  end

  create_table "process_crispr", :id => false, :force => true do |t|
    t.integer "process_id", :null => false
    t.integer "crispr_id",  :null => false
  end

  create_table "process_design", :id => false, :force => true do |t|
    t.integer "process_id", :null => false
    t.integer "design_id",  :null => false
  end

  create_table "process_global_arm_shortening_design", :id => false, :force => true do |t|
    t.integer "process_id", :null => false
    t.integer "design_id",  :null => false
  end

  create_table "process_input_well", :id => false, :force => true do |t|
    t.integer "process_id", :null => false
    t.integer "well_id",    :null => false
  end

  create_table "process_nuclease", :id => false, :force => true do |t|
    t.integer "process_id",  :null => false
    t.integer "nuclease_id", :null => false
  end

  create_table "process_output_well", :id => false, :force => true do |t|
    t.integer "process_id", :null => false
    t.integer "well_id",    :null => false
  end

  create_table "process_recombinase", :id => false, :force => true do |t|
    t.integer "process_id",     :null => false
    t.text    "recombinase_id", :null => false
    t.integer "rank",           :null => false
  end

  add_index "process_recombinase", ["process_id", "recombinase_id"], :name => "process_recombinase_process_id_recombinase_id_key", :unique => true

  create_table "process_types", :id => false, :force => true do |t|
    t.text "id",                          :null => false
    t.text "description", :default => "", :null => false
  end

  create_table "processes", :force => true do |t|
    t.text "type_id", :null => false
  end

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

  create_table "project_alleles", :id => false, :force => true do |t|
    t.integer "project_id",        :null => false
    t.text    "allele_type",       :null => false
    t.text    "cassette_function", :null => false
    t.text    "mutation_type",     :null => false
  end

  create_table "projects", :force => true do |t|
    t.text    "sponsor_id",                             :null => false
    t.text    "allele_request",                         :null => false
    t.text    "gene_id"
    t.text    "targeting_type",  :default => "unknown", :null => false
    t.text    "species_id"
    t.integer "htgt_project_id"
  end

  add_index "projects", ["sponsor_id", "gene_id", "targeting_type", "species_id"], :name => "sponsor_gene_type_species_key", :unique => true

  create_table "qc_alignment_regions", :id => false, :force => true do |t|
    t.integer "qc_alignment_id",                    :null => false
    t.text    "name",                               :null => false
    t.integer "length",                             :null => false
    t.integer "match_count",                        :null => false
    t.text    "query_str",                          :null => false
    t.text    "target_str",                         :null => false
    t.text    "match_str",                          :null => false
    t.boolean "pass",            :default => false, :null => false
  end

  create_table "qc_alignments", :force => true do |t|
    t.text    "qc_seq_read_id",                                  :null => false
    t.integer "qc_eng_seq_id",                                   :null => false
    t.text    "primer_name",                                     :null => false
    t.integer "query_start",                                     :null => false
    t.integer "query_end",                                       :null => false
    t.integer "query_strand",                                    :null => false
    t.integer "target_start",                                    :null => false
    t.integer "target_end",                                      :null => false
    t.integer "target_strand",                                   :null => false
    t.integer "score",                                           :null => false
    t.boolean "pass",                         :default => false, :null => false
    t.text    "features",                                        :null => false
    t.text    "cigar",                                           :null => false
    t.text    "op_str",                                          :null => false
    t.string  "qc_run_id",      :limit => 36
  end

  create_table "qc_eng_seqs", :force => true do |t|
    t.text "method", :null => false
    t.text "params", :null => false
  end

  add_index "qc_eng_seqs", ["method", "params"], :name => "qc_eng_seqs_method_params_key", :unique => true

  create_table "qc_results", :force => true do |t|
    t.string   "description", :limit => 50, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "qc_results", ["description"], :name => "index_qc_results_on_description", :unique => true

  create_table "qc_run_seq_project", :id => false, :force => true do |t|
    t.string "qc_run_id",         :limit => 36, :null => false
    t.text   "qc_seq_project_id",               :null => false
  end

  create_table "qc_run_seq_well_qc_seq_read", :id => false, :force => true do |t|
    t.integer "qc_run_seq_well_id", :null => false
    t.text    "qc_seq_read_id",     :null => false
  end

  create_table "qc_run_seq_wells", :force => true do |t|
    t.text "qc_run_id",  :null => false
    t.text "plate_name", :null => false
    t.text "well_name",  :null => false
  end

  add_index "qc_run_seq_wells", ["qc_run_id", "plate_name", "well_name"], :name => "qc_run_seq_wells_qc_run_id_plate_name_well_name_key", :unique => true

  create_table "qc_runs", :id => false, :force => true do |t|
    t.string   "id",               :limit => 36,                    :null => false
    t.datetime "created_at",                                        :null => false
    t.integer  "created_by_id",                                     :null => false
    t.text     "profile",                                           :null => false
    t.integer  "qc_template_id",                                    :null => false
    t.text     "software_version",                                  :null => false
    t.boolean  "upload_complete",                :default => false, :null => false
  end

  create_table "qc_seq_projects", :id => false, :force => true do |t|
    t.text "id",         :null => false
    t.text "species_id", :null => false
  end

  create_table "qc_seq_reads", :id => false, :force => true do |t|
    t.text    "id",                                :null => false
    t.text    "description",       :default => "", :null => false
    t.text    "primer_name",                       :null => false
    t.text    "seq",                               :null => false
    t.integer "length",                            :null => false
    t.text    "qc_seq_project_id",                 :null => false
  end

  create_table "qc_template_well_backbone", :id => false, :force => true do |t|
    t.integer "qc_template_well_id", :null => false
    t.integer "backbone_id",         :null => false
  end

  create_table "qc_template_well_cassette", :id => false, :force => true do |t|
    t.integer "qc_template_well_id", :null => false
    t.integer "cassette_id",         :null => false
  end

  create_table "qc_template_well_recombinase", :id => false, :force => true do |t|
    t.integer "qc_template_well_id", :null => false
    t.text    "recombinase_id",      :null => false
  end

  create_table "qc_template_wells", :force => true do |t|
    t.integer "qc_template_id", :null => false
    t.text    "name",           :null => false
    t.integer "qc_eng_seq_id",  :null => false
    t.integer "source_well_id"
  end

  add_index "qc_template_wells", ["qc_template_id", "name"], :name => "qc_template_wells_qc_template_id_name_key", :unique => true

  create_table "qc_templates", :force => true do |t|
    t.text     "name",       :null => false
    t.datetime "created_at", :null => false
    t.text     "species_id", :null => false
  end

  add_index "qc_templates", ["name", "created_at"], :name => "qc_templates_name_created_at_key", :unique => true

  create_table "qc_test_results", :force => true do |t|
    t.string  "qc_run_id",          :limit => 36,                    :null => false
    t.integer "qc_eng_seq_id",                                       :null => false
    t.integer "score",                            :default => 0,     :null => false
    t.boolean "pass",                             :default => false, :null => false
    t.integer "qc_run_seq_well_id",                                  :null => false
  end

  create_table "recombinases", :id => false, :force => true do |t|
    t.text "id", :null => false
  end

  create_table "recombineering_result_types", :id => false, :force => true do |t|
    t.text "id", :null => false
  end

  create_table "report_caches", :force => true do |t|
    t.text     "name",       :null => false
    t.text     "data",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "format",     :null => false
  end

  add_index "report_caches", ["name", "format"], :name => "index_report_caches_on_name_and_format", :unique => true

  create_table "roles", :force => true do |t|
    t.text "name", :null => false
  end

  add_index "roles", ["name"], :name => "roles_name_key", :unique => true

  create_table "schema_versions", :id => false, :force => true do |t|
    t.integer  "version",     :null => false
    t.datetime "deployed_at", :null => false
  end

  create_table "solr_alleles", :id => false, :force => true do |t|
    t.text    "type"
    t.integer "id"
    t.text    "product_type"
    t.integer "allele_id"
    t.text    "order_from_names"
    t.text    "order_from_urls"
    t.text    "simple_allele_image_url"
    t.text    "allele_image_url"
    t.text    "genbank_file_url"
    t.string  "mgi_accession_id",        :limit => 40
    t.string  "marker_symbol",           :limit => 75
    t.string  "allele_type",             :limit => 100
    t.string  "strain",                  :limit => 25
    t.text    "allele_name"
    t.string  "project_ids"
  end

  add_index "solr_alleles", ["id"], :name => "solr_alleles_idx"

  create_table "solr_centre_map", :id => false, :force => true do |t|
    t.string "centre_name", :limit => 40
    t.string "pref"
    t.string "def"
  end

  create_table "solr_genes", :id => false, :force => true do |t|
    t.integer  "id"
    t.text     "type"
    t.text     "allele_id"
    t.string   "consortium"
    t.string   "production_centre",       :limit => 100
    t.string   "status",                  :limit => 50
    t.datetime "effective_date"
    t.string   "mgi_accession_id",        :limit => nil
    t.text     "project_ids"
    t.text     "project_statuses"
    t.text     "project_pipelines"
    t.text     "vector_project_ids"
    t.text     "vector_project_statuses"
    t.string   "marker_symbol",           :limit => 75
    t.string   "marker_type"
  end

  add_index "solr_genes", ["id"], :name => "solr_genes_idx"

  create_table "solr_ikmc_projects_details_agg", :id => false, :force => true do |t|
    t.text    "projects"
    t.text    "pipelines"
    t.text    "statuses"
    t.integer "gene_id"
    t.text    "type"
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

  create_table "species", :id => false, :force => true do |t|
    t.text "id", :null => false
  end

  create_table "species_default_assembly", :id => false, :force => true do |t|
    t.text "species_id",  :null => false
    t.text "assembly_id", :null => false
  end

  create_table "sponsors", :id => false, :force => true do |t|
    t.text "id",                          :null => false
    t.text "description", :default => "", :null => false
  end

  create_table "strains", :force => true do |t|
    t.string   "name",                    :limit => 100, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "mgi_strain_accession_id", :limit => 100
    t.string   "mgi_strain_name",         :limit => 100
  end

  add_index "strains", ["name"], :name => "index_strains_on_name", :unique => true

# Could not dump table "summaries" because of following StandardError
#   Unknown type 'name' for column 'final_well_name'

  create_table "targ_rep_alleles", :force => true do |t|
    t.integer  "gene_id"
    t.string   "assembly",                           :default => "GRCm38",                  :null => false
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
    t.boolean  "has_issue",                          :default => false,                     :null => false
    t.text     "issue_description"
    t.text     "sequence"
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
    t.integer  "allele_id",                                :null => false
    t.string   "name",                                     :null => false
    t.string   "ikmc_project_id"
    t.string   "intermediate_vector"
    t.boolean  "report_to_public",                         :null => false
    t.integer  "pipeline_id"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.integer  "ikmc_project_foreign_id"
    t.string   "mgi_allele_name_prediction", :limit => 40
    t.string   "allele_type_prediction",     :limit => 10
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

  create_table "user_preferences", :id => false, :force => true do |t|
    t.integer "user_id",            :null => false
    t.text    "default_species_id", :null => false
  end

  create_table "user_role", :id => false, :force => true do |t|
    t.integer "user_id", :null => false
    t.integer "role_id", :null => false
  end

  create_table "users", :force => true do |t|
    t.text    "name",                       :null => false
    t.text    "password"
    t.boolean "active",   :default => true, :null => false
  end

  add_index "users", ["name"], :name => "users_name_key", :unique => true

  create_table "well_accepted_override", :id => false, :force => true do |t|
    t.integer  "well_id",       :null => false
    t.boolean  "accepted",      :null => false
    t.integer  "created_by_id", :null => false
    t.datetime "created_at",    :null => false
  end

  create_table "well_barcodes", :id => false, :force => true do |t|
    t.integer "well_id",               :null => false
    t.string  "barcode", :limit => 40, :null => false
  end

  add_index "well_barcodes", ["barcode"], :name => "well_barcodes_barcode_key", :unique => true

  create_table "well_chromosome_fail", :id => false, :force => true do |t|
    t.integer  "well_id",       :null => false
    t.text     "result",        :null => false
    t.datetime "created_at",    :null => false
    t.integer  "created_by_id", :null => false
  end

  create_table "well_colony_counts", :id => false, :force => true do |t|
    t.integer  "well_id",              :null => false
    t.text     "colony_count_type_id", :null => false
    t.integer  "colony_count",         :null => false
    t.datetime "created_at",           :null => false
    t.integer  "created_by_id",        :null => false
  end

  create_table "well_comments", :force => true do |t|
    t.integer  "well_id",       :null => false
    t.text     "comment_text",  :null => false
    t.integer  "created_by_id", :null => false
    t.datetime "created_at",    :null => false
  end

  create_table "well_dna_quality", :id => false, :force => true do |t|
    t.integer  "well_id",                       :null => false
    t.text     "quality"
    t.text     "comment_text",  :default => "", :null => false
    t.datetime "created_at",                    :null => false
    t.integer  "created_by_id",                 :null => false
    t.boolean  "egel_pass"
  end

  create_table "well_dna_status", :id => false, :force => true do |t|
    t.integer  "well_id",                             :null => false
    t.boolean  "pass",                                :null => false
    t.text     "comment_text",        :default => "", :null => false
    t.datetime "created_at",                          :null => false
    t.integer  "created_by_id",                       :null => false
    t.float    "concentration_ng_ul"
  end

  create_table "well_genotyping_results", :id => false, :force => true do |t|
    t.integer  "well_id",                   :null => false
    t.text     "genotyping_result_type_id", :null => false
    t.text     "call",                      :null => false
    t.float    "copy_number"
    t.float    "copy_number_range"
    t.text     "confidence"
    t.datetime "created_at",                :null => false
    t.integer  "created_by_id",             :null => false
    t.float    "vic"
  end

  create_table "well_lab_number", :id => false, :force => true do |t|
    t.integer "well_id",    :null => false
    t.text    "lab_number", :null => false
  end

  add_index "well_lab_number", ["lab_number"], :name => "lab_number_unique", :unique => true

  create_table "well_primer_bands", :id => false, :force => true do |t|
    t.integer  "well_id",                           :null => false
    t.text     "primer_band_type_id",               :null => false
    t.string   "pass",                :limit => 16, :null => false
    t.datetime "created_at",                        :null => false
    t.integer  "created_by_id",                     :null => false
  end

  create_table "well_qc_sequencing_result", :id => false, :force => true do |t|
    t.integer  "well_id",                            :null => false
    t.text     "valid_primers",   :default => "",    :null => false
    t.boolean  "mixed_reads",     :default => false, :null => false
    t.boolean  "pass",            :default => false, :null => false
    t.text     "test_result_url",                    :null => false
    t.datetime "created_at",                         :null => false
    t.integer  "created_by_id",                      :null => false
  end

  create_table "well_recombineering_results", :id => false, :force => true do |t|
    t.integer  "well_id",                        :null => false
    t.text     "result_type_id",                 :null => false
    t.text     "result",                         :null => false
    t.text     "comment_text",   :default => "", :null => false
    t.datetime "created_at",                     :null => false
    t.integer  "created_by_id",                  :null => false
  end

  create_table "well_targeting_neo_pass", :id => false, :force => true do |t|
    t.integer  "well_id",       :null => false
    t.text     "result",        :null => false
    t.datetime "created_at",    :null => false
    t.integer  "created_by_id", :null => false
  end

  create_table "well_targeting_pass", :id => false, :force => true do |t|
    t.integer  "well_id",       :null => false
    t.text     "result",        :null => false
    t.datetime "created_at",    :null => false
    t.integer  "created_by_id", :null => false
  end

  create_table "well_targeting_puro_pass", :id => false, :force => true do |t|
    t.integer  "well_id",       :null => false
    t.text     "result",        :null => false
    t.datetime "created_at",    :null => false
    t.integer  "created_by_id", :null => false
  end

  create_table "wells", :force => true do |t|
    t.integer  "plate_id",                                  :null => false
    t.text     "name",                                      :null => false
    t.integer  "created_by_id",                             :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "assay_pending"
    t.datetime "assay_complete"
    t.boolean  "accepted",               :default => false, :null => false
    t.text     "accepted_rules_version"
  end

  add_index "wells", ["plate_id", "name"], :name => "wells_plate_id_name_key", :unique => true

  add_foreign_key "assemblies", "species", :name => "assemblies_species_id_fkey"

  add_foreign_key "bac_clone_loci", "assemblies", :name => "bac_clone_loci_assembly_id_fkey"
  add_foreign_key "bac_clone_loci", "bac_clones", :name => "bac_clone_loci_bac_clone_id_fkey"
  add_foreign_key "bac_clone_loci", "chromosomes", :name => "bac_clone_loci_chr_id_fkey1", :column => "chr_id"

  add_foreign_key "bac_clones", "bac_libraries", :name => "bac_clones_bac_library_id_fkey"

  add_foreign_key "bac_libraries", "species", :name => "bac_libraries_species_id_fkey"

  add_foreign_key "chromosomes", "species", :name => "new_chromosomes_species_id_fkey"

  add_foreign_key "crispr_designs", "crispr_pairs", :name => "crispr_designs_crispr_pair_id_fkey"
  add_foreign_key "crispr_designs", "crisprs", :name => "crispr_designs_crispr_id_fkey"
  add_foreign_key "crispr_designs", "designs", :name => "crispr_designs_design_id_fkey"

  add_foreign_key "crispr_es_qc_runs", "species", :name => "crispr_es_qc_runs_species_id_fkey"
  add_foreign_key "crispr_es_qc_runs", "users", :name => "crispr_es_qc_runs_created_by_id_fkey", :column => "created_by_id"

  add_foreign_key "crispr_es_qc_wells", "chromosomes", :name => "crispr_es_qc_wells_crispr_chr_id_fkey", :column => "crispr_chr_id"
  add_foreign_key "crispr_es_qc_wells", "crispr_es_qc_runs", :name => "crispr_es_qc_wells_crispr_es_qc_run_id_fkey"
  add_foreign_key "crispr_es_qc_wells", "wells", :name => "crispr_es_qc_wells_well_id_fkey"

  add_foreign_key "crispr_loci", "assemblies", :name => "crispr_loci_assembly_id_fkey"
  add_foreign_key "crispr_loci", "chromosomes", :name => "crispr_loci_chr_id_fkey", :column => "chr_id"
  add_foreign_key "crispr_loci", "crisprs", :name => "crispr_loci_crispr_id_fkey"

  add_foreign_key "crispr_off_target_summaries", "crisprs", :name => "crispr_off_target_summaries_crispr_id_fkey"

  add_foreign_key "crispr_off_targets", "assemblies", :name => "crispr_off_targets_assembly_id_fkey"
  add_foreign_key "crispr_off_targets", "crispr_loci_types", :name => "crispr_off_targets_crispr_loci_type_id_fkey"
  add_foreign_key "crispr_off_targets", "crisprs", :name => "crispr_off_targets_crispr_id_fkey"

  add_foreign_key "crispr_pairs", "crisprs", :name => "crispr_pairs_left_crispr_fkey", :column => "left_crispr_id"
  add_foreign_key "crispr_pairs", "crisprs", :name => "crispr_pairs_right_crispr_fkey", :column => "right_crispr_id"

  add_foreign_key "crispr_primers", "crispr_pairs", :name => "crispr_primers_crispr_pair_id_fkey"
  add_foreign_key "crispr_primers", "crispr_primer_types", :name => "crispr primer name must belong to allowed list", :column => "primer_name", :primary_key => "primer_name"
  add_foreign_key "crispr_primers", "crisprs", :name => "crispr_primers_crispr_id_fkey"

  add_foreign_key "crispr_primers_loci", "assemblies", :name => "crispr_primers_loci_assembly_id_fkey"
  add_foreign_key "crispr_primers_loci", "chromosomes", :name => "crispr_primers_loci_chr_id_fkey", :column => "chr_id"

  add_foreign_key "crisprs", "crispr_loci_types", :name => "crisprs_crispr_loci_type_id_fkey"
  add_foreign_key "crisprs", "species", :name => "crisprs_species_id_fkey"

  add_foreign_key "design_attempts", "species", :name => "design_attempts_species_id_fkey"
  add_foreign_key "design_attempts", "users", :name => "design_attempts_created_by_fkey", :column => "created_by"

  add_foreign_key "design_comments", "design_comment_categories", :name => "design_comments_design_comment_category_id_fkey"
  add_foreign_key "design_comments", "designs", :name => "design_comments_design_id_fkey"
  add_foreign_key "design_comments", "users", :name => "design_comments_created_by_fkey", :column => "created_by"

  add_foreign_key "design_oligo_loci", "assemblies", :name => "design_oligo_loci_assembly_id_fkey"
  add_foreign_key "design_oligo_loci", "chromosomes", :name => "design_oligo_loci_chr_id_fkey1", :column => "chr_id"
  add_foreign_key "design_oligo_loci", "design_oligos", :name => "design_oligo_loci_design_oligo_id_fkey"

  add_foreign_key "design_oligos", "design_oligo_types", :name => "design_oligos_design_oligo_type_id_fkey"
  add_foreign_key "design_oligos", "designs", :name => "design_oligos_design_id_fkey"

  add_foreign_key "design_targets", "assemblies", :name => "design_targets_assembly_id_fkey"
  add_foreign_key "design_targets", "chromosomes", :name => "design_targets_chr_id_fkey", :column => "chr_id"
  add_foreign_key "design_targets", "species", :name => "design_targets_species_id_fkey"

  add_foreign_key "designs", "design_types", :name => "designs_design_type_id_fkey"
  add_foreign_key "designs", "species", :name => "designs_species_id_fkey"
  add_foreign_key "designs", "users", :name => "designs_created_by_fkey", :column => "created_by"

  add_foreign_key "gene_design", "designs", :name => "gene_design_design_id_fkey"
  add_foreign_key "gene_design", "gene_types", :name => "gene_design_gene_type_id_fkey"
  add_foreign_key "gene_design", "users", :name => "gene_design_created_by_fkey", :column => "created_by"

  add_foreign_key "genotyping_primers", "designs", :name => "genotyping_primers_design_id_fkey"
  add_foreign_key "genotyping_primers", "genotyping_primer_types", :name => "genotyping_primers_genotyping_primer_type_id_fkey"

  add_foreign_key "genotyping_primers_loci", "assemblies", :name => "genotyping_primers_loci_assembly_id_fkey"
  add_foreign_key "genotyping_primers_loci", "chromosomes", :name => "genotyping_primers_loci_chr_id_fkey", :column => "chr_id"

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
  add_foreign_key "mi_attempts", "targ_rep_alleles", :name => "mi_attempts_targ_rep_allele_id_fk", :column => "allele_id"
  add_foreign_key "mi_attempts", "targ_rep_real_alleles", :name => "mi_attempts_targ_rep_real_allele_id_fk", :column => "real_allele_id"

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

  add_foreign_key "mouse_allele_mods", "mi_attempts", :name => "mouse_allele_mods_mi_attempt_id_fk"
  add_foreign_key "mouse_allele_mods", "mi_plans", :name => "mouse_allele_mods_mi_plan_id_fk"
  add_foreign_key "mouse_allele_mods", "mouse_allele_mod_statuses", :name => "mouse_allele_mods_status_id_fk", :column => "status_id"
  add_foreign_key "mouse_allele_mods", "phenotype_attempts", :name => "mouse_allele_mods_phenotype_attempt_id_fk"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_critical_region_qpcr_id_fk", :column => "qc_critical_region_qpcr_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_five_prime_cassette_integrity_id_fk", :column => "qc_five_prime_cassette_integrity_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_five_prime_lr_pcr_id_fk", :column => "qc_five_prime_lr_pcr_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_homozygous_loa_sr_pcr_id_fk", :column => "qc_homozygous_loa_sr_pcr_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_lacz_count_qpcr_id_fk", :column => "qc_lacz_count_qpcr_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_lacz_sr_pcr_id_fk", :column => "qc_lacz_sr_pcr_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_loa_qpcr_id_fk", :column => "qc_loa_qpcr_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_loxp_confirmation_id_fk", :column => "qc_loxp_confirmation_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_loxp_srpcr_and_sequencing_id_fk", :column => "qc_loxp_srpcr_and_sequencing_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_loxp_srpcr_id_fk", :column => "qc_loxp_srpcr_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_mutant_specific_sr_pcr_id_fk", :column => "qc_mutant_specific_sr_pcr_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_neo_count_qpcr_id_fk", :column => "qc_neo_count_qpcr_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_neo_sr_pcr_id_fk", :column => "qc_neo_sr_pcr_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_southern_blot_id_fk", :column => "qc_southern_blot_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_three_prime_lr_pcr_id_fk", :column => "qc_three_prime_lr_pcr_id"
  add_foreign_key "mouse_allele_mods", "qc_results", :name => "mouse_allele_mods_qc_tv_backbone_assay_id_fk", :column => "qc_tv_backbone_assay_id"
  add_foreign_key "mouse_allele_mods", "strains", :name => "mouse_allele_mods_colony_background_strain_id_fk", :column => "colony_background_strain_id"
  add_foreign_key "mouse_allele_mods", "strains", :name => "mouse_allele_mods_deleter_strain_id_fk", :column => "deleter_strain_id"
  add_foreign_key "mouse_allele_mods", "targ_rep_alleles", :name => "mouse_allele_mods_targ_rep_allele_id_fk", :column => "allele_id"
  add_foreign_key "mouse_allele_mods", "targ_rep_real_alleles", :name => "mouse_allele_mods_targ_rep_real_allele_id_fk", :column => "real_allele_id"

  add_foreign_key "notifications", "contacts", :name => "notifications_contact_id_fk"
  add_foreign_key "notifications", "genes", :name => "notifications_gene_id_fk"

  add_foreign_key "phenotype_attempt_distribution_centres", "centres", :name => "phenotype_attempt_distribution_centres_centre_id_fk"
  add_foreign_key "phenotype_attempt_distribution_centres", "deposited_materials", :name => "phenotype_attempt_distribution_centres_deposited_material_id_fk"
  add_foreign_key "phenotype_attempt_distribution_centres", "mouse_allele_mods", :name => "fk_mouse_allele_mod_distribution_centres"
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
  add_foreign_key "phenotype_attempts", "targ_rep_alleles", :name => "phenotype_attempts_targ_rep_allele_id_fk", :column => "allele_id"
  add_foreign_key "phenotype_attempts", "targ_rep_real_alleles", :name => "phenotype_attempts_targ_rep_real_allele_id_fk", :column => "real_allele_id"

  add_foreign_key "phenotyping_production_status_stamps", "phenotyping_production_statuses", :name => "phenotyping_production_status_stamps_status_id_fk", :column => "status_id"
  add_foreign_key "phenotyping_production_status_stamps", "phenotyping_productions", :name => "fk_phenotyping_productions"

  add_foreign_key "phenotyping_productions", "mi_plans", :name => "phenotyping_productions_mi_plan_id_fk"
  add_foreign_key "phenotyping_productions", "mouse_allele_mods", :name => "phenotyping_productions_mouse_allele_mod_id_fk"
  add_foreign_key "phenotyping_productions", "phenotype_attempts", :name => "phenotyping_productions_phenotype_attempt_id_fk"
  add_foreign_key "phenotyping_productions", "phenotyping_production_statuses", :name => "phenotyping_productions_status_id_fk", :column => "status_id"

  add_foreign_key "plate_comments", "plates", :name => "plate_comments_plate_id_fkey"
  add_foreign_key "plate_comments", "users", :name => "plate_comments_created_by_id_fkey", :column => "created_by_id"

  add_foreign_key "plates", "plate_types", :name => "plates_type_id_fkey", :column => "type_id"
  add_foreign_key "plates", "species", :name => "plates_species_id_fkey"
  add_foreign_key "plates", "sponsors", :name => "plates_sponsor_id_fkey"
  add_foreign_key "plates", "users", :name => "plates_created_by_id_fkey", :column => "created_by_id"

  add_foreign_key "process_bac", "bac_clones", :name => "process_bac_bac_clone_id_fkey"
  add_foreign_key "process_bac", "processes", :name => "process_bac_process_id_fkey"

  add_foreign_key "process_backbone", "backbones", :name => "process_backbone_backbone_id_fkey"
  add_foreign_key "process_backbone", "processes", :name => "process_backbone_process_id_fkey"

  add_foreign_key "process_cassette", "cassettes", :name => "process_cassette_cassette_id_fkey"
  add_foreign_key "process_cassette", "processes", :name => "process_cassette_process_id_fkey"

  add_foreign_key "process_cell_line", "cell_lines", :name => "process_cell_line_cell_line_id_fkey"
  add_foreign_key "process_cell_line", "processes", :name => "process_cell_line_process_id_fkey"

  add_foreign_key "process_crispr", "crisprs", :name => "process_crispr_crispr_id_fkey"
  add_foreign_key "process_crispr", "processes", :name => "process_crispr_process_id_fkey"

  add_foreign_key "process_design", "designs", :name => "process_design_design_id_fkey"
  add_foreign_key "process_design", "processes", :name => "process_design_process_id_fkey"

  add_foreign_key "process_global_arm_shortening_design", "designs", :name => "process_global_arm_shortening_design_design_id_fkey"
  add_foreign_key "process_global_arm_shortening_design", "processes", :name => "process_global_arm_shortening_design_process_id_fkey"

  add_foreign_key "process_input_well", "processes", :name => "process_input_well_process_id_fkey"
  add_foreign_key "process_input_well", "wells", :name => "process_input_well_well_id_fkey"

  add_foreign_key "process_nuclease", "nucleases", :name => "process_nuclease_nuclease_id_fkey"
  add_foreign_key "process_nuclease", "processes", :name => "process_nuclease_process_id_fkey"

  add_foreign_key "process_output_well", "processes", :name => "process_output_well_process_id_fkey"
  add_foreign_key "process_output_well", "wells", :name => "process_output_well_well_id_fkey"

  add_foreign_key "process_recombinase", "processes", :name => "process_recombinase_process_id_fkey"
  add_foreign_key "process_recombinase", "recombinases", :name => "process_recombinase_recombinase_id_fkey"

  add_foreign_key "processes", "process_types", :name => "processes_type_id_fkey", :column => "type_id"

  add_foreign_key "project_alleles", "cassette_function", :name => "project_alleles_cassette_function_fkey", :column => "cassette_function"
  add_foreign_key "project_alleles", "projects", :name => "project_alleles_project_id_fkey"

  add_foreign_key "projects", "sponsors", :name => "projects_sponsor_id_fkey"

  add_foreign_key "qc_alignment_regions", "qc_alignments", :name => "qc_alignment_regions_qc_alignment_id_fkey"

  add_foreign_key "qc_alignments", "qc_eng_seqs", :name => "qc_alignments_qc_eng_seq_id_fkey"
  add_foreign_key "qc_alignments", "qc_runs", :name => "qc_alignments_qc_run_id_fkey"
  add_foreign_key "qc_alignments", "qc_seq_reads", :name => "qc_alignments_qc_seq_read_id_fkey"

  add_foreign_key "qc_run_seq_project", "qc_runs", :name => "qc_run_seq_project_qc_run_id_fkey"
  add_foreign_key "qc_run_seq_project", "qc_seq_projects", :name => "qc_run_seq_project_qc_seq_project_id_fkey"

  add_foreign_key "qc_run_seq_well_qc_seq_read", "qc_run_seq_wells", :name => "qc_run_seq_well_qc_seq_read_qc_run_seq_well_id_fkey"
  add_foreign_key "qc_run_seq_well_qc_seq_read", "qc_seq_reads", :name => "qc_run_seq_well_qc_seq_read_qc_seq_read_id_fkey"

  add_foreign_key "qc_run_seq_wells", "qc_runs", :name => "qc_run_seq_wells_qc_run_id_fkey"

  add_foreign_key "qc_runs", "qc_templates", :name => "qc_runs_qc_template_id_fkey"
  add_foreign_key "qc_runs", "users", :name => "qc_runs_created_by_id_fkey", :column => "created_by_id"

  add_foreign_key "qc_seq_projects", "species", :name => "qc_seq_projects_species_id_fkey"

  add_foreign_key "qc_seq_reads", "qc_seq_projects", :name => "qc_seq_reads_qc_seq_project_id_fkey"

  add_foreign_key "qc_template_well_backbone", "backbones", :name => "qc_template_well_backbone_backbone_id_fkey"
  add_foreign_key "qc_template_well_backbone", "qc_template_wells", :name => "qc_template_well_backbone_qc_template_well_id_fkey"

  add_foreign_key "qc_template_well_cassette", "cassettes", :name => "qc_template_well_cassette_cassette_id_fkey"
  add_foreign_key "qc_template_well_cassette", "qc_template_wells", :name => "qc_template_well_cassette_qc_template_well_id_fkey"

  add_foreign_key "qc_template_well_recombinase", "qc_template_wells", :name => "qc_template_well_recombinase_qc_template_well_id_fkey"
  add_foreign_key "qc_template_well_recombinase", "recombinases", :name => "qc_template_well_recombinase_recombinase_id_fkey"

  add_foreign_key "qc_template_wells", "qc_eng_seqs", :name => "qc_template_wells_qc_eng_seq_id_fkey"
  add_foreign_key "qc_template_wells", "qc_templates", :name => "qc_template_wells_qc_template_id_fkey"
  add_foreign_key "qc_template_wells", "wells", :name => "qc_template_wells_source_well_id_fkey", :column => "source_well_id"

  add_foreign_key "qc_templates", "species", :name => "qc_templates_species_id_fkey"

  add_foreign_key "qc_test_results", "qc_eng_seqs", :name => "qc_test_results_qc_eng_seq_id_fkey"
  add_foreign_key "qc_test_results", "qc_run_seq_wells", :name => "qc_test_results_qc_run_seq_well_id_fkey"
  add_foreign_key "qc_test_results", "qc_runs", :name => "qc_test_results_qc_run_id_fkey"

  add_foreign_key "species_default_assembly", "assemblies", :name => "species_default_assembly_assembly_id_fkey"
  add_foreign_key "species_default_assembly", "species", :name => "species_default_assembly_species_id_fkey"

  add_foreign_key "targ_rep_es_cells", "centres", :name => "targ_rep_es_cells_user_qc_mouse_clinic_id_fk", :column => "user_qc_mouse_clinic_id"
  add_foreign_key "targ_rep_es_cells", "targ_rep_real_alleles", :name => "targ_rep_es_cells_targ_rep_real_allele_id_fk", :column => "real_allele_id"

  add_foreign_key "targ_rep_real_alleles", "genes", :name => "targ_rep_real_alleles_gene_id_fk"

  add_foreign_key "user_preferences", "species", :name => "user_preferences_default_species_id_fkey", :column => "default_species_id"
  add_foreign_key "user_preferences", "users", :name => "user_preferences_user_id_fkey"

  add_foreign_key "user_role", "roles", :name => "user_role_role_id_fkey"
  add_foreign_key "user_role", "users", :name => "user_role_user_id_fkey"

  add_foreign_key "well_accepted_override", "users", :name => "well_accepted_override_created_by_id_fkey", :column => "created_by_id"
  add_foreign_key "well_accepted_override", "wells", :name => "well_accepted_override_well_id_fkey"

  add_foreign_key "well_barcodes", "wells", :name => "well_barcodes_well_id_fkey"

  add_foreign_key "well_chromosome_fail", "users", :name => "well_chromosome_fail_created_by_id_fkey", :column => "created_by_id"
  add_foreign_key "well_chromosome_fail", "wells", :name => "well_chromosome_fail_well_id_fkey"

  add_foreign_key "well_colony_counts", "colony_count_types", :name => "well_colony_counts_colony_count_type_id_fkey"
  add_foreign_key "well_colony_counts", "users", :name => "well_colony_counts_created_by_id_fkey", :column => "created_by_id"
  add_foreign_key "well_colony_counts", "wells", :name => "well_colony_counts_well_id_fkey"

  add_foreign_key "well_comments", "users", :name => "well_comments_created_by_id_fkey", :column => "created_by_id"
  add_foreign_key "well_comments", "wells", :name => "well_comments_well_id_fkey"

  add_foreign_key "well_dna_quality", "users", :name => "well_dna_quality_created_by_id_fkey", :column => "created_by_id"
  add_foreign_key "well_dna_quality", "wells", :name => "well_dna_quality_well_id_fkey"

  add_foreign_key "well_dna_status", "users", :name => "well_dna_status_created_by_id_fkey", :column => "created_by_id"
  add_foreign_key "well_dna_status", "wells", :name => "well_dna_status_well_id_fkey"

  add_foreign_key "well_genotyping_results", "genotyping_result_types", :name => "well_genotyping_results_genotyping_result_type_id_fkey"
  add_foreign_key "well_genotyping_results", "users", :name => "well_genotyping_results_created_by_id_fkey", :column => "created_by_id"
  add_foreign_key "well_genotyping_results", "wells", :name => "well_genotyping_results_well_id_fkey"

  add_foreign_key "well_lab_number", "wells", :name => "well_lab_number_well_id_fkey"

  add_foreign_key "well_primer_bands", "primer_band_types", :name => "well_primer_bands_primer_band_type_id_fkey"
  add_foreign_key "well_primer_bands", "users", :name => "well_primer_bands_created_by_id_fkey", :column => "created_by_id"
  add_foreign_key "well_primer_bands", "wells", :name => "well_primer_bands_well_id_fkey"

  add_foreign_key "well_qc_sequencing_result", "users", :name => "well_qc_sequencing_result_created_by_id_fkey", :column => "created_by_id"
  add_foreign_key "well_qc_sequencing_result", "wells", :name => "well_qc_sequencing_result_well_id_fkey"

  add_foreign_key "well_recombineering_results", "recombineering_result_types", :name => "well_recombineering_results_result_type_id_fkey", :column => "result_type_id"
  add_foreign_key "well_recombineering_results", "users", :name => "well_recombineering_results_created_by_id_fkey", :column => "created_by_id"
  add_foreign_key "well_recombineering_results", "wells", :name => "well_recombineering_results_well_id_fkey"

  add_foreign_key "well_targeting_neo_pass", "users", :name => "well_targeting_neo_pass_created_by_id_fkey", :column => "created_by_id"
  add_foreign_key "well_targeting_neo_pass", "wells", :name => "well_targeting_neo_pass_well_id_fkey"

  add_foreign_key "well_targeting_pass", "users", :name => "well_targeting_pass_created_by_id_fkey", :column => "created_by_id"
  add_foreign_key "well_targeting_pass", "wells", :name => "well_targeting_pass_well_id_fkey"

  add_foreign_key "well_targeting_puro_pass", "users", :name => "well_targeting_puro_pass_created_by_id_fkey", :column => "created_by_id"
  add_foreign_key "well_targeting_puro_pass", "wells", :name => "well_targeting_puro_pass_well_id_fkey"

  add_foreign_key "wells", "plates", :name => "wells_plate_id_fkey"
  add_foreign_key "wells", "users", :name => "wells_created_by_id_fkey", :column => "created_by_id"

end
