class Mp2Load::PhenotypingColoniesReportEsCell

  attr_accessor :phenotyping_colonies


  def phenotyping_colonies
    @phenotyping_colonies ||= process_data(ActiveRecord::Base.connection.execute(self.class.phenotyping_colonies_sql))
  end

  def process_data(data)
    process_data = []

    data.each do |row|
      processed_row = row.dup
      if processed_row['mgi_allele_symbol_superscript'].blank?
        processed_row['allele_symbol'] = ''
      else
        processed_row['allele_symbol'] = "#{processed_row['gene_marker_symbol']}<#{processed_row['mgi_allele_symbol_superscript']}>"
      end
      process_data << processed_row
    end

    return process_data
  end
  private :process_data



  class << self

    def show_columns
      [{'title' => 'Marker Symbol', 'field' => 'gene_marker_symbol'},
       {'title' => 'MGI Accession ID', 'field' => 'gene_mgi_accession_id'},
       {'title' => 'Colony Name', 'field' => 'phenotyping_colony_name'},
       {'title' => 'Es Cell Name', 'field' => 'es_cell_name'},
       {'title' => 'Colony Background Strain', 'field' => 'background_strain_name'},
       {'title' => 'Mgi Strain Accession id', 'field' => 'mgi_strain_accession_id'},
       {'title' => 'Production Centre', 'field' => 'production_centre'},
       {'title' => 'Production Consortium', 'field' => 'production_consortia'},
       {'title' => 'Phenotyping Centre', 'field' => 'phenotyping_centre'},
       {'title' => 'Phenotyping Consortium', 'field' => 'phenotyping_consortia'},
       {'title' => 'Cohort Production Centre', 'field' => 'cohort_production_centre_name'},
       {'title' => 'Allele Symbol', 'field' => 'allele_symbol'},
       {'title' => 'Report Phenotype data To Public', 'field' => 'report_to_public'},
       {'title' => 'Selected For Late Adult Pipeline', 'field' => 'selected_for_late_adult_phenotyping'},
       {'title' => 'Report Late Adult Phenotype data To Public', 'field' => 'late_adult_report_to_public'}
       ]
    end

    def phenotyping_colonies_sql
      <<-EOF
      WITH plans AS (
        SELECT mi_plans.gene_id AS gene_id, mi_plans.id AS id, centres.name AS centre_name, consortia.name AS consortium_name
        FROM mi_plans
          JOIN consortia ON consortia.id = mi_plans.consortium_id
          JOIN centres ON centres.id = mi_plans.production_centre_id
        WHERE mi_plans.mutagenesis_via_crispr_cas9 = false
      ),

      colony_summary AS (
        SELECT
          colonies.id AS id,
          colonies.name,
          alleles.mgi_allele_accession_id,
          alleles.mgi_allele_symbol_superscript,
          colonies.mouse_allele_mod_id AS mouse_allele_mod_id,
          colonies.genotype_confirmed AS genotype_confirmed,
          cb_strain.name AS background_strain_name,
          cb_strain.mgi_strain_accession_id AS mgi_strain_accession_id,
          CASE WHEN mam_plan.id IS NOT NULL THEN mam_plan.consortium_name ELSE m_plan.consortium_name END AS consortium_name,
          CASE WHEN mam_plan.id IS NOT NULL THEN mam_plan.centre_name ELSE m_plan.centre_name END AS centre_name,
          targ_rep_es_cells.name AS es_cell_name
        FROM colonies
          JOIN alleles ON alleles.colony_id = colonies.id
          LEFT JOIN strains cb_strain ON cb_strain.id = colonies.background_strain_id
          LEFT JOIN mi_attempts ON mi_attempts.id = colonies.mi_attempt_id
          LEFT JOIN mouse_allele_mods ON mouse_allele_mods.id = colonies.mouse_allele_mod_id
          LEFT JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
          LEFT JOIN plans m_plan ON m_plan.id = mi_attempts.mi_plan_id
          LEFT JOIN plans mam_plan ON mam_plan.id = mouse_allele_mods.mi_plan_id
      )

      SELECT
        phenotyping_productions.colony_name AS phenotyping_colony_name,
        genes.marker_symbol AS gene_marker_symbol,
        genes.mgi_accession_id AS gene_mgi_accession_id,
        colony.centre_name AS production_centre,
        colony.consortium_name AS production_consortia,
        pp_plans.centre_name AS phenotyping_centre,
        pp_plans.consortium_name AS phenotyping_consortia,
        CASE WHEN pp_cb_strains.name IS NOT NULL THEN pp_cb_strains.name ELSE colony.background_strain_name END AS background_strain_name,
        CASE WHEN pp_cb_strains.mgi_strain_accession_id IS NOT NULL THEN pp_cb_strains.mgi_strain_accession_id ELSE '' END AS mgi_strain_accession_id,
        CASE WHEN cohort_centres.name IS NOT NULL THEN cohort_centres.name 
             ELSE colony.centre_name 
        END AS cohort_production_centre_name,
        CASE WHEN colony.es_cell_name IS NOT NULL AND colony.es_cell_name != '' THEN colony.es_cell_name ELSE mi_colony.es_cell_name END AS es_cell_name, 
        colony.mgi_allele_symbol_superscript AS mgi_allele_symbol_superscript,
        phenotyping_productions.report_to_public,
        CASE WHEN late_adult_is_active = true AND phenotyping_productions.selected_for_late_adult_phenotyping = true THEN true ELSE NULL END,
        CASE WHEN late_adult_is_active = true AND phenotyping_productions.selected_for_late_adult_phenotyping = true THEN phenotyping_productions.late_adult_report_to_public ELSE NULL END
      FROM phenotyping_productions
        JOIN plans pp_plans ON pp_plans.id = phenotyping_productions.mi_plan_id
        JOIN genes ON genes.id = pp_plans.gene_id
        JOIN colony_summary colony ON colony.id = phenotyping_productions.parent_colony_id
        LEFT JOIN strains pp_cb_strains ON pp_cb_strains.id = phenotyping_productions.colony_background_strain_id
        LEFT JOIN centres cohort_centres ON cohort_centres.id = phenotyping_productions.cohort_production_centre_id
        LEFT JOIN (mouse_allele_mods JOIN colony_summary mi_colony ON mi_colony.id = mouse_allele_mods.parent_colony_id) ON mouse_allele_mods.id = colony.mouse_allele_mod_id
      WHERE colony.genotype_confirmed = true AND phenotyping_productions.is_active = true
      ORDER BY phenotyping_colony_name
      EOF
    end
  end

end