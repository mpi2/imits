class MgiAlleleLoad::MixedCloneAlleleReport

  attr_accessor :mixed_clone_mgi_allele


  def mixed_clone_mgi_allele
    @mixed_clone_mgi_allele ||= ActiveRecord::Base.connection.execute(self.class.mgi_allele_sql)
  end

  class << self

    def show_columns
      [{'title' => 'Marker Symbol', 'field' => 'marker_symbol'},
       {'title' => 'MGI Accession ID', 'field' => 'mgi_accession_id'},
       {'title' => 'Colony Name', 'field' => 'colony_name'},
       {'title' => 'Colony Background Strian', 'field' => 'colony_background_strain'},
       {'title' => 'Production Centre', 'field' => 'production_centre'},
       {'title' => 'mutation_type', 'field' => 'mutation_type'},
       {'title' => 'Es Cell Allele Symbol', 'field' => 'mi_attempt_es_cell_allele_symbol'},
       {'title' => 'Es Cell MGI Allele Accession', 'field' => 'mi_attempt_es_cell_mgi_allele_accession'},
       {'title' => 'Es Cell Name', 'field' => 'mi_attempt_es_cell_name'},
       {'title' => 'Es Cell Line', 'field' => 'mi_attempt_es_cell_line'},
       {'title' => 'MGI Allele Accession', 'field' => 'mgi_allele_accession'},
       {'title' => 'MGI Allele Name', 'field' => 'mgi_allele_name'}
       ]
    end

    def mgi_allele_sql
      <<-EOF
      SELECT
        genes.marker_symbol AS marker_symbol,
        genes.mgi_accession_id AS mgi_accession_id,
        colonies.name AS colony_name, colonies.allele_type AS mutation_type, colonies.mgi_allele_id AS mgi_allele_accession, colonies.mgi_allele_symbol_superscript AS mgi_allele_name,
        background_strains.name AS colony_background_strain,
        centres.name AS production_centre,
        colonies.allele_type AS mutation_type,
        targ_rep_es_cells.name AS mi_attempt_es_cell_name,
        targ_rep_es_cells.mgi_allele_symbol_superscript AS mi_attempt_es_cell_allele_symbol,
        targ_rep_es_cells.mgi_allele_id AS mi_attempt_es_cell_mgi_allele_accession,
        targ_rep_es_cells.parental_cell_line AS mi_attempt_es_cell_line,
        colonies.mgi_allele_id AS mgi_allele_accession,
        colonies.mgi_allele_symbol_superscript AS mgi_allele_name

      FROM mi_attempts
        JOIN colonies ON colonies.mi_attempt_id = mi_attempts.id AND colonies.allele_type IS NOT NULL
        LEFT JOIN strains background_strains ON background_strains.id = colonies.background_strain_id
        JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
        JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
        JOIN genes ON genes.id = mi_plans.gene_id
        JOIN centres ON centres.id = mi_plans.production_centre_id
      WHERE colonies.allele_type != targ_rep_es_cells.allele_type AND colonies.genotype_confirmed = true
      ORDER BY mgi_accession_id
      EOF
    end
  end

end