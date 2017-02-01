class MgiAlleleLoad::CrisprAlleleReport

  attr_accessor :crispr_mgi_allele


  def crispr_mgi_allele
    @crispr_mgi_allele ||= ActiveRecord::Base.connection.execute(self.class.mgi_allele_sql)
  end

  class << self

    def show_columns
      [{'title' => 'Marker Symbol', 'field' => 'marker_symbol'},
       {'title' => 'MGI Accession ID', 'field' => 'mgi_accession_id'},
       {'title' => 'ES Cell Line', 'field' => 'es_cell_line'},
       {'title' => 'Colony Name', 'field' => 'colony_name'},
       {'title' => 'Colony Background Strian', 'field' => 'colony_background_strain'},
       {'title' => 'Project Name', 'field' => 'project_name'},
       {'title' => 'Production Centre', 'field' => 'production_centre'},

       {'title' => 'Nuclease', 'field' => 'nuclease'},
       {'title' => 'Nuclease Form', 'field' => 'nuclease_form'},
       {'title' => 'Guide Sequences', 'field' => 'guide_sequences'},
       {'title' => 'Donor Sequences', 'field' => 'donor_sequences'},
       {'title' => 'Plasmid ID', 'field' => 'plasmid_ids'},

       {'title' => 'Molecular Mutation', 'field' => 'molecular_mutation'},
       {'title' => 'Attributes', 'field' => 'attributes'},

       {'title' => 'Allele Characterized', 'field' => 'allele_characterized'},
       {'title' => 'Consequence to Protein', 'field' => 'consequence_to_protein'},
       {'title' => 'Molecular Characterization', 'field' => 'molecular_characterization'},
       {'title' => 'MGI Allele Accession', 'field' => 'mgi_allele_accession'},
       {'title' => 'MGI Allele Name', 'field' => 'mgi_allele_name'}
       ]
    end

    def mgi_allele_sql
      <<-EOF
      WITH crisprs AS (
          SELECT mi_attempts.id AS mi_attempt_id, string_agg(targ_rep_crisprs.sequence, '|') AS guides
          FROM targ_rep_crisprs
            JOIN mi_attempts ON mi_attempts.mutagenesis_factor_id = targ_rep_crisprs.mutagenesis_factor_id
          GROUP BY mi_attempts.id
        ),

        donors AS (
          SELECT mi_attempts.id AS mi_attempt_id, count(mutagenesis_factor_donors.oligo_sequence_fa) num_oligos, string_agg(mutagenesis_factor_donors.oligo_sequence_fa, '|') AS donor_sequences,
          string_agg(targ_rep_targeting_vectors.name, '|') AS plasmid_ids
          FROM targ_rep_targeting_vectors
            JOIN mutagenesis_factor_donors ON mutagenesis_factor_donors.vector_id = targ_rep_targeting_vectors.id
            LEFT JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_targeting_vectors.allele_id
            JOIN mi_attempts ON mi_attempts.mutagenesis_factor_id = mutagenesis_factor_donors.mutagenesis_factor_id
          GROUP BY mi_attempts.id
        ),
        characterized_alleles AS (
          SELECT trace_calls.colony_id AS colony_id, trace_calls.file_mutant_fa AS protein_sequence,
          string_agg( 'Chromosome:' || tcvm.chr || ' Start:' || tcvm.start || ' ' || (CASE WHEN tcvm.mod_type = 'del' THEN 'deletion' WHEN tcvm.mod_type = 'ins' THEN 'insertion' WHEN tcvm.mod_type = 'snp' THEN 'nucleotide_substitutions' ELSE tcvm.mod_type END) || ':' || (tcvm.end - tcvm.start + 1) || 'bp ' || (CASE WHEN tcvm.mod_type = 'del' THEN  'mutation:' || substring( tcvm.ref_seq from 2 for (tcvm.end - tcvm.start + 1) ) WHEN tcvm.mod_type = 'ins' THEN 'mutation:' ||  substring( tcvm.alt_seq from 2 for (tcvm.end - tcvm.start + 1) ) WHEN tcvm.mod_type = 'snp' THEN 'mutation:' || tcvm.ref_seq || '/' || tcvm.alt_seq ELSE '' END), '|') AS molecular_characterization
          FROM trace_calls
          JOIN trace_call_vcf_modifications tcvm ON trace_calls.id = tcvm.trace_call_id
          GROUP BY trace_calls.colony_id, trace_calls.file_mutant_fa
        )



      SELECT
        genes.marker_symbol AS marker_symbol,
        genes.mgi_accession_id AS mgi_accession_id,
        genes.chr AS chromosome,
        colonies.name AS colony_name, colonies.allele_type AS mutation_type, colonies.mgi_allele_id AS mgi_allele_accession, colonies.mgi_allele_symbol_superscript AS mgi_allele_name,
        blast_strains.name AS es_cell_line,
        background_strains.name AS colony_background_strain,
        centres.name AS production_centre,
        CASE WHEN mi_attempts.mrna_nuclease IS NOT NULL THEN mi_attempts.mrna_nuclease 
            WHEN mi_attempts.protein_nuclease IS NOT NULL THEN mi_attempts.protein_nuclease
            ELSE '' 
            END AS nuclease,
        CASE WHEN mi_attempts.mrna_nuclease IS NOT NULL THEN 'RNA' 
            WHEN mi_attempts.protein_nuclease IS NOT NULL THEN 'Protein'
            ELSE '' 
            END AS nuclease_form,
        crisprs.guides AS guide_sequences,
        CASE WHEN donors.num_oligos > 0 THEN donors.donor_sequences ELSE '' END AS donor_sequences,
        CASE WHEN donors.num_oligos = 0 THEN donors.plasmid_ids ELSE '' END AS plasmid_ids,
        colonies.mgi_allele_id AS mgi_allele_accession,
        colonies.mgi_allele_symbol_superscript AS mgi_allele_name,
        CASE WHEN characterized_alleles.colony_id IS NULL THEN 'No' ELSE 'Yes' END AS allele_characterized,
        characterized_alleles.molecular_characterization AS molecular_characterization,
        characterized_alleles.protein_sequence AS consequence_to_protein,
        CASE WHEN donors.num_oligos > 0 OR donors.plasmid_ids IS NOT NULL THEN 'Null or Conditional Ready or humanized sequence' ELSE 'Null' END AS attributes,
        CASE WHEN donors.num_oligos = 1 THEN 'Nucleotide substitutions' ELSE 'Intragenic deletion' END AS molecular_mutation,
        'IMPC' AS project_name
      FROM mi_attempts
        JOIN colonies ON colonies.mi_attempt_id = mi_attempts.id AND colonies.genotype_confirmed = true
        LEFT JOIN strains blast_strains ON blast_strains.id = mi_attempts.blast_strain_id
        LEFT JOIN strains background_strains ON background_strains.id = colonies.background_strain_id
        JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
        JOIN crisprs ON crisprs.mi_attempt_id = mi_attempts.id
        LEFT JOIN donors ON donors.mi_attempt_id = mi_attempts.id
        JOIN genes ON genes.id = mi_plans.gene_id
        JOIN centres ON centres.id = mi_plans.production_centre_id
        LEFT JOIN characterized_alleles ON characterized_alleles.colony_id = colonies.id

      WHERE colonies.genotype_confirmed = true
      ORDER BY mgi_accession_id
      EOF
    end
  end

end