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
       {'title' => 'cassette_start', 'field' => 'cassette_start'},
       {'title' => 'cassette_end', 'field' => 'cassette_end'},
       {'title' => 'loxp_start', 'field' => 'loxp_start'},
       {'title' => 'loxp_end', 'field' => 'loxp_end'},
       {'title' => 'is_mixed', 'field' => 'is_mixed'}
       ]
    end

    def mgi_allele_sql
      <<-EOF
      SELECT genes.mgi_accession_id AS mgi_accession_id,
             targ_rep_alleles.assembly AS assembly, targ_rep_alleles.cassette AS cassette,
             targ_rep_alleles.cassette_start AS cassette_start, targ_rep_alleles.cassette_end AS cassette_end, targ_rep_alleles.loxp_start AS loxp_start, targ_rep_alleles.loxp_end AS loxp_end,
             targ_rep_pipelines.name AS pipeline, targ_rep_es_cells.ikmc_project_id AS ikmc_project_id, targ_rep_es_cells.name AS es_cell_clone, targ_rep_es_cells.parental_cell_line AS parent_cell_line,
             targ_rep_es_cells.mgi_allele_symbol_superscript AS allele_symbol_superscript, targ_rep_es_cells.allele_type AS mutation_type,
             CASE WHEN colonies.allele_type IS NOT NULL AND colonies.allele_type != targ_rep_es_cells.allele_type THEN 'yes' ELSE 'no' END AS is_mixed
      FROM targ_rep_es_cells
        LEFT JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_es_cells.pipeline_id
        JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
        JOIN genes ON genes.id = targ_rep_alleles.gene_id
        LEFT JOIN (mi_attempts JOIN colonies ON colonies.mi_attempt_id = mi_attempts.id AND colonies.genotype_confirmed) ON mi_attempts.es_cell_id = targ_rep_es_cells.id

      WHERE targ_rep_es_cells.reporT_to_public = true
      ORDER BY genes.mgi_accession_id
      EOF
    end
  end

end