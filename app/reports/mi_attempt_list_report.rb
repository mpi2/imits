class MiAttemptListReport

  def initialize(options={})


    @consortia = options['consortia']
    @production_centres = options['production_centres']
    @group = options['group']
  end

  def columns
    {   'MI External Ref'                                             => {:data => 'external_ref', :show => true},
        'Consortium'                                                  => {:data => 'consortium_name', :show => true},
        'Production Centre'                                           => {:data => 'production_centre_name', :show => true},
        'MGI Accession ID'                                            => {:data => 'mgi_accession_id', :show => true},
        'Marker Symbol'                                               => {:data => 'marker_symbol', :show => true},

        'Pipeline'                                                    => {:data => 'pipeline_name', :show => true},
        'Delivery Method'                                             => {:data => 'delivery_method', :show => true},
        'Injection Date'                                              => {:data => 'mi_date', :show => true},
        'Injection Status'                                            => {:data => 'status_name', :show => true},

        'Clone Name / MF External Ref'                                => {:data => 'es_cell_name', :show => true},
        'Clone Parental Cell Line'                                    => {:data => 'es_cell_parental_cell_line', :show => true},
        'Clone Allele Type'                                           => {:data => 'es_cell_allele_type', :show => true},

        'mRNA Nuclease'                                               => {:data => 'mrna_nuclease', :show => true},
        'mRNA Nuclease Concentration'                                 => {:data => 'mrna_nuclease_concentration', :show => true},
        'Protein Nuclease'                                            => {:data => 'protein_nuclease', :show => true},
        'Protein Nuclease Concentration'                              => {:data => 'protein_nuclease_concentration', :show => true},
        'Vector Names / Oligo Sequences'                              => {:data => 'vector_names', :show => true},
        'Crisprs'                                                     => {:data => 'crispr_groups', :show => true},

        'Electoporation Voltage'                                      => {:data => 'electroporation_voltage', :show => true},
        'Electroporation # Pulses'                                    => {:data => 'electroporation_number_of_pulses', :show => true},
        'Electroporation Pulse Length'                                => {:data => 'electroporation_pulse_length', :show => true},

        'Embryo / Blastocyst Strain'                                  => {:data => 'blast_strain_name', :show => true},
        '# Embryos / Blastocysts Injected'                            => {:data => 'total_injected', :show => true},
        '# Embryos Survived'                                          => {:data => 'crsp_total_embryos_survived', :show => true},
        '# Embryos / Blastocysts Transferred'                         => {:data => 'total_transferred', :show => true},

        'Transfer Day'                                                => {:data => 'embryo_transfer_day', :show => true},
        '2 Cell'                                                      => {:data => 'embryo_2_cell', :show => true},

        '# Pups Born'                                                 => {:data => 'total_pups_born', :show => true},
        '# Founders Selected For Breading'                            => {:data => 'crsp_num_founders_selected_for_breading', :show => true},
        '# Founders Assayed'                                          => {:data => 'founder_num_assays', :show => true},
        'Assay Used'                                                  => {:data => 'assay_type', :show => true},

        'Colony Name'                                                 => {:data => 'colony_names', :show => true},
        'Background Strain'                                           => {:data => 'colony_background_strain_name', :show => true},

        'Test Cross Strain'                                           => {:data => 'test_strain_name', :show => true},
        '# Total Chimeras'                                            => {:data => 'total_chimeras', :show => true},
        '# Male Chimeras'                                             => {:data => 'total_male_chimeras', :show => true},
        '# Female Chimeras'                                           => {:data => 'total_female_chimeras', :show => true},
        '# Male Chimeras/Coat Colour < 40%'                           => {:data => 'number_of_males_with_0_to_39_percent_chimerism', :show => true},
        '# Male Chimeras/Coat Colour 40-79%'                          => {:data => 'number_of_males_with_40_to_79_percent_chimerism', :show => true},
        '# Male Chimeras/Coat Colour 80-99%'                          => {:data => 'number_of_males_with_80_to_99_percent_chimerism', :show => true},
        '# Male Chimeras/Coat Colour 100%'                            => {:data => 'number_of_males_with_100_percent_chimerism', :show => true},

        '# Chimeras Set-Up'                                           => {:data => 'number_of_chimera_matings_attempted', :show => true},
        '# Chimeras < 10% GLT'                                        => {:data => 'number_of_chimeras_with_0_to_9_percent_glt', :show => true},
        '# Chimeras 10-49% GLT'                                       => {:data => 'number_of_chimeras_with_10_to_49_percent_glt', :show => true},
        '# Chimeras 50-99% GLT'                                       => {:data => 'number_of_chimeras_with_50_to_99_percent_glt', :show => true},
        '# Chimeras 100% GLT'                                         => {:data => 'number_of_chimeras_with_100_percent_glt', :show => true},
        '# Coat Colour Offspring'                                     => {:data => 'number_of_cct_offspring', :show => true},
        '# Chimeras with Genotype-Confirmed Transmission'             => {:data => 'number_of_chimeras_with_glt_from_genotyping', :show => true},
        '# Heterozygous Offspring'                                    => {:data => 'number_of_het_offspring', :show => true},
        '# Chimeras GLT from CCT'                                     => {:data => 'number_of_chimeras_with_glt_from_cct', :show => true},

        'Experimental?'                                               => {:data => 'experimental', :show => true},
        'Report Micro Injection Progress To Public'                   => {:data => 'report_to_public', :show => true},
        'Active?'                                                     => {:data => 'is_active', :show => true},
        'Comments'                                                    => {:data => 'comments', :show => true}
    }
  end

  def mi_attempt_list
    @mi_attempt_list ||= ActiveRecord::Base.connection.execute(self.class.mi_attempt_list_sql(@consortia, @production_centres, @group))
  end

  def self.mi_attempt_list_sql(consortia = [], production_centres = [], group_by = nil)

    if ['Consortium', 'Production Centre'].include?(group_by)
      group_by = {'Consortium' => 'consortia.name', 'Production Centre' => 'centres.name'}[group_by]
    else
      group_by = 'genes.marker_symbol'
    end

    where_condition = []
    unless consortia.blank?
      where_condition << "consortia.name IN ('#{consortia.join("','")}')"
    end

    unless production_centres.blank?
      where_condition << "centres.name IN ('#{production_centres.join("','")}')"
    end

    sql = <<-EOF
      WITH mutagenesis_factors_vectors_summary AS (
        SELECT mi_attempts.id AS mi_attempt_id, 
        string_agg( '', ' | ')  AS vector_names
        FROM mutagenesis_factor_donors
          JOIN mutagenesis_factors ON mutagenesis_factors.id = mutagenesis_factor_donors.mutagenesis_factor_id
          JOIN mi_attempts ON mi_attempts.mutagenesis_factor_id = mutagenesis_factors.id
          LEFT JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.id = mutagenesis_factor_donors.vector_id
        GROUP BY mi_attempts.id
        ),

        crispr_summary AS (
        SELECT mi_attempts.id AS mi_attempt_id, string_agg(targ_rep_crisprs.sequence, '| ') AS crispr_sequences
        FROM targ_rep_crisprs
          JOIN mutagenesis_factors ON mutagenesis_factors.id = targ_rep_crisprs.mutagenesis_factor_id
          JOIN mi_attempts ON mi_attempts.mutagenesis_factor_id = mutagenesis_factors.id
        GROUP BY mi_attempts.id
        ),

        mutagenesis_factor_summary AS (
        SELECT mi_attempts.id AS mi_attempt_id, mutagenesis_factors.id AS mutagenesis_factor_ids, mutagenesis_factors.external_ref AS external_ref, mutagenesis_factors_vectors_summary.vector_names AS vector_names,
               crispr_summary.crispr_sequences AS crispr_groups
        FROM mi_attempts
          JOIN mutagenesis_factors ON mutagenesis_factors.id = mi_attempts.mutagenesis_factor_id
          JOIN crispr_summary ON crispr_summary.mi_attempt_id = mi_attempts.id
          LEFT JOIN mutagenesis_factors_vectors_summary ON mutagenesis_factors_vectors_summary.mi_attempt_id = mi_attempts.id
      ),

      grouped_colonies AS (
        SELECT colonies.mi_attempt_id, string_agg(colonies.name, ' | ') AS colony_names, string_agg(background_strain.name, ' | ') AS background_strains, 
        string_agg(alleles.mgi_allele_symbol_superscript, ' | ') AS allele_names, string_agg(alleles.allele_type, ' | ') AS allele_types
        FROM colonies
          LEFT JOIN alleles ON alleles.colony_id = colonies.id
          LEFT JOIN strains background_strain ON background_strain.id = colonies.background_strain_id
        WHERE mi_attempt_id IS NOT NULL
        GROUP BY colonies.mi_attempt_id
      )

      SELECT

            consortia.name AS consortium_name,
            centres.name AS production_centre_name,
            genes.mgi_accession_id AS mgi_accession_id,
            genes.marker_symbol AS marker_symbol,

            CASE WHEN es_cells.name IS NOT NULL THEN es_cells.name ELSE mutagenesis_factor_summary.external_ref END AS es_cell_name,
            CASE WHEN es_cells.name IS NOT NULL THEN es_cells.parental_cell_line ELSE parent_colony.name END AS es_cell_parental_cell_line,
            CASE WHEN es_cells.name IS NOT NULL THEN pipelines.name ELSE 'IMPC' END AS pipeline_name,

            mi_attempts.external_ref AS external_ref,
            mi_attempts.mi_date AS mi_date,
            mi_attempt_statuses.name AS status_name,
            CASE WHEN es_cells.name IS NULL THEN mi_attempts.delivery_method ELSE 'Micro Injection' END AS delivery_method,

            CASE WHEN es_cells.name IS NOT NULL THEN mi_attempts.total_blasts_injected ELSE mi_attempts.crsp_total_embryos_injected END AS total_injected,
            mi_attempts.crsp_total_embryos_survived                     AS crsp_total_embryos_survived,
            CASE WHEN es_cells.name IS NOT NULL THEN mi_attempts.total_transferred ELSE mi_attempts.crsp_total_transfered END AS total_transferred,
            CASE WHEN es_cells.name IS NOT NULL THEN mi_attempts.total_pups_born ELSE crsp_no_founder_pups END AS total_pups_born,
            mi_attempts.total_chimeras                                  AS total_chimeras,
            mi_attempts.total_male_chimeras                             AS total_male_chimeras,
            mi_attempts.total_female_chimeras                           AS total_female_chimeras,
            mi_attempts.number_of_males_with_0_to_39_percent_chimerism  AS number_of_males_with_0_to_39_percent_chimerism,
            mi_attempts.number_of_males_with_40_to_79_percent_chimerism AS number_of_males_with_40_to_79_percent_chimerism,
            mi_attempts.number_of_males_with_80_to_99_percent_chimerism AS number_of_males_with_80_to_99_percent_chimerism,
            mi_attempts.number_of_males_with_100_percent_chimerism      AS number_of_males_with_100_percent_chimerism,
            mi_attempts.number_of_chimera_matings_attempted             AS number_of_chimera_matings_attempted,
            mi_attempts.number_of_chimeras_with_0_to_9_percent_glt      AS number_of_chimeras_with_0_to_9_percent_glt,
            mi_attempts.number_of_chimeras_with_10_to_49_percent_glt    AS number_of_chimeras_with_10_to_49_percent_glt,
            mi_attempts.number_of_chimeras_with_50_to_99_percent_glt    AS number_of_chimeras_with_50_to_99_percent_glt,
            mi_attempts.number_of_chimeras_with_100_percent_glt         AS number_of_chimeras_with_100_percent_glt,
            mi_attempts.number_of_cct_offspring                         AS number_of_cct_offspring,
            mi_attempts.number_of_chimeras_with_glt_from_genotyping     AS number_of_chimeras_with_glt_from_genotyping,
            mi_attempts.number_of_het_offspring                         AS number_of_het_offspring,
            mi_attempts.number_of_chimeras_with_glt_from_cct            AS number_of_chimeras_with_glt_from_cct,

            mi_attempts.experimental                                    AS experimental,
            mi_attempts.report_to_public                                AS report_to_public,
            mi_attempts.is_active                                       AS is_active,
            mi_attempts.comments                                        As comments,

            mutagenesis_factor_summary.mutagenesis_factor_ids           AS mutagenesis_factor_ids,
            mi_attempts.mrna_nuclease                                   AS mrna_nuclease,
            mi_attempts.protein_nuclease                                AS protein_nuclease,
            mi_attempts.mrna_nuclease_concentration                     AS mrna_nuclease_concentration,
            mi_attempts.protein_nuclease_concentration                  AS protein_nuclease_concentration,
            
            mi_attempts.voltage                                         AS electroporation_voltage, 
            mi_attempts.number_of_pulses                                AS electroporation_number_of_pulses,
            NULL AS electroporation_pulse_length,
            mi_attempts.crsp_embryo_transfer_day                        AS embryo_transfer_day,
            mi_attempts.crsp_embryo_2_cell                              AS embryo_2_cell,
            mutagenesis_factor_summary.vector_names                     AS vector_names,
            mutagenesis_factor_summary.crispr_groups                    AS crispr_groups,

            mi_attempts.crsp_no_founder_pups                            AS crsp_no_founder_pups,
            mi_attempts.crsp_num_founders_selected_for_breading         AS crsp_num_founders_selected_for_breading,
            mi_attempts.founder_num_assays                              AS founder_num_assays,
            mi_attempts.assay_type                                      AS assay_type,

            blast_strain.name                                           AS blast_strain_name,
            test_strain.name                                            AS test_strain_name,

            grouped_colonies.background_strains                         AS colony_background_strain_names,
            grouped_colonies.colony_names                               AS colony_names,
            grouped_colonies.allele_names                               AS allele_names,
            grouped_colonies.allele_types                               AS allele_types


      FROM mi_attempts
        JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
        JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
        JOIN genes ON genes.id = mi_plans.gene_id
        JOIN consortia ON consortia.id = mi_plans.consortium_id
        JOIN centres ON centres.id = mi_plans.production_centre_id
        LEFT JOIN colonies parent_colony ON parent_colony.id = mi_attempts.parent_colony_id
        LEFT JOIN strains blast_strain ON blast_strain.id = mi_attempts.blast_strain_id
        LEFT JOIN strains test_strain ON test_strain.id = mi_attempts.test_cross_strain_id
        LEFT JOIN (targ_rep_es_cells es_cells LEFT JOIN targ_rep_pipelines pipelines ON pipelines.id = es_cells.pipeline_id) ON es_cells.id = mi_attempts.es_cell_id
        LEFT JOIN mutagenesis_factor_summary ON mutagenesis_factor_summary.mi_attempt_id = mi_attempts.id
        LEFT JOIN grouped_colonies ON grouped_colonies.mi_attempt_id = mi_attempts.id
      #{!where_condition.blank? ? "WHERE " + where_condition.join(' AND ') : ""}
      ORDER BY #{group_by}, consortia.name, centres.name, genes.marker_symbol

    EOF
  end

end
