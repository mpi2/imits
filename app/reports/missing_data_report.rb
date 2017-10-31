class MissingDataReport

  FIELDS = {'crispr_mi' => ['mi_date','external_ref','crsp_total_embryos_injected','crsp_total_embryos_survived','crsp_total_transfered','crsp_no_founder_pups',
                            'crsp_num_founders_selected_for_breading','founder_num_assays','assay_type','experimental','mrna_nuclease',
                            'mrna_nuclease_concentration','protein_nuclease','protein_nuclease_concentration','delivery_method','voltage','number_of_pulses', 
                            'crsp_embryo_transfer_day','crsp_embryo_2_cell', 'report_to_public','is_active','comments'],

            'additional_crispr_mi_fields' => ['mgi_accession_id', 'marker_symbol', 'consortium_name', 'production_centre_name', 'status_name', 'blast_strain_name',
                                              'IMPC_mutant_strain'],

            'colonies' =>  ['name', 'genotype_confirmed', 'is_released_from_genotyping', 'report_to_public', 'genotyping_comment'],

            'additional_colonies_fields' => ['background_strain_name']
  }

# [spreadsheet, title ,field_value, field_type, conditional_formatting]
  REPORT_FIELDS = [['MI Attempt', 'Consortium',                                 'consortium_name',                          'text',  nil],
                   ['MI Attempt', 'Production Centre',                          'production_centre_name',                   'text',  nil],
                   ['MI Attempt', 'Status Name',                                'status_name',                              'text',  nil],
                   ['MI Attempt', 'Mi Attempt External Ref',                    'external_ref',                             'text',  nil],
                   ['MI Attempt', 'Report Micro Injection Progress To Public',  'report_to_public',                         'text',  nil],
                   ['MI Attempt', 'IS Active',                                  'is_active',                                'text',  nil],
                   ['MI Attempt', 'Experimental (exclude from production reports)', 'experimental',                         'text',  nil],
                   ['MI Attempt', 'Gene MGI Accession ID',                      'mgi_accession_id',                         'text',  nil],
                   ['MI Attempt', 'Gene Marker Symbol',                         'marker_symbol',                            'text',  nil],
                   ['MI Attempt', 'Zygote',                                     'blast_strain_name',                        'text',  nil],
                   ['MI Attempt', 'IMPC Mutant Strain Donor',                   'IMPC_mutant_strain',                       'text',  nil],
                   ['MI Attempt', 'mRNA Nuclease',                              'mrna_nuclease',                            'text',  nil],
                   ['MI Attempt', 'mRNA Concentration',                         'mrna_nuclease_concentration',              'text',  nil],
                   ['MI Attempt', 'Protein Nuclease',                           'protein_nuclease',                         'text',  nil],
                   ['MI Attempt', 'Protein Concentration',                      'protein_nuclease_concentration',           'text',  nil],
                   ['MI Attempt', 'Delivery Method',                            'delivery_method',                          'text',  nil],
                   ['MI Attempt', 'Voltage',                                    'voltage',                                  'text',  nil],
                   ['MI Attempt', '#Pulses',                                    'number_of_pulses',                         'text',  nil],
                   ['MI Attempt', 'Comments',                                   'comments',                                 'text',  nil],
                   ['MI Attempt', 'Mi Date',                                    'mi_date',                                  'text',  nil],
                   ['MI Attempt', '#Embryos Injected',                          'crsp_total_embryos_injected',              'text',  nil],
                   ['MI Attempt', '#Embryos Survived',                          'crsp_total_embryos_survived',              'text',  nil],
                   ['MI Attempt', 'Embryo Transfer Day',                        'crsp_embryo_transfer_day',                 'text',  nil],
                   ['MI Attempt', '#Embryos Survived to 2 cell stage',          'crsp_embryo_2_cell',                       'text',  nil],
                   ['MI Attempt', '#Embryos Transfered',                        'crsp_total_transfered',                    'text',  nil],
                   ['MI Attempt', '#Founder Pups Born',                         'crsp_no_founder_pups',                     'text',  nil],
                   ['MI Attempt', '#Founders Selected For Breeding',            'crsp_num_founders_selected_for_breading',  'text',  nil],
                   ['MI Attempt', '#Founders Assayed',                          'founder_num_assays',                       'text',  nil],
                   ['MI Attempt', 'Assay Carried Out',                          'assay_type',                               'text',  nil],
                  ]

  MUTAGENESIS_FACTOR_FIELDS = {'f1' => 'external_ref', 'f2' => 'individually_set_grna_concentrations', 'f3' => 'guides_generated_in_plasmid', 'f4' => 'grna_concentration',
  'f5' => 'no_g0_where_mutation_detected', 'f6' => 'no_nhej_g0_mutants', 'f7' => 'no_deletion_g0_mutants', 'f8' => 'no_hr_g0_mutants', 'f9' => 'no_hdr_g0_mutants',
  'f10' => 'no_hdr_g0_mutants_all_donors_inserted', 'f11' => 'no_hdr_g0_mutants_subset_donors_inserted'
  }

  CRISPR_FIELDS = {'f1' => 'sequence', 'f2' => 'chr', 'f3' => 'start', 'f4' => 'end', 'f5' => 'truncated_guide', 'f6' => 'grna_concentration'}

  CUMULATIVE_CRISPR_FIELDS = {'f12' => 'crisprs'}

  CRISPR_AND_MUTAGENESIS_FACTOR_FIELDS = MUTAGENESIS_FACTOR_FIELDS.merge(CUMULATIVE_CRISPR_FIELDS)

  ALLELE_FIELDS = { 'f1' => 'mgi_allele_symbol_without_impc_abbreviation', 'f2' => 'mgi_allele_symbol_superscript', 'f3' => 'mgi_allele_accession_id', 
                    'f4' => 'allele_type', 'f5' => 'allele_subtype', 'f6' => 'mutant_fa', 'f7' => 'allele_description'}



  attr_accessor :mi_attempts
  attr_accessor :f1_colonies

  def initialize(options = {})
    raise 'ERROR: the keys numbering in CUMULATIVE_CRISPR_FIELDS must continue on from MUTAGENESIS_FACTOR_FIELDS' unless (CUMULATIVE_CRISPR_FIELDS.keys && MUTAGENESIS_FACTOR_FIELDS.keys).blank?
    options.has_key?('category') && ['all', 'es cell', 'crispr'].include?(options['category']) ? @category = options['category'] : @category = 'cripsr'
  end

  def mi_attempts
    @mi_attempts ||= ActiveRecord::Base.connection.execute(self.class.mi_attempt_sql)
  end

  def f1_colonies
    @f1_colonies ||= ActiveRecord::Base.connection.execute(self.class.f1_colony_sql)
  end

  def self.mi_attempt_sql
    <<-EOF
      WITH mfs AS (
        SELECT mi_attempts.id AS mi_attempt_id, #{MUTAGENESIS_FACTOR_FIELDS.map{|k, field| "mf.#{field}" }.join(', ')},
        json_agg( ROW( #{CRISPR_FIELDS.map{|k, field| "c.#{field}" }.join(', ')} ) ) AS crisprs
        FROM mutagenesis_factors mf
          JOIN mi_attempts ON  mi_attempts.mutagenesis_factor_id = mf.id
          JOIN targ_rep_crisprs  c  ON c.mutagenesis_factor_id = mf.id
        GROUP BY mi_attempts.id, #{MUTAGENESIS_FACTOR_FIELDS.map{|k, field| "mf.#{field}" }.join(', ')}
        )


      SELECT genes.mgi_accession_id, genes.marker_symbol, consortia.name AS consortium_name, centres.name AS production_centre_name,
             mis.name AS status_name, strains.name AS blast_strain_name, parent_colony AS IMPC_mutant_strain,
             #{FIELDS['crispr_mi'].map{|f| "mi_attempts.#{f} AS #{f}"}.join(', ')},
             json_agg( ROW( #{CRISPR_AND_MUTAGENESIS_FACTOR_FIELDS.map{|k, field| "mfs.#{field}" }.join(', ')} ) ) AS mutagenesis_factors
      FROM mi_attempts
        JOIN mi_attempt_statuses mis ON mis.id = mi_attempts.status_id
        LEFT JOIN strains ON strains.id = mi_attempts.blast_strain_id
        LEFT JOIN colonies parent_colony ON parent_colony.id = mi_attempts.parent_colony_id
        JOIN mfs ON mfs.mi_attempt_id = mi_attempts.id
        JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
        JOIN genes ON genes.id = mi_plans.gene_id
        JOIN consortia ON consortia.id = mi_plans.consortium_id
        JOIN centres ON centres.id = mi_plans.production_centre_id
      WHERE mi_attempts.mutagenesis_factor_id IS NOT NULL
      GROUP BY genes.mgi_accession_id, genes.marker_symbol, consortia.name, centres.name, mis.name, strains.name, parent_colony,
               #{FIELDS['crispr_mi'].map{|f| "mi_attempts.#{f}"}.join(', ')}
    EOF
  end

  def self.f1_colony_sql
    <<-EOF
      SELECT #{FIELDS['colonies'].map{|f| "colonies.#{f} AS #{f}"}.join(', ')}, strains.name AS background_strain_name, tc.trace_file_file_name AS trace_file_name,
      json_agg( ROW( #{ALLELE_FIELDS.map{|k, field| "alleles.#{field}" }.join(', ')} ) ) AS colonies_alleles
      FROM colonies
        JOIN alleles ON alleles.colony_id = colonies.id
        LEFT JOIN strains ON strains.id = colonies.background_strain_id
        LEFT JOIN trace_calls tc ON tc.colony_id = colonies.id
      WHERE colonies.mi_attempt_id IS NOT NULL
      GROUP BY colonies.id, #{FIELDS['colonies'].map{|f| "colonies.#{f}"}.join(', ')}, strains.name, tc.trace_file_file_name
    EOF
  end

end
