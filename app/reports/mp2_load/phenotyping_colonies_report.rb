class Mp2Load::PhenotypingColoniesReport

  attr_accessor :phenotyping_colonies


  def phenotyping_colonies
    @phenotyping_colonies ||= process_data(ActiveRecord::Base.connection.execute(self.class.phenotyping_colonies_sql))
  end

  def process_data(data)
    process_data = []

    data.each do |row|
      processed_row = row.dup
      processed_row['allele_symbol'] = TargRep::RealAllele.calculate_allele_information({ 'allele_name' => !row['crispr_allele_name'].blank? ? row['crispr_allele_name'] : nil,
                                                                                          'allele_symbol_superscript_template' => !row['allele_symbol_superscript_template'].blank? ? row['allele_symbol_superscript_template'] : row['es_cell_allele_symbol_superscript_template'],
                                                                                          'mgi_allele_symbol_superscript' => !row['mgi_allele_symbol_superscript'].blank? ? row['mgi_allele_symbol_superscript'] : nil,
                                                                                          'es_cell_allele_type' => row['es_cell_allele_type'],
                                                                                          'colony_allele_type' => !row['allele_type'].blank? ? row['allele_type'] : nil,
                                                                                          'mi_allele_target' => !row['crispr_allele_target'].blank? ? row['crispr_allele_target'] : nil,
                                                                                          'mutation_method_allele_prefix' => !row['es_cell_allele_mutation_method_allele_prefix'].nil? ? row['es_cell_allele_mutation_method_allele_prefix'] : nil,
                                                                                          'mutation_type_allele_code' => !row['es_cell_allele_mutation_type'].nil? ? row['es_cell_allele_mutation_type'] : nil
                                                                                         })['allele_symbol']
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
       {'title' => 'Colony Background Strian', 'field' => 'background_strain_name'},
       {'title' => 'Production Centre', 'field' => 'production_centre'},
       {'title' => 'Production Consortium', 'field' => 'production_consortia'},
       {'title' => 'Phenotyping Centre', 'field' => 'phenotyping_centre'},
       {'title' => 'Phenotyping Consortium', 'field' => 'phenotyping_consortia'},
       {'title' => 'Allele Symbol', 'field' => 'allele_symbol'}
       ]
    end

    def phenotyping_colonies_sql
      <<-EOF
      WITH plans AS (
        SELECT mi_plans.gene_id AS gene_id, mi_plans.id AS id, centres.name AS centre_name, consortia.name AS consortium_name
        FROM mi_plans
          JOIN consortia ON consortia.id = mi_plans.consortium_id
          JOIN centres ON centres.id = mi_plans.production_centre_id
      ),

      colony_summary AS (
        SELECT
          colonies.id AS id,
          colonies.name,
          colonies.mgi_allele_id,
          colonies.allele_name,
          colonies.mgi_allele_symbol_superscript,
          colonies.allele_symbol_superscript_template,
          colonies.allele_type,
          colonies.mouse_allele_mod_id AS mouse_allele_mod_id,
          colonies.genotype_confirmed AS genotype_confirmed,
          cb_strain.name AS background_strain_name,
          CASE WHEN mam_plan.id IS NOT NULL THEN mam_plan.consortium_name ELSE m_plan.consortium_name END AS consortium_name,
          CASE WHEN mam_plan.id IS NOT NULL THEN mam_plan.centre_name ELSE m_plan.centre_name END AS centre_name,
          targ_rep_es_cells.mgi_allele_symbol_superscript AS es_cell_mgi_allele_symbol_superscript,
          targ_rep_es_cells.allele_type AS es_cell_allele_type,
          targ_rep_es_cells.allele_symbol_superscript_template AS es_cell_allele_symbol_superscript_template,
          targ_rep_mutation_types.allele_code AS es_cell_allele_mutation_type,
          targ_rep_mutation_methods.allele_prefix AS es_cell_allele_mutation_method_allele_prefix,
          mi_attempts.allele_target AS crispr_allele_target
        FROM colonies
          LEFT JOIN strains cb_strain ON cb_strain.id = colonies.background_strain_id
          LEFT JOIN mi_attempts ON mi_attempts.id = colonies.mi_attempt_id
          LEFT JOIN mouse_allele_mods ON mouse_allele_mods.id = colonies.mouse_allele_mod_id
          LEFT JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
          LEFT JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
          LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
          LEFT JOIN targ_rep_mutation_methods ON targ_rep_mutation_methods.id = targ_rep_alleles.mutation_method_id
          LEFT JOIN plans m_plan ON m_plan.id = mi_attempts.mi_plan_id
          LEFT JOIN plans mam_plan ON mam_plan.id = mouse_allele_mods.mi_plan_id
      )

      SELECT
        phenotyping_productions.colony_name AS phenotyping_colony_name,
        genes.marker_symbol AS gene_marker_symbol,
        genes.mgi_accession_id AS gene_mgi_accession_id,

        colony.centre_name AS production_centre,
        colony.consortium_name AS production_consortia,
        colony.crispr_allele_target AS crispr_allele_target,
        colony.allele_name AS crispr_allele_name,
        pp_plans.centre_name AS phenotyping_centre,
        pp_plans.consortium_name AS phenotyping_consortia,

        CASE WHEN pp_cb_strains.name IS NOT NULL THEN pp_cb_strains.name ELSE colony.background_strain_name END AS background_strain_name,
        CASE WHEN colony.mgi_allele_symbol_superscript IS NOT NULL AND colony.mgi_allele_symbol_superscript != '' THEN colony.mgi_allele_symbol_superscript ELSE mam_colony.mgi_allele_symbol_superscript END AS mgi_allele_symbol_superscript,
        CASE WHEN colony.allele_symbol_superscript_template IS NOT NULL AND colony.allele_symbol_superscript_template != '' THEN colony.allele_symbol_superscript_template ELSE mam_colony.allele_symbol_superscript_template END AS allele_symbol_superscript_template,
        CASE WHEN colony.allele_type IS NOT NULL AND colony.allele_type != '' THEN colony.allele_type ELSE mam_colony.allele_type END AS allele_type,

        CASE WHEN colony.es_cell_mgi_allele_symbol_superscript IS NOT NULL THEN colony.es_cell_mgi_allele_symbol_superscript ELSE mam_colony.es_cell_mgi_allele_symbol_superscript END AS es_cell_mgi_allele_symbol_superscript,
        CASE WHEN colony.es_cell_allele_type IS NOT NULL THEN colony.es_cell_allele_type ELSE mam_colony.es_cell_allele_type END AS es_cell_allele_type,
        CASE WHEN colony.es_cell_allele_symbol_superscript_template IS NOT NULL THEN colony.es_cell_allele_symbol_superscript_template ELSE mam_colony.es_cell_allele_symbol_superscript_template END AS es_cell_allele_symbol_superscript_template,

        CASE WHEN colony.es_cell_allele_mutation_type IS NOT NULL THEN colony.es_cell_allele_mutation_type ELSE mam_colony.es_cell_allele_mutation_type END AS es_cell_allele_mutation_type,
        CASE WHEN colony.es_cell_allele_mutation_method_allele_prefix IS NOT NULL THEN colony.es_cell_allele_mutation_method_allele_prefix ELSE mam_colony.es_cell_allele_mutation_method_allele_prefix END AS es_cell_allele_mutation_method_allele_prefix
      FROM phenotyping_productions
        JOIN plans pp_plans ON pp_plans.id = phenotyping_productions.mi_plan_id
        JOIN genes ON genes.id = pp_plans.gene_id
        JOIN colony_summary colony ON colony.id = phenotyping_productions.parent_colony_id
        LEFT JOIN strains pp_cb_strains ON pp_cb_strains.id = phenotyping_productions.colony_background_strain_id
        LEFT JOIN (mouse_allele_mods JOIN colony_summary mam_colony ON mam_colony.id = mouse_allele_mods.parent_colony_id) ON mouse_allele_mods.id = colony.mouse_allele_mod_id
      WHERE colony.genotype_confirmed = true AND phenotyping_productions.is_active = true
      ORDER BY phenotyping_colony_name
      EOF
    end
  end

end