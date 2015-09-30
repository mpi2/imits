class MgiAlleleLoad::MouseAlleleModReport

  attr_accessor :phenotype_attempt_mgi_allele


  def phenotype_attempt_mgi_allele
    @phenotype_attempt_mgi_allele ||= ActiveRecord::Base.connection.execute(self.class.mgi_allele_sql)
  end

  class << self

    def show_columns
      [{'title' => 'Marker Symbol', 'field' => 'marker_symbol'},
       {'title' => 'MGI Accession ID', 'field' => 'mgi_accession_id'},
       {'title' => 'Mi Attempt Colony Name', 'field' => 'mi_attempt_colony_name'},
       {'title' => 'Mi Attempt Colony Background Strian', 'field' => 'mi_attempt_colony_background_strain'},
       {'title' => 'Mi Attempt Production Centre', 'field' => 'mi_attempt_production_centre'},
       {'title' => 'Mi Attempt Allele Symbol', 'field' => 'mi_attempt_allele_symbol'},
       {'title' => 'Mi Attempt Es Cell Allele Symbol', 'field' => 'mi_attempt_es_cell_allele_symbol'},
       {'title' => 'Mi Attempt Es Cell MGI Allele Accession', 'field' => 'mi_attempt_es_cell_mgi_allele_accession'},
       {'title' => 'Mi Attempt Es Cell Name', 'field' => 'mi_attempt_es_cell_name'},
       {'title' => 'Mi Attempt Es Cell Line', 'field' => 'mi_attempt_es_cell_line'},
       {'title' => 'Colony Name', 'field' => 'colony_name'},
       {'title' => 'Excision Type', 'field' => 'excision_type'},
       {'title' => 'Tat Cre', 'field' => 'tat_cre'},
       {'title' => 'Phenotype Attempt Deleter Strain', 'field' => 'phenotype_attempt_deleter_strain'},
       {'title' => 'Phenotype Attempt Colony Background Strain', 'field' => 'phenotype_attempt_colony_background_strain'},
       {'title' => 'Phenotype Attempt Production Centre', 'field' => 'phenotype_attempt_production_centre'},
       {'title' => 'MGI Allele Accession', 'field' => 'mgi_allele_accession'},
       {'title' => 'MGI Allele Name', 'field' => 'mgi_allele_name'}
       ]
    end

    def mgi_allele_sql
      <<-EOF
      SELECT
        genes.marker_symbol AS marker_symbol,
        genes.mgi_accession_id AS mgi_accession_id,
        parent_colony.name AS mi_attempt_colony_name,
        ma_colony_background_strain.name AS mi_attempt_colony_background_strain,
        ma_centres.name AS mi_attempt_production_centre,
        CASE
          WHEN targ_rep_es_cells.allele_symbol_superscript_template IS NOT NULL AND targ_rep_es_cells.allele_symbol_superscript_template != ''
            AND parent_colony.allele_type IS NOT NULL AND parent_colony.allele_type != ''
            AND parent_colony.allele_type != targ_rep_es_cells.allele_type
          THEN
            regexp_replace(targ_rep_es_cells.allele_symbol_superscript_template, '#{TargRep::Allele::TEMPLATE_CHARACTER}' , parent_colony.allele_type)
          ELSE
            targ_rep_es_cells.mgi_allele_symbol_superscript
        END AS mi_attempt_allele_symbol,
        targ_rep_es_cells.mgi_allele_symbol_superscript AS mi_attempt_es_cell_allele_symbol,
        targ_rep_es_cells.mgi_allele_id AS mi_attempt_es_cell_mgi_allele_accession,
        targ_rep_es_cells.name AS mi_attempt_es_cell_name,
        targ_rep_es_cells.parental_cell_line AS mi_attempt_es_cell_line,
        mam_colony.name AS colony_name,
        CASE
          WHEN mam_colony.allele_type = 'b'
          THEN
            'cre'
          WHEN mam_colony.allele_type = 'c'
          THEN
            'flp'
          WHEN mam_colony.allele_type = 'd'
          THEN
            'flp-cre'
          WHEN mam_colony.allele_type = '.1'
          THEN
            'cre'
          WHEN mam_colony.allele_type = 'e.1'
          THEN
            'cre'
          ELSE ''
        END AS excision_type,
        mouse_allele_mods.tat_cre AS tat_cre,
        pa_deleter_strains.name AS phenotype_attempt_deleter_strain,
        pa_colony_background_strains.name AS phenotype_attempt_colony_background_strain,
        pa_centres.name AS phenotype_attempt_production_centre,
        mam_colony.mgi_allele_id AS mgi_allele_accession,
        mam_colony.mgi_allele_symbol_superscript AS mgi_allele_name

      FROM mouse_allele_mods
      JOIN colonies AS mam_colony ON mam_colony.mouse_allele_mod_id = mouse_allele_mods.id
      JOIN mouse_allele_mod_status_stamps ON mouse_allele_mod_status_stamps.mouse_allele_mod_id = mouse_allele_mods.id AND mouse_allele_mod_status_stamps.status_id = 6
      LEFT JOIN strains AS pa_colony_background_strains ON pa_colony_background_strains.id = mam_colony.background_strain_id
      LEFT JOIN deleter_strains AS pa_deleter_strains ON pa_deleter_strains.id = mouse_allele_mods.deleter_strain_id
      JOIN (mi_plans AS pa_mi_plans JOIN centres AS pa_centres ON pa_centres.id = pa_mi_plans.production_centre_id) ON pa_mi_plans.id = mouse_allele_mods.mi_plan_id
      JOIN genes ON genes.id = pa_mi_plans.gene_id
      JOIN colonies AS parent_colony ON parent_colony.id = mouse_allele_mods.parent_colony_id
      JOIN (mi_attempts JOIN mi_plans AS ma_plans ON mi_attempts.mi_plan_id = ma_plans.id JOIN centres AS ma_centres ON ma_centres.id = ma_plans.production_centre_id) ON mi_attempts.id = parent_colony.mi_attempt_id
      LEFT JOIN strains AS ma_colony_background_strain ON ma_colony_background_strain.id = parent_colony.background_strain_id
      JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
      ORDER BY mgi_accession_id
      EOF
    end
  end

end