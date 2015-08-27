class MiAttemptListReport

  def initialize(options={})
    @consortia = options['consortia']
    @production_centres = options['production_centres']

    if @crispr.blank?
      @crispr = nil
    else
      @crispr = [true, 'true'].include?(options['crispr']) ? true : false
    end

    @group = options['group']
  end


  def columns
    {   'Consortium'                                                  => {:data => 'consortium_name', :show => true},
        'Production Centre'                                           => {:data => 'production_centre_name', :show => true},
        'MGI Accession ID'                                            => {:data => 'mgi_accession_id', :show => true},
        'Marker Symbol'                                               => {:data => 'marker_symbol', :show => true},

        'ES Cell Pipeline'                                            => {:data => 'pipeline_name', :show => @crispr != true},
        'Clone Name'                                                  => {:data => 'es_cell_name', :show => @crispr != true},
        'ES Cell Parental Cell Line'                                  => {:data => 'es_cell_parental_cell_line', :show => @crispr != true},
        'Clone Allele Type'                                           => {:data => 'es_cell_allele_type', :show => @crispr != true},

        'MI External Ref'                                             => {:data => 'external_ref', :show => true},
        'Injection Date'                                              => {:data => 'mi_date', :show => true},
        'Status'                                                      => {:data => 'status_name', :show => true},

        'Blastocyst Strain'                                           => {:data => 'blast_strain_name', :show => true},
        'Test Cross Strain'                                           => {:data => 'test_strain_name', :show => true},

        'Colony Name'                                                 => {:data => 'colony_names', :show => true},
        'Background Strain'                                           => {:data => 'colony_background_strain_name', :show => true},

        '# Blastocysts Transferred'                                   => {:data => 'total_transferred', :show => @crispr != true},
        '# Pups Born'                                                 => {:data => 'total_pups_born', :show => @crispr != true},
        '# Total Chimeras'                                            => {:data => 'total_chimeras', :show => @crispr != true},
        '# Male Chimeras'                                             => {:data => 'total_male_chimeras', :show => @crispr != true},
        '# Female Chimeras'                                           => {:data => 'total_female_chimeras', :show => @crispr != true},
        '# Male Chimeras/Coat Colour < 40%'                           => {:data => 'number_of_males_with_0_to_39_percent_chimerism', :show => @crispr != true},
        '# Male Chimeras/Coat Colour 40-79%'                          => {:data => 'number_of_males_with_40_to_79_percent_chimerism', :show => @crispr != true},
        '# Male Chimeras/Coat Colour 80-99%'                          => {:data => 'number_of_males_with_80_to_99_percent_chimerism', :show => @crispr != true},
        '# Male Chimeras/Coat Colour 100%'                            => {:data => 'number_of_males_with_100_percent_chimerism', :show => @crispr != true},

        '# Chimeras Set-Up'                                           => {:data => 'number_of_chimera_matings_attempted', :show => @crispr != true},
        '# Chimeras < 10% GLT'                                        => {:data => 'number_of_chimeras_with_0_to_9_percent_glt', :show => @crispr != true},
        '# Chimeras 10-49% GLT'                                       => {:data => 'number_of_chimeras_with_10_to_49_percent_glt', :show => @crispr != true},
        '# Chimeras 50-99% GLT'                                       => {:data => 'number_of_chimeras_with_50_to_99_percent_glt', :show => @crispr != true},
        '# Chimeras 100% GLT'                                         => {:data => 'number_of_chimeras_with_100_percent_glt', :show => @crispr != true},
        '# Coat Colour Offspring'                                     => {:data => 'number_of_cct_offspring', :show => @crispr != true},
        '# Chimeras with Genotype-Confirmed Transmission'             => {:data => 'number_of_chimeras_with_glt_from_genotyping', :show => @crispr != true},
        '# Heterozygous Offspring'                                    => {:data => 'number_of_het_offspring', :show => @crispr != true},
        ''                                                            => {:data => 'number_of_chimeras_with_glt_from_cct', :show => @crispr != true},

        'Mutagenesis Factor Ref'                                      => {:data => 'mutagenesis_factor_ids', :show => @crispr == true},
        'Nuclease'                                                    => {:data => 'nucleases', :show => @crispr == true},
        'Vector Name'                                                 => {:data => 'vector_names', :show => @crispr == true},
        'Crisprs'                                                     => {:data => 'crispr_groups', :show => @crispr == true},

        'Total Embryos Injected'                                      => {:data => 'crsp_total_embryos_injected', :show => @crispr == true},
        'Total Embryos Survived'                                      => {:data => 'crsp_total_embryos_survived', :show => @crispr == true},
        'Total Transfered'                                            => {:data => 'crsp_total_transfered', :show => @crispr == true},
        '# Founder Pups'                                              => {:data => 'crsp_no_founder_pups', :show => @crispr == true},
        '# Founders Selected For Breading'                            => {:data => 'crsp_num_founders_selected_for_breading', :show => @crispr == true},
        '# Founders Selected For Breading'                                                 => {:data => 'Founder Assay Type''assay_type', :show => @crispr == true},
        '# Founders Assayed'                                          => {:data => 'founder_num_assays', :show => @crispr == true},
        '# Founder with Positive Assay'                               => {:data => 'founder_num_positive_results', :show => @crispr == true},
        'Total # Mutant Founders'                                     => {:data => 'crsp_total_num_mutant_founders', :show => @crispr == true},

 #       'is_suitable_for_emma'                                        => 'Suitable for EMMA?',
        'Experimental?'                                               => {:data => 'experimental', :show => true},
        'Active?'                                                     => {:data => 'is_active', :show => true},
        'Comments'                                                    => {:data => 'comments', :show => true}
    }
  end


     #   es_cells.allele_symbol,
     #   mi_attempts.is_suitable_for_emma,

  def mi_attempt_list
    @mi_attempt_list ||= ActiveRecord::Base.connection.execute(self.class.mi_attempt_list_sql(@consortia, @production_centres, @crispr, @group))
  end

  def self.mi_attempt_list_sql(consortia = [], production_centres = [], crisprs = nil, group_by = nil)

    if ['consortium', 'production_centre'].include?(group_by)
      group_by = {'consortium' => 'consortia.name', 'production_centre' => 'centres.name'}[group_by]
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

    unless crisprs.blank? && ['true', 'false'].include?(crisprs)
      where_condition << "mi_plans.mutagenesis_via_crispr_cas9 = #{crisprs}"
    end

    sql = <<-EOF
      WITH mutagenesis_factor_summary AS (
        SELECT grouped_crisprs.mi_attempt_id, array_agg(grouped_crisprs.mutagenesis_factor_id) AS mutagenesis_factor_ids, array_agg(grouped_crisprs.nucleases) AS nucleases, array_agg(grouped_crisprs.vector_name) AS vector_names, array_agg(array_to_string(grouped_crisprs.crisprs, ',')) AS crispr_groups
        FROM
          (SELECT mutagenesis_factors.id AS mutagenesis_factor_id, targ_rep_targeting_vectors.name AS vector_name, mutagenesis_factors.nuclease AS nucleases, mi_attempts.id AS mi_attempt_id, array_agg(targ_rep_crisprs.sequence) AS crisprs
          FROM mutagenesis_factors
            JOIN mi_attempts ON mi_attempts.mutagenesis_factor_id = mutagenesis_factors.id
            JOIN targ_rep_crisprs ON targ_rep_crisprs.mutagenesis_factor_id = mutagenesis_factors.id
            LEFT JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.id = mutagenesis_factors.vector_id
          GROUP BY mutagenesis_factors.id, targ_rep_targeting_vectors.name, mi_attempts.id
          ) AS grouped_crisprs
        GROUP BY grouped_crisprs.mi_attempt_id
      ),

      grouped_colonies AS (
        SELECT colonies.mi_attempt_id, array_agg(colonies.name) AS colony_names, array_agg(background_strain.name) AS background_strains, array_agg(allele_name) AS allele_names, array_agg(allele_type) AS allele_types
        FROM colonies
          LEFT JOIN strains background_strain ON background_strain.id = colonies.background_strain_id
        WHERE mi_attempt_id IS NOT NULL
        GROUP BY colonies.mi_attempt_id
      )

      SELECT

            consortia.name AS consortium_name,
            centres.name AS production_centre_name,
            genes.mgi_accession_id AS mgi_accession_id,
            genes.marker_symbol AS marker_symbol,

            es_cells.name AS es_cell_name,
            es_cells.parental_cell_line AS es_cell_parental_cell_line,
            pipelines.name AS pipeline_name,

            mi_attempts.external_ref AS external_ref,
            mi_attempts.mi_date AS mi_date,
            mi_attempt_statuses.name AS status_name,

            mi_attempts.total_transferred                               AS total_transferred,
            mi_attempts.total_pups_born                                 AS total_pups_born,
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
            mi_attempts.is_active                                       AS is_active,
            mi_attempts.comments                                        As comments,

            mutagenesis_factor_summary.mutagenesis_factor_ids           AS mutagenesis_factor_ids,
            mutagenesis_factor_summary.nucleases                        AS nucleases,
            mutagenesis_factor_summary.vector_names                     AS vector_names,
            mutagenesis_factor_summary.crispr_groups                    AS crispr_groups,

            mi_attempts.crsp_total_embryos_injected                     AS crsp_total_embryos_injected,
            mi_attempts.crsp_total_embryos_survived                     AS crsp_total_embryos_survived,
            mi_attempts.crsp_total_transfered                           AS crsp_total_transfered,
            mi_attempts.crsp_no_founder_pups                            AS crsp_no_founder_pups,
            mi_attempts.crsp_total_num_mutant_founders                  AS crsp_total_num_mutant_founders,
            mi_attempts.crsp_num_founders_selected_for_breading         AS crsp_num_founders_selected_for_breading,
            mi_attempts.founder_num_assays                              AS founder_num_assays,
            mi_attempts.founder_num_positive_results                    AS founder_num_positive_results,
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
