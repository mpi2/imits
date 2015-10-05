class MgiAlleleLoad::EsCellReport

  attr_accessor :es_cell_mgi_allele


  def es_cell_mgi_allele
    @es_cell_mgi_allele ||= ActiveRecord::Base.connection.execute(self.class.mgi_allele_sql)
  end

  class << self

    def show_columns
      [{'title' => 'mgi_accession_id', 'field' => 'mgi_accession_id'},
       {'title' => 'assembly', 'field' => 'assembly'},
       {'title' => 'cassette', 'field' => 'cassette'},
       {'title' => 'pipeline', 'field' => 'pipeline'},
       {'title' => 'ikmc_project_id', 'field' => 'ikmc_project_id'},
       {'title' => 'es_cell_clone', 'field' => 'es_cell_clone'},
       {'title' => 'parent_cell_line', 'field' => 'parent_cell_line'},
       {'title' => 'allele_symbol_superscript', 'field' => 'allele_symbol_superscript'},
       {'title' => 'mutation_type', 'field' => 'mutation_type'},
       {'title' => 'mutation_subtype', 'field' => 'mutation_subtype'},
       {'title' => 'cassette_start', 'field' => 'cassette_start'},
       {'title' => 'cassette_end', 'field' => 'cassette_end'},
       {'title' => 'loxp_start', 'field' => 'loxp_start'},
       {'title' => 'loxp_end', 'field' => 'loxp_end'},
       {'title' => 'is_mixed', 'field' => 'is_mixed'}
       ]
    end

    def mgi_allele_sql
      <<-EOF
      WITH clones_injected AS (
         SELECT es_cell_id, colonies.allele_type
         FROM mi_attempts
           JOIN colonies ON colonies.mi_attempt_id = mi_attempts.id AND colonies.genotype_confirmed = true AND colonies.allele_type IS NOT NULL
         GROUP BY es_cell_id, colonies.allele_type
      )

      SELECT genes.mgi_accession_id AS mgi_accession_id,
             targ_rep_alleles.assembly AS assembly, targ_rep_alleles.cassette AS cassette,
             targ_rep_alleles.cassette_start AS cassette_start, targ_rep_alleles.cassette_end AS cassette_end, targ_rep_alleles.loxp_start AS loxp_start, targ_rep_alleles.loxp_end AS loxp_end,
             targ_rep_pipelines.name AS pipeline, targ_rep_es_cells.ikmc_project_id AS ikmc_project_id, targ_rep_es_cells.name AS es_cell_clone, targ_rep_es_cells.parental_cell_line AS parent_cell_line,
             targ_rep_es_cells.mgi_allele_symbol_superscript AS allele_symbol_superscript,
             targ_rep_mutation_types.name AS mutation_type,
             targ_rep_mutation_subtypes.name AS mutation_subtype,
             CASE WHEN clones_injected.allele_type IS NOT NULL AND clones_injected.allele_type != targ_rep_es_cells.allele_type THEN 'yes' ELSE 'no' END AS is_mixed
      FROM targ_rep_es_cells
        LEFT JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_es_cells.pipeline_id
        JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
        JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
        LEFT JOIN targ_rep_mutation_subtypes ON targ_rep_mutation_subtypes.id = targ_rep_alleles.mutation_subtype_id
        JOIN genes ON genes.id = targ_rep_alleles.gene_id
        LEFT JOIN clones_injected ON clones_injected.es_cell_id = targ_rep_es_cells.id

      WHERE targ_rep_es_cells.report_to_public = true OR clones_injected.es_cell_id IS NOT NULL

      ORDER BY genes.mgi_accession_id
      EOF
    end
  end

end