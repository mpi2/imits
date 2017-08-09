class AllowUploadMultipleTraceFiles < ActiveRecord::Migration

  def self.up

    add_column :alleles, :colony_id, :integer
    add_column :alleles, :auto_allele_description, :text
    add_column :alleles, :allele_description, :text
    add_column :alleles, :mutant_fa, :text
    add_column :alleles, :reference_fa, :text
    add_column :alleles, :mutant_protein_fa, :text
    add_column :alleles, :reference_protein_fa, :text
    add_column :alleles, :alignment, :text
    add_column :alleles, :filtered_analysis_vcf, :text
    add_column :alleles, :merged_variants_vcf, :text
    add_column :alleles, :variant_effect_predictor_output, :text
    add_column :alleles, :primer_reads_fa, :text
    add_column :alleles, :alignment_data_yaml, :text
    add_column :alleles, :trace_output, :text
    add_column :alleles, :trace_error, :text
    add_column :alleles, :exception_details, :text
    add_column :alleles, :return_code, :integer
    add_column :alleles, :exon_id, :string

    rename_table :trace_call_vcf_modifications, :vcf_modifications
    add_column   :vcf_modifications, :allele_id, :integer

    add_column :production_centre_qcs, :qc_southern_blot, :string,
    add_column :production_centre_qcs, :qc_five_prime_lr_pcr, :string,
    add_column :production_centre_qcs, :qc_five_prime_cassette_integrity, :string,
    add_column :production_centre_qcs, :qc_tv_backbone_assay, :string,
    add_column :production_centre_qcs, :qc_neo_count_qpcr, :string,
    add_column :production_centre_qcs, :qc_lacz_count_qpcr, :string,
    add_column :production_centre_qcs, :qc_neo_sr_pcr, :string,
    add_column :production_centre_qcs, :qc_loa_qpcr, :string,
    add_column :production_centre_qcs, :qc_homozygous_loa_sr_pcr, :string,
    add_column :production_centre_qcs, :qc_lacz_sr_pcr, :string,
    add_column :production_centre_qcs, :qc_mutant_specific_sr_pcr, :string,
    add_column :production_centre_qcs, :qc_loxp_confirmation, :string,
    add_column :production_centre_qcs, :qc_three_prime_lr_pcr, :string,
    add_column :production_centre_qcs, :qc_critical_region_qpcr, :string,
    add_column :production_centre_qcs, :qc_loxp_srpcr, :string,
    add_column :production_centre_qcs, :qc_loxp_srpcr_and_sequencing, :string 

    sql = <<-EOF


      INSERT INTO alleles(
        colony_id, allele_confirmed,
        mgi_allele_symbol_without_impc_abbreviation, mgi_allele_symbol_superscript, 
        mgi_allele_accession_id, allele_type, allele_symbol_superscript_template, auto_allele_description, allele_description,
        alignment, filtered_analysis_vcf, variant_effect_predictor_output, reference_protein_fa, mutant_protein_fa,
        primer_reads_fa, alignment_data_yaml, trace_output, trace_error, exception_details, return_code, merged_variants_vcf, 
        exon_id, created_at, updated_at, genbank_file_id
        )
      SELECT colonies.id, colonies.genotype_confirmed,
             false, colonies.mgi_allele_symbol_superscript, colonies.mgi_allele_id,
             colonies.allele_type, NULL, colonies.auto_allele_description, colonies.allele_description,
             trace_files.file_alignment, trace_files.file_filtered_analysis_vcf, trace_files.file_variant_effect_output_txt,
             trace_files.file_reference_fa, trace_files.file_mutant_fa, trace_files.file_primer_reads_fa, trace_files.file_alignment_data_yaml,
             trace_files.file_trace_output, trace_files.file_trace_error, trace_files.file_exception_details, trace_files.file_return_code,
             trace_files.file_merged_variants_vcf, trace_files.exon_id, mi_attempts.created_at, mi_attempts.updated_at, alleles.genbank_file_id
      FROM colonies
        JOIN mi_attempts ON mi_attempts.id = colonies.mi_attempt_id     
        LEFT JOIN trace_files ON colonies.id = trace_files.colony_id
        LEFT JOIN alleles ON alleles.es_cell_id = mi_attempts.es_cell_id
        ;
      
      ----
      INSERT INTO alleles(
        colony_id, allele_confirmed, 
        mgi_allele_symbol_without_impc_abbreviation, mgi_allele_symbol_superscript, 
        mgi_allele_accession_id, allele_type, NULL, allele_symbol_superscript_template, auto_allele_description, allele_description, created_at, updated_at, genbank_file_id, genbank_transition
        )
      SELECT colonies.id, colonies.genotype_confirmed,
             false, colonies.mgi_allele_symbol_superscript, colonies.mgi_allele_id,
             colonies.allele_type, colonies.auto_allele_description, colonies.allele_description,
             mouse_allele_mods.created_at, mouse_allele_mods.updated_at, alleles.genbank_file_id,
             CASE WHEN colonies.allele_type IN ('b', '.1', 'e.1') THEN 'cre'
                  WHEN colonies.allele_type = 'c' THEN 'flp'
                  WHEN colonies.allele_type= 'd' THEN 'flp-cre'
                  ELSE NULL END
      FROM colonies
        JOIN mouse_allele_mods ON mouse_allele_mods.id = colonies.mouse_allele_mod_id
        JOIN colonies pc ON pc.id = mouse_allele_mods.parent_colony_id
        JOIN mi_attempts ON mi_attempts.id = pc.mi_attempt_id
        LEFT JOIN alleles ON alleles.es_cell_id = mi_attempts.es_cell_id
        ;

      ----
      UPDATE production_centre_qcs SET allele_id = allele_id
      FROM colonies, alleles
      WHERE colonies.id = production_centre_qcs.colony_id AND alleles.colony_id = colonies.id
      ;

      ----
      UPDATE vcf_modifications SET allele_id = trace_files.allele_id
      FROM trace_files
      WHERE vcf_modifications.trace_call_id = trace_files.id
      ;

    EOF

    ActiveRecord::Base.connection.execute(sql)

    remove_column :alleles, :colony_id
    remove_column :alleles, :auto_allele_description
    remove_column :alleles, :allele_description
    remove_column :alleles, :mutant_fa
    remove_column :alleles, :reference_fa
    remove_column :alleles, :mutant_protein_fa
    remove_column :alleles, :reference_protein_fa
    remove_column :alleles, :alignment
    remove_column :alleles, :filtered_analysis_vcf
    remove_column :alleles, :merged_variants_vcf
    remove_column :alleles, :variant_effect_predictor_output
    remove_column :alleles, :primer_reads_fa
    remove_column :alleles, :alignment_data_yaml
    remove_column :alleles, :trace_output
    remove_column :alleles, :trace_error
    remove_column :alleles, :exception_details
    remove_column :alleles, :return_code
    remove_column :alleles, :exon_id

    remove_column :production_centre_qcs, :production_centre_qcs
    remove_column :production_centre_qcs, :qc_southern_blot
    remove_column :production_centre_qcs, :qc_five_prime_lr_pcr
    remove_column :production_centre_qcs, :qc_five_prime_cassette_integrity
    remove_column :production_centre_qcs, :qc_tv_backbone_assay
    remove_column :production_centre_qcs, :qc_neo_count_qpcr
    remove_column :production_centre_qcs, :qc_lacz_count_qpcr
    remove_column :production_centre_qcs, :qc_neo_sr_pcr
    remove_column :production_centre_qcs, :qc_loa_qpcr
    remove_column :production_centre_qcs, :qc_homozygous_loa_sr_pcr
    remove_column :production_centre_qcs, :qc_lacz_sr_pcr
    remove_column :production_centre_qcs, :qc_mutant_specific_sr_pcr
    remove_column :production_centre_qcs, :qc_loxp_confirmation
    remove_column :production_centre_qcs, :qc_three_prime_lr_pcr
    remove_column :production_centre_qcs, :qc_critical_region_qpcr
    remove_column :production_centre_qcs, :qc_loxp_srpcr
    remove_column :production_centre_qcs, :qc_loxp_srpcr_and_sequencing

    remove_column :vcf_modifications, :trace_call_id
  end
end
