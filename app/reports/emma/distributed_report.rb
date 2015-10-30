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
       {'title' => 'Mutation Type', 'field' => 'mutation_type'},
       {'title' => 'Allele Description', 'field' => 'allele_description'},
       {'title' => 'Colony Name', 'field' => 'colony_name'},
       {'title' => 'Colony Background Strian', 'field' => 'colony_background_strain'},
       {'title' => 'Production Centre', 'field' => 'production_centre'},
       {'title' => 'Mutagenesis Factor Details', 'field' => 'mutagenesis_details'},
       {'title' => 'MGI Allele Accession', 'field' => 'mgi_allele_accession'},
       {'title' => 'MGI Allele Name', 'field' => 'mgi_allele_name'}
       ]
    end

    def mgi_allele_sql
      <<-EOF
      WITH mutagenesis_factor_summary AS (
        SELECT mi_attempts.id AS mi_attempt_id, array_agg(mutagenesis_factors.id), array_agg('vector_name:' || CASE WHEN targ_rep_targeting_vectors.name IS NULL THEN '' ELSE  targ_rep_targeting_vectors.name END || ' | ' || crispr_details) AS mutagenesis_details
        FROM mutagenesis_factors
          JOIN mi_attempts ON mi_attempts.mutagenesis_factor_id = mutagenesis_factors.id
          JOIN (SELECT targ_rep_crisprs.mutagenesis_factor_id AS mutagenesis_factor_id, string_agg('crispr_seq:' || targ_rep_crisprs.sequence || ', crispr_chromosome:' || targ_rep_crisprs.start || ', crispr_start_co_ordinate:' || targ_rep_crisprs.start || ', crispr_end_co_ordinate:' || targ_rep_crisprs.end, ' | ') AS crispr_details
                  FROM targ_rep_crisprs
                GROUP BY targ_rep_crisprs.mutagenesis_factor_id
               ) AS crispr_summary ON mutagenesis_factors.id = crispr_summary.mutagenesis_factor_id
          LEFT JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.id = mutagenesis_factors.vector_id
        GROUP BY mi_attempts.id
      )

      SELECT
        genes.marker_symbol AS marker_symbol,
        genes.mgi_accession_id AS mgi_accession_id,
        colonies.name AS colony_name, colonies.allele_type AS mutation_type, colonies.mgi_allele_id AS mgi_allele_accession, colonies.mgi_allele_symbol_superscript AS mgi_allele_name,
        blast_strains.name AS es_cell_line,
        background_strains.name AS colony_background_strain,
        centres.name AS production_centre,
        'Deletion' AS mutation_type,
        mutagenesis_factor_summary.mutagenesis_details AS mutagenesis_details,
        'example description) This allele from project Adad2-5594J-B was generated at The Jackson Laboratory by injecting Cas9 RNA and guide sequence CCCATGCTCAGCGGTCCTAG, which resulted in an 8 bp deletion CTAGGACC and a 4 bp insertion ATGA in exon1 beginning at Chromosome 8 positive strand position 119612902 bp (GRCm38) and is predicted to cause a frameshift mutation with early truncation' AS allele_description,
        colonies.mgi_allele_id AS mgi_allele_accession,
        colonies.mgi_allele_symbol_superscript AS mgi_allele_name
      FROM mi_attempts
        JOIN colonies ON colonies.mi_attempt_id = mi_attempts.id AND colonies.genotype_confirmed = true
        JOIN mutagenesis_factor_summary ON mutagenesis_factor_summary.mi_attempt_id = mi_attempts.id
        LEFT JOIN strains blast_strains ON blast_strains.id = mi_attempts.blast_strain_id
        LEFT JOIN strains background_strains ON background_strains.id = colonies.background_strain_id
        JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
        JOIN genes ON genes.id = mi_plans.gene_id
        JOIN centres ON centres.id = mi_plans.production_centre_id
      WHERE colonies.genotype_confirmed = true
      ORDER BY mgi_accession_id
      EOF
    end
  end

end