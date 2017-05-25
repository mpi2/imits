class RefactorAlleleStructureForMiAttempts < ActiveRecord::Migration

  def self.up
    add_column :alleles, :colony_id, :integer
    add_column :alleles, :auto_allele_description, :text
    add_column :alleles, :allele_description, :text
    add_column :alleles, :mutant_fa, :text
    add_column :alleles, :genbank_transition, :string
    add_column :alleles, :same_as_es_cell, :boolean
    add_column :alleles, :allele_subtype, :string
    add_column :alleles, :contains_lacZ, :boolean, :default => false

    add_column :production_centre_qcs, :southern_blot, :string
    add_column :production_centre_qcs, :five_prime_lr_pcr, :string
    add_column :production_centre_qcs, :five_prime_cassette_integrity, :string
    add_column :production_centre_qcs, :tv_backbone_assay, :string
    add_column :production_centre_qcs, :neo_count_qpcr, :string
    add_column :production_centre_qcs, :lacz_count_qpcr, :string
    add_column :production_centre_qcs, :neo_sr_pcr, :string
    add_column :production_centre_qcs, :loa_qpcr, :string
    add_column :production_centre_qcs, :homozygous_loa_sr_pcr, :string
    add_column :production_centre_qcs, :lacz_sr_pcr, :string
    add_column :production_centre_qcs, :mutant_specific_sr_pcr, :string
    add_column :production_centre_qcs, :loxp_confirmation, :string
    add_column :production_centre_qcs, :three_prime_lr_pcr, :string
    add_column :production_centre_qcs, :critical_region_qpcr, :string
    add_column :production_centre_qcs, :loxp_srpcr, :string
    add_column :production_centre_qcs, :loxp_srpcr_and_sequencing, :string

    add_column :colonies, :is_released_from_genotyping, :boolean, :default => false
    add_column :colonies, :genotyping_comment, :text
    change_column :colonies, :report_to_public, :boolean, :default => true

    sql = <<-EOF

      INSERT INTO alleles(
        colony_id, allele_confirmed, mgi_allele_symbol_without_impc_abbreviation,
        mgi_allele_symbol_superscript, 
        mgi_allele_accession_id,
        allele_type, 
        auto_allele_description, allele_description,
        created_at, updated_at, genbank_file_id,
        same_as_es_cell
        )
      SELECT colonies.id, colonies.genotype_confirmed, false, 
             CASE WHEN alleles.id IS NULL OR ( colonies.allele_type IS NOT NULL AND colonies.allele_type != alleles.allele_type) THEN colonies.mgi_allele_symbol_superscript ELSE alleles.mgi_allele_symbol_superscript END,
             CASE WHEN alleles.id IS NULL OR ( colonies.allele_type IS NOT NULL AND colonies.allele_type != alleles.allele_type) THEN colonies.mgi_allele_id ELSE alleles.mgi_allele_accession_id END,
             CASE WHEN alleles.id IS NULL OR ( colonies.allele_type IS NOT NULL) THEN colonies.allele_type ELSE alleles.allele_type END,
             colonies.auto_allele_description, colonies.allele_description,
             mi_attempts.created_at, mi_attempts.updated_at, 
             CASE WHEN alleles.id IS NULL OR (colonies.allele_type IS NOT NULL AND colonies.allele_type != alleles.allele_type) THEN NULL ELSE alleles.genbank_file_id END,
             CASE WHEN alleles.id IS NULL THEN false WHEN colonies.allele_type IS NOT NULL AND colonies.allele_type != alleles.allele_type THEN false ELSE true END,
      FROM colonies
        JOIN mi_attempts ON mi_attempts.id = colonies.mi_attempt_id    
        LEFT JOIN alleles ON alleles.es_cell_id = mi_attempts.es_cell_id
        ;
      
      ----
      INSERT INTO alleles(
        colony_id, allele_confirmed, mgi_allele_symbol_without_impc_abbreviation,
        mgi_allele_symbol_superscript, 
        mgi_allele_accession_id,
        allele_type,
        auto_allele_description, allele_description,
        created_at, updated_at, genbank_file_id, genbank_transition,
        same_as_es_cell
        )
      SELECT colonies.id, colonies.genotype_confirmed,
             false, colonies.mgi_allele_symbol_superscript, colonies.mgi_allele_id,
             colonies.allele_type, colonies.auto_allele_description, colonies.allele_description,
             mouse_allele_mods.created_at, mouse_allele_mods.updated_at, alleles.genbank_file_id,
             CASE WHEN colonies.allele_type IN ('b', '.1', 'e.1') THEN 'cre'
                  WHEN colonies.allele_type = 'c' THEN 'flp'
                  WHEN colonies.allele_type= 'd' THEN 'flp-cre'
                  ELSE NULL END,
            NULL
      FROM colonies
        JOIN mouse_allele_mods ON mouse_allele_mods.id = colonies.mouse_allele_mod_id
        JOIN colonies pc ON pc.id = mouse_allele_mods.parent_colony_id
        JOIN mi_attempts ON mi_attempts.id = pc.mi_attempt_id
        LEFT JOIN alleles ON alleles.es_cell_id = mi_attempts.es_cell_id
        ;


      ----
      INSERT INTO production_centre_qcs(allele_id, southern_blot, five_prime_lr_pcr, five_prime_cassette_integrity, tv_backbone_assay, neo_count_qpcr, 
        lacz_count_qpcr, neo_sr_pcr, loa_qpcr, homozygous_loa_sr_pcr, lacz_sr_pcr, mutant_specific_sr_pcr, loxp_confirmation, three_prime_lr_pcr, 
        critical_region_qpcr, loxp_srpcr, loxp_srpcr_and_sequencing)
      SELECT alleles.id, colony_qcs.qc_southern_blot, colony_qcs.qc_five_prime_lr_pcr, colony_qcs.qc_five_prime_cassette_integrity, colony_qcs.qc_tv_backbone_assay,
        colony_qcs.qc_neo_count_qpcr, colony_qcs.qc_lacz_count_qpcr, colony_qcs.qc_neo_sr_pcr, colony_qcs.qc_loa_qpcr, colony_qcs.qc_homozygous_loa_sr_pcr,
        colony_qcs.qc_lacz_sr_pcr, colony_qcs.qc_mutant_specific_sr_pcr, colony_qcs.qc_loxp_confirmation, colony_qcs.qc_three_prime_lr_pcr, 
        colony_qcs.qc_critical_region_qpcr, colony_qcs.qc_loxp_srpcr, colony_qcs.qc_loxp_srpcr_and_sequencing
      FROM colony_qcs
        JOIN alleles ON alleles.colony_id = colony_qcs.colony_id
      ;

      ---
      UPDATE colonies SET report_to_public = mi_attempts.report_to_public
        FROM mi_attempts
      WHERE mi_attempts.id = colonies.mi_attempt_id AND mi_attempts.es_cell_id IS NOT NULL;

      ---
      UPDATE colonies SET genotyping_comment = mi_attempts.genotyping_comment, is_released_from_genotyping = mi_attempts.is_released_from_genotyping
        FROM mi_attempts
      WHERE mi_attempts.id = colonies.mi_attempt_id;

    EOF

    ActiveRecord::Base.connection.execute(sql)
 
    drop_table :colony_qcs
    remove_column :mi_attempts, :genotyping_comment
    remove_column :mi_attempts, :is_released_from_genotyping
  end
end
