#!/usr/bin/env ruby

require 'pp'

#sql_1 = <<END
#  select
#    marker_symbol,
#    mgi_accession_id,
#    marker_type,
#    report_to_public
#  from genes left outer join targ_rep_alleles on genes.id = targ_rep_alleles.gene_id
#  left outer join targ_rep_es_cells on targ_rep_alleles.id = targ_rep_es_cells.allele_id
#  left outer join mi_attempts on mi_attempts.es_cell_id = targ_rep_es_cells.id
#  left join mi_plans mi_attempt_plan on mi_attempts.mi_plan_id = mi_attempt_plan.id
#  left join centres miapc on mi_attempt_plan.production_centre_id = miapc.id
#  left outer join phenotype_attempts on phenotype_attempts.mi_attempt_id = mi_attempts.id
#  limit 10
#END

sql = <<END
  select distinct
    genes.id,
    genes.marker_symbol,
    genes.marker_type,
    genes.mgi_accession_id,
    targ_rep_es_cells.mgi_allele_symbol_superscript,
    miapc.name as production_centre,
    mi_attempts.mouse_allele_type,
    phenotype_attempts.mouse_allele_type
  from genes
    left outer join targ_rep_alleles on genes.id = targ_rep_alleles.gene_id
    left outer join targ_rep_es_cells on targ_rep_alleles.id = targ_rep_es_cells.allele_id
    left outer join mi_attempts on mi_attempts.es_cell_id = targ_rep_es_cells.id
    left join mi_plans mi_attempt_plan on mi_attempts.mi_plan_id = mi_attempt_plan.id
    left join centres miapc on mi_attempt_plan.production_centre_id = miapc.id
    left outer join phenotype_attempts on phenotype_attempts.mi_attempt_id = mi_attempts.id
    left outer join mi_plans paplan on phenotype_attempts.mi_plan_id = paplan.id
  where marker_symbol = 'Cib2'
  --limit 5;
END

rows = ActiveRecord::Base.connection.execute(sql)

#gene level:
#
#    mouse production center (latest project status)
#    phenotyping center (latest project status)
#    marker_name
#    marker_synonym
#
#allele level (each allele)
#    es cell status
#    mice status
#    phenotyping status
#    allele name (tm1a/tm1b...)
#    allele_type: (mi/pa)
#    (above as shown on the search page)
#
#    mouse production center
#    phenotyping center

count = 0
columns = []
processed_rows = []
rows.each do |row|
  #columns = row.keys

  gene = Gene.find row['id']

  count += 1
  row['latest_project_status'] = gene.relevant_status[:status]

  # pp gene.relevant_status

  processed_rows.push row.clone #if ! row['mouse_allele_type'].nil? && ! row['mgi_allele_symbol_superscript'].nil?

  phenotype_attempt_id = gene.relevant_status[:phenotype_attempt_id]

  if phenotype_attempt_id
    phenotype_atempt = PhenotypeAttempt.find phenotype_attempt_id
    row['imits_phenotype_started'] = phenotype_atempt.phenotyping_started
    row['imits_phenotype_complete'] = phenotype_atempt.phenotyping_complete
    row['imits_phenotype_status'] = phenotype_atempt.status.name
    row['centre'] = phenotype_atempt.centre.name

    processed_rows.push row.clone #if ! row['mouse_allele_type'].nil? && ! row['mgi_allele_symbol_superscript'].nil?
  end

  if row['mouse_allele_type'] == 'b'
    # processed_rows.push row.clone #if ! row['mouse_allele_type'].nil? && ! row['mgi_allele_symbol_superscript'].nil?

    hash = row.clone
    hash['mgi_allele_symbol_superscript'] = hash['mgi_allele_symbol_superscript'].gsub(/(\d)a\(/, '\1b(')
    #hash['XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'] = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    processed_rows.push hash
  end
end

puts "#### count: #{count}"
pp processed_rows

#[{"marker_symbol"=>"Cib2",
#  "marker_type"=>"Gene",
#  "mgi_accession_id"=>"MGI:1929293",
#  "mgi_allele_symbol_superscript"=>"tm1(KOMP)Vlcg",
#  "production_centre"=>nil,
#  "mouse_allele_type"=>nil},
# {"marker_symbol"=>"Cib2",
#  "marker_type"=>"Gene",
#  "mgi_accession_id"=>"MGI:1929293",
#  "mgi_allele_symbol_superscript"=>"tm1e(EUCOMM)Wtsi",
#  "production_centre"=>nil,
#  "mouse_allele_type"=>nil},
# {"marker_symbol"=>"Cib2",
#  "marker_type"=>"Gene",
#  "mgi_accession_id"=>"MGI:1929293",
#  "mgi_allele_symbol_superscript"=>"tm1a(EUCOMM)Wtsi",
#  "production_centre"=>"Harwell",
#  "mouse_allele_type"=>"b"},
# {"marker_symbol"=>"Cib2",
#  "marker_type"=>"Gene",
#  "mgi_accession_id"=>"MGI:1929293",
#  "mgi_allele_symbol_superscript"=>"tm1a(EUCOMM)Wtsi",
#  "production_centre"=>nil,
#  "mouse_allele_type"=>nil}]

#["id",
# "marker_symbol",
# "mgi_accession_id",
# "ikmc_projects_count",
# "conditional_es_cells_count",
# "non_conditional_es_cells_count",
# "deletion_es_cells_count",
# "other_targeted_mice_count",
# "other_condtional_mice_count",
# "mutation_published_as_lethal_count",
# "publications_for_gene_count",
# "go_annotations_for_gene_count",
# "created_at",
# "updated_at",
# "chr",
# "start_coordinates",
# "end_coordinates",
# "strand_name",
# "vega_ids",
# "ncbi_ids",
# "ensembl_ids",
# "ccds_ids",
# "marker_type",
# "gene_id",
# "assembly",
# "chromosome",
# "strand",
# "homology_arm_start",
# "homology_arm_end",
# "loxp_start",
# "loxp_end",
# "cassette_start",
# "cassette_end",
# "cassette",
# "backbone",
# "subtype_description",
# "floxed_start_exon",
# "floxed_end_exon",
# "project_design_id",
# "reporter",
# "mutation_method_id",
# "mutation_type_id",
# "mutation_subtype_id",
# "cassette_type",
# "intron",
# "type",
# "has_issue",
# "allele_id",
# "targeting_vector_id",
# "parental_cell_line",
# "mgi_allele_symbol_superscript",
# "name",
# "comment",
# "contact",
# "ikmc_project_id",
# "mgi_allele_id",
# "pipeline_id",
# "report_to_public",
# "strain",
# "production_qc_five_prime_screen",
# "production_qc_three_prime_screen",
# "production_qc_loxp_screen",
# "production_qc_loss_of_allele",
# "production_qc_vector_integrity",
# "user_qc_map_test",
# "user_qc_karyotype",
# "user_qc_tv_backbone_assay",
# "user_qc_loxp_confirmation",
# "user_qc_southern_blot",
# "user_qc_loss_of_wt_allele",
# "user_qc_neo_count_qpcr",
# "user_qc_lacz_sr_pcr",
# "user_qc_mutant_specific_sr_pcr",
# "user_qc_five_prime_cassette_integrity",
# "user_qc_neo_sr_pcr",
# "user_qc_five_prime_lr_pcr",
# "user_qc_three_prime_lr_pcr",
# "user_qc_comment",
# "allele_type",
# "mutation_subtype",
# "allele_symbol_superscript_template",
# "legacy_id",
# "production_centre_auto_update",
# "user_qc_loxp_srpcr_and_sequencing",
# "user_qc_karyotype_spread",
# "user_qc_karyotype_pcr",
# "user_qc_mouse_clinic_id",
# "user_qc_chr1",
# "user_qc_chr11",
# "user_qc_chr8",
# "user_qc_chry",
# "user_qc_lacz_qpcr",
# "ikmc_project_foreign_id",
# "es_cell_id",
# "mi_date",
# "status_id",
# "colony_name",
# "updated_by_id",
# "blast_strain_id",
# "total_blasts_injected",
# "total_transferred",
# "number_surrogates_receiving",
# "total_pups_born",
# "total_female_chimeras",
# "total_male_chimeras",
# "total_chimeras",
# "number_of_males_with_0_to_39_percent_chimerism",
# "number_of_males_with_40_to_79_percent_chimerism",
# "number_of_males_with_80_to_99_percent_chimerism",
# "number_of_males_with_100_percent_chimerism",
# "colony_background_strain_id",
# "test_cross_strain_id",
# "date_chimeras_mated",
# "number_of_chimera_matings_attempted",
# "number_of_chimera_matings_successful",
# "number_of_chimeras_with_glt_from_cct",
# "number_of_chimeras_with_glt_from_genotyping",
# "number_of_chimeras_with_0_to_9_percent_glt",
# "number_of_chimeras_with_10_to_49_percent_glt",
# "number_of_chimeras_with_50_to_99_percent_glt",
# "number_of_chimeras_with_100_percent_glt",
# "total_f1_mice_from_matings",
# "number_of_cct_offspring",
# "number_of_het_offspring",
# "number_of_live_glt_offspring",
# "mouse_allele_type",
# "qc_southern_blot_id",
# "qc_five_prime_lr_pcr_id",
# "qc_five_prime_cassette_integrity_id",
# "qc_tv_backbone_assay_id",
# "qc_neo_count_qpcr_id",
# "qc_neo_sr_pcr_id",
# "qc_loa_qpcr_id",
# "qc_homozygous_loa_sr_pcr_id",
# "qc_lacz_sr_pcr_id",
# "qc_mutant_specific_sr_pcr_id",
# "qc_loxp_confirmation_id",
# "qc_three_prime_lr_pcr_id",
# "is_active",
# "is_released_from_genotyping",
# "comments",
# "mi_plan_id",
# "genotyping_comment",
# "legacy_es_cell_id",
# "qc_lacz_count_qpcr_id",
# "qc_critical_region_qpcr_id",
# "qc_loxp_srpcr_id",
# "qc_loxp_srpcr_and_sequencing_id",
# "cassette_transmission_verified",
# "cassette_transmission_verified_auto_complete",
# "consortium_id",
# "priority_id",
# "production_centre_id",
# "number_of_es_cells_starting_qc",
# "number_of_es_cells_passing_qc",
# "sub_project_id",
# "is_bespoke_allele",
# "is_conditional_allele",
# "is_deletion_allele",
# "is_cre_knock_in_allele",
# "is_cre_bac_allele",
# "withdrawn",
# "es_qc_comment_id",
# "phenotype_only",
# "completion_note",
# "recovery",
# "conditional_tm1c",
# "ignore_available_mice",
# "number_of_es_cells_received",
# "es_cells_received_on",
# "es_cells_received_from_id",
# "point_mutation",
# "conditional_point_mutation",
# "allele_symbol_superscript",
# "completion_comment",
# "mutagenesis_via_crispr_cas9",
# "contact_name",
# "contact_email",
# "mi_attempt_id",
# "rederivation_started",
# "rederivation_complete",
# "number_of_cre_matings_started",
# "number_of_cre_matings_successful",
# "phenotyping_started",
# "phenotyping_complete",
# "deleter_strain_id",
# "cre_excision_required",
# "tat_cre",
# "phenotyping_experiments_started",
# "allele_name",
# "jax_mgi_accession_id"]







#gene level:
#
#    mouse production center (latest project status)
#    phenotyping center (latest project status)
#    marker_symbol
#    marker_name
#    marker_synonym
#    marker_type
#    mgi_accession_id
#    latest_project_status'
#
#    // the following 3 are use to make the IMPC Phenotyping Status
#facet on search page
#    imits_phenotype_started (from gene core)
#    imits_phenotype_complete (from gene core)
#    imits_phenotype_status (from gene core)
#
#allele level (each allele)
#    es cell status
#    mice status
#    phenotyping status
#    allele name (tm1a/tm1b...)
#    allele_type: (mi/pa)
#    (above as shown on the search page)
#
#    mouse production center
#    phenotyping center
