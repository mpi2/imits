class MissingDataReport

  # Nested field configurations (i.e. number of copies)
  NO_NESTED_MUTAGENESIS_FACTOR = 1
  NO_NESTED_CRISPR = 4
  NO_NESTED_FOUNDER_QC = 1
  NO_NESTED_ALLELES = 1

  # Fields to return in SQL
  FIELDS = {'crispr_mi' => ['mi_date','external_ref','crsp_total_embryos_injected','crsp_total_embryos_survived','crsp_total_transfered','crsp_no_founder_pups',
                            'crsp_num_founders_selected_for_breading','founder_num_assays','assay_type','experimental','mrna_nuclease',
                            'mrna_nuclease_concentration','protein_nuclease','protein_nuclease_concentration','delivery_method','voltage','number_of_pulses', 
                            'crsp_embryo_transfer_day','crsp_embryo_2_cell', 'report_to_public','is_active','comments'],

            'additional_crispr_mi_fields' => ['mgi_accession_id', 'marker_symbol', 'consortium_name', 'production_centre_name', 'status_name', 'blast_strain_name',
                                              'IMPC_mutant_strain'],

            'colonies' =>  ['name', 'genotype_confirmed', 'is_released_from_genotyping', 'report_to_public', 'genotyping_comment'],

            'additional_colonies_fields' => ['background_strain_name']
  }

  # Translations for aggregated json fields returned from SQL  
  MUTAGENESIS_FACTOR_FIELDS = {'f1' => 'external_ref', 'f2' => 'individually_set_grna_concentrations', 'f3' => 'guides_generated_in_plasmid', 'f4' => 'grna_concentration',
  'f5' => 'no_g0_where_mutation_detected', 'f6' => 'no_nhej_g0_mutants', 'f7' => 'no_deletion_g0_mutants', 'f8' => 'no_hr_g0_mutants', 'f9' => 'no_hdr_g0_mutants',
  'f10' => 'no_hdr_g0_mutants_all_donors_inserted', 'f11' => 'no_hdr_g0_mutants_subset_donors_inserted'
  }

  CRISPR_FIELDS = {'f1' => 'sequence', 'f2' => 'chr', 'f3' => 'start', 'f4' => 'end', 'f5' => 'truncated_guide', 'f6' => 'grna_concentration'}

  CUMULATIVE_CRISPR_FIELDS = {'f12' => 'crisprs'}

  CRISPR_AND_MUTAGENESIS_FACTOR_FIELDS = MUTAGENESIS_FACTOR_FIELDS.merge(CUMULATIVE_CRISPR_FIELDS)

  ALLELE_FIELDS = { 'f1' => 'mgi_allele_symbol_without_impc_abbreviation', 'f2' => 'mgi_allele_symbol_superscript', 'f3' => 'mgi_allele_accession_id', 
                    'f4' => 'allele_type', 'f5' => 'allele_subtype', 'f6' => 'mutant_fa', 'f7' => 'allele_description'}


# Spreadsheet configration [spreadsheet, title ,field_value, nesting_attribute ,field_type, conditional_formatting]
  REPORT_FIELDS = [['MI Attempt', 'Mi Attempt URL',                             'mi_attempt_url',                           nil, 'string',  'format_blue'],
                   ['MI Attempt', 'Mi Attempt External Ref',                    'external_ref',                             nil, 'string',  nil],
                   ['MI Attempt', 'Gene Marker Symbol',                         'marker_symbol',                            nil, 'string',  nil],
                   ['MI Attempt', 'Gene MGI Accession ID',                      'mgi_accession_id',                         nil, 'string',  nil],
                   ['MI Attempt', 'Consortium',                                 'consortium_name',                          nil, 'string',  nil],
                   ['MI Attempt', 'Production Centre',                          'production_centre_name',                   nil, 'string',  nil],
                   ['MI Attempt', 'Status Name',                                'status_name',                              nil, 'string',  nil],
                   ['MI Attempt', 'Report Micro Injection Progress To Public',  'report_to_public',                         nil, 'string',  nil],
                   ['MI Attempt', 'IS Active',                                  'is_active',                                nil, 'string',  nil],
                   ['MI Attempt', 'Experimental (exclude from production reports)', 'experimental',                         nil, 'string',  nil],
                   ['MI Attempt', 'Zygote',                                     'blast_strain_name',                        nil, 'string',  nil],
                   ['MI Attempt', 'IMPC Mutant Strain Donor',                   'IMPC_mutant_strain',                       nil, 'string',  nil],
                   ['MI Attempt', 'Mutagenesis Factor',                         'Mutagenesis Factor',                       'mutagenesis_factors', "nested(#{NO_NESTED_MUTAGENESIS_FACTOR})",  nil],
                   ['MI Attempt', 'mRNA Nuclease',                              'mrna_nuclease',                            nil, 'string',  'format_blank_nucleases'],
                   ['MI Attempt', 'mRNA Concentration',                         'mrna_nuclease_concentration',              nil, 'string',  'format_blank_nucleases_concentrations'],
                   ['MI Attempt', 'Protein Nuclease',                           'protein_nuclease',                         nil, 'string',  'format_blank_nucleases'],
                   ['MI Attempt', 'Protein Concentration',                      'protein_nuclease_concentration',           nil, 'string',  'format_blank_nucleases_concentrations'],
                   ['MI Attempt', 'Delivery Method',                            'delivery_method',                          nil, 'string',  'format_blank_red'],
                   ['MI Attempt', 'Voltage',                                    'voltage',                                  nil, 'string',  'format_blank_n_electroporation'],
                   ['MI Attempt', '#Pulses',                                    'number_of_pulses',                         nil, 'string',  'format_blank_n_electroporation'],
                   ['MI Attempt', 'Comments',                                   'comments',                                 nil, 'string',  nil],
                   ['MI Attempt', 'Mi Date',                                    'mi_date',                                  nil, 'string',  nil],
                   ['MI Attempt', '#Embryos Injected',                          'crsp_total_embryos_injected',              nil, 'string',  'format_blank_red'],
                   ['MI Attempt', '#Embryos Survived',                          'crsp_total_embryos_survived',              nil, 'string',  'format_blank_n_embyo_injected'],
                   ['MI Attempt', 'Embryo Transfer Day',                        'crsp_embryo_transfer_day',                 nil, 'string',  'format_blank_red'],
                   ['MI Attempt', '#Embryos Survived to 2 cell stage',          'crsp_embryo_2_cell',                       nil, 'string',  'format_blank_n_next_day_transfer'],
                   ['MI Attempt', '#Embryos Transfered',                        'crsp_total_transfered',                    nil, 'string',  'format_blank_n_embyo_injected'],
                   ['MI Attempt', '#Founder Pups Born',                         'crsp_no_founder_pups',                     nil, 'string',  'format_founder_counts'],
                   ['MI Attempt', '#Founders Assayed',                          'founder_num_assays',                       nil, 'string',  'format_founder_counts'],
                   ['MI Attempt', 'Assay Carried Out',                          'assay_type',                               nil, 'string',  'format_assay_type'],
                   ['MI Attempt', '#Founders Selected For Breeding',            'crsp_num_founders_selected_for_breading',  nil, 'string',  'format_founder_counts'],
                   ['MI Attempt', 'G0 Screens',                                 'G0 Screen',                                'mutagenesis_factors', "nested(#{NO_NESTED_FOUNDER_QC})",  nil],
                   ['F1 Colony', 'Mi Attempt URL',                              'mi_attempt_url',                           nil, 'string',  'format_blue'],
                   ['F1 Colony', 'Mi Attempt External Ref',                     'external_ref',                             nil, 'string',  nil],  
                   ['F1 Colony', 'Gene Marker Symbol',                          'marker_symbol',                            nil, 'string',  nil],
                   ['F1 Colony', 'Gene MGI Accession ID',                       'mgi_accession_id',                         nil, 'string',  nil],
                   ['F1 Colony', 'Consortium',                                  'consortium_name',                          nil, 'string',  nil],
                   ['F1 Colony', 'Production Centre',                           'production_centre_name',                   nil, 'string',  nil],
                   ['F1 Colony', 'Status Name',                                 'status_name',                              nil, 'string',  nil],                 
                   ['F1 Colony', 'F1 Colony Name',                              'name',                                     nil, 'string',  nil],
                   ['F1 Colony', 'Genotype Confirmed',                          'genotype_confirmed',                       nil, 'string',  nil],
                   ['F1 Colony', 'Released from Genotyping (WTSI)',             'is_released_from_genotyping',              nil, 'string',  nil],
                   ['F1 Colony', 'Report F1 Colony To Public',                  'report_to_public',                         nil, 'string',  'format_orange_if_false_n_genoype_confirmed'],
                   ['F1 Colony', 'Genotyping Comment',                          'genotyping_comment',                       nil, 'string',  nil],
                   ['F1 Colony', 'Background Strain',                           'background_strain_name',                   nil, 'string',  'format_blank_red_if_genoype_confirmed'],
                   ['F1 Colony', 'Uploaded Trace file',                         'trace_file_name',                          nil, 'string',  nil],
                   ['F1 Colony', 'Alleles',                                     'Allele',                                   'colonies_alleles', "nested(#{NO_NESTED_ALLELES})",  nil]
                  ]


  NESTED_FIELDS = [['Mutagenesis Factor', 'MF External Ref',                    'external_ref',                              nil, 'string',  nil],
                  ['Mutagenesis Factor', 'Plasmid Generated Guides',            'guides_generated_in_plasmid',               nil, 'string',  nil],
                  ['Mutagenesis Factor', 'gRNA Concentrations',                 'grna_concentration',                        nil, 'string',  'format_blank_n_not_individually_set'],
                  ['Mutagenesis Factor', 'gRNA Concentrations Individually Set?', 'individually_set_grna_concentrations',    nil, 'string',  nil],
                  ['Mutagenesis Factor', 'gRNAs',                               'Crispr',                                    'crisprs', "nested(#{NO_NESTED_CRISPR})", nil],
                  ['G0 Screen', '#G0 with detected mutation',                   'no_g0_where_mutation_detected',             nil, 'string',  'format_founder_with_detected_mutation'],
                  ['G0 Screen', '#G0 NHEJ event detected',                      'no_nhej_g0_mutants',                        nil, 'string',  'format_founder_qc'],
                  ['G0 Screen', '#G0 deletion event detected',                  'no_deletion_g0_mutants',                    nil, 'string',  'format_founder_qc'],
                  ['G0 Screen', '#G0 HR event detected',                        'no_hr_g0_mutants',                          nil, 'string',  'format_founder_qc'],
                  ['G0 Screen', '#G0 HDR event detected',                       'no_hdr_g0_mutants',                         nil, 'string',  'format_founder_qc'],
                  ['G0 Screen', '#G0 all donor insertions detected',            'no_hdr_g0_mutants_all_donors_inserted',     nil, 'string',  'format_founder_hdr_qc'],
                  ['G0 Screen', '#G0 subset of donors inserted detected',       'no_hdr_g0_mutants_subset_donors_inserted',  nil, 'string',  'format_founder_hdr_qc'],
                  ['Crispr', 'gRNA Sequence (+ strand)',                        'sequence',                                  nil, 'string',  nil],
                  ['Crispr', 'Chromosome (+ strand)',                           'chr',                                       nil, 'string',  nil],
                  ['Crispr', 'Start Co-od',                                     'start',                                     nil, 'string',  nil],
                  ['Crispr', 'End Co-od',                                       'end',                                       nil, 'string',  nil],
                  ['Crispr', 'Truncated_guide',                                 'truncated_guide',                           nil, 'string',  nil],
                  ['Crispr', 'Individually set gRNA concentrations',            'grna_concentration',                        nil, 'string',  nil],
                  ['Allele', 'MGI Allele Symbol Superscript',                   'mgi_allele_symbol_superscript',             nil, 'string',  'format_blank_red_if_genoype_confirmed'],
                  ['Allele', 'MGI Allele Accession ID',                         'mgi_allele_accession_id',                   nil, 'string',  nil],
                  ['Allele', 'Allele Type',                                     'allele_type',                               nil, 'string',  'format_blank_red_if_genoype_confirmed'],
                  ['Allele', 'Allele Subtype',                                  'allele_subtype',                            nil, 'string',  'format_blank_red_if_genoype_confirmed'],
                  ['Allele', 'Mutant Fasta Sequence',                           'mutant_fa',                                 nil, 'string',  'format_blank_red_if_genoype_confirmed'],
                  ['Allele', 'Centres Allele Description',                      'allele_description',                        nil, 'string',  nil]
                ]


  attr_accessor :mi_attempts
  attr_accessor :f1_colonies

  def initialize(options = {})
    raise 'ERROR: the keys numbering in CUMULATIVE_CRISPR_FIELDS must continue on from MUTAGENESIS_FACTOR_FIELDS' unless (CUMULATIVE_CRISPR_FIELDS.keys & MUTAGENESIS_FACTOR_FIELDS.keys).blank?
    options.has_key?(:centre) ? @centre = options[:centre] : @centre = nil
  end

  def mi_attempts
    @mi_attempts ||= self.class.process_mi_data(ActiveRecord::Base.connection.execute(self.mi_attempt_sql))

    #@mi_attempts ||= ActiveRecord::Base.connection.execute(self.class.mi_attempt_sql)
  end

  def f1_colonies
    @f1_colonies ||= self.class.process_f1_colony_data(ActiveRecord::Base.connection.execute(self.f1_colony_sql))
  end

  def self.process_mi_data(mi_data)
    translated_data = []
    report_data = []

    mi_data.each do |row|
        translated_data << translate_data(row)
    end

    translated_data.each do |row|
      processed_data = []
      REPORT_FIELDS.select{|field| field[0] == 'MI Attempt'}.each do |field|
        processed_data += self.process_data(field, row, nil)
      end
      report_data << processed_data
    end
 
    return report_data
  end

  def self.process_f1_colony_data(f1_colony_data)
    translated_data = []
    report_data = []

    f1_colony_data.each do |row|
        translated_data << translate_data(row)
    end

    translated_data.each do |row|
      processed_data = []
      REPORT_FIELDS.select{|field| field[0] == 'F1 Colony'}.each do |field|
        processed_data += self.process_data(field, row, nil)
      end
      report_data << processed_data
    end
 
    return report_data
  end
  
  def self.translate_data(data_row)
    data_mapping = {'mutagenesis_factors' => CRISPR_AND_MUTAGENESIS_FACTOR_FIELDS,
                    'crisprs' => CRISPR_FIELDS,
                    'colonies_alleles' => ALLELE_FIELDS
                   }
    data = {}

    data_row.each do |key, value|
      if data_mapping.has_key?(key)
        new_data_format = []
        value = JSON.parse(value) if value.class != Array 
        value.each do |nested_data|
          new_nested_data = {}
          nested_data.each do |nested_key, nested_value|
            if nested_value.class == Array
              new_key, new_value = self.translate_data( {data_mapping[key][nested_key] => nested_value} ).first

              new_nested_data[new_key] = new_value
            else
              new_nested_data[ data_mapping[key][nested_key] ] = nested_value
            end
          end
          new_data_format << new_nested_data
        end
        data[key] = new_data_format
      else
        data[key] = value
      end
    end
    return data
  end

  def self.process_data(field, data_row, parent_data)
    md=/nested\((\d+)\)/.match(field[4])
    if md.blank?
      value = ""
      value = data_row["#{field[2]}"] if data_row.has_key?("#{field[2]}")
      style = nil
      if !field[5].blank?
        style = MissingDataReport.method(field[5].to_sym).call(value, field[2], data_row, parent_data)
      end
      style = 'default_cell' if style.blank?

      return [[ value, field[4], style ]]
    else
      return self.get_nested_data(field, md[1], data_row)
    end
  end

  def self.get_nested_data(field, num_repeats, data_row)
    nested_data = []
    nested_data_row = data_row[field[3]]

    (0..(num_repeats.to_i-1)).each do |i|
      NESTED_FIELDS.select{|nested_field| nested_field[0] == field[2] }.each do |nf|
        d = {} 
        d = nested_data_row[i] if !nested_data_row.blank? && nested_data_row.length >= (i + 1)
        nested_data += self.process_data(nf, d, data_row)
      end
    end
    return nested_data
  end

  def self.mi_attempt_titles
    start_pos = 0
    end_pos = 0
    mi_attempt_titles = []

    REPORT_FIELDS.select{|field| field[0] == 'MI Attempt'}.each do |field|
      titles, end_pos = self.process_field(field, start_pos, end_pos)
      start_pos = end_pos
      mi_attempt_titles << titles
    end

    return mi_attempt_titles
  end

  def self.f1_colony_titles
    start_pos = 0
    end_pos = 0
    mi_attempt_titles = []

    REPORT_FIELDS.select{|field| field[0] == 'F1 Colony'}.each do |field|
      titles, end_pos = self.process_field(field, start_pos, end_pos)
      start_pos = end_pos
      mi_attempt_titles << titles
    end

    return mi_attempt_titles
  end

  def self.get_nested_fields(field, num_repeats, start_pos, end_pos)
    all_nested_titles = []
    (0..(num_repeats.to_i-1)).each do |i|
      nested_titles = []
      NESTED_FIELDS.select{|nested_field| nested_field[0] == field }.each do |nf|
        titles, end_pos = self.process_field(nf, start_pos, end_pos)
        start_pos = end_pos
        nested_titles << titles
      end
      all_nested_titles << nested_titles
    end
    return all_nested_titles, end_pos
  end

  def self.process_field(field, start_pos, end_pos)
      start_pos += 1
      end_pos += 1
      nested = nil
      md=/nested\((\d+)\)/.match(field[4])
      nested, end_pos = self.get_nested_fields(field[2], md[1].to_i, start_pos - 1, end_pos - 1) unless md.blank?
      return [{title: field[1], position_range: [start_pos, end_pos], nested: nested}, end_pos]
  end

  def format_blank_orange(value, field, data_row, parent_data)
    return 'orange_cell' if value.blank?
    return nil
  end

  def self.format_blank_red(value, field, data_row, parent_data)
    return 'red_cell' if value.blank?
    return nil
  end

  def self.format_blank_n_electroporation(value, field, data_row, parent_data)
    return 'red_cell' if value.blank? && data_row['delivery_method'] == 'Electroporation'
    return nil
  end

  def self.format_blank_n_next_day_transfer(value, field, data_row, parent_data)
    return 'red_cell' if value.blank? && data_row['crsp_embryo_transfer_day'] == 'Next Day'
    return nil
  end

  def self.format_blank_n_embyo_injected(value, field, data_row, parent_data)
    return 'red_cell' if value.blank? && !data_row['crsp_total_embryos_injected'].blank?
    return nil
  end

  def self.format_blank_n_not_individually_set(value, field, data_row, parent_data)
    return 'red_cell' if value.blank? && !data_row['individually_set_grna_concentrations']
    return nil
  end

  def self.format_blank_nucleases(value, field, data_row, parent_data)
    return 'red_cell' if data_row['mrna_nuclease'].blank? && data_row['protein_nuclease'].blank?
    return nil
  end

  def self.format_blank_nucleases_concentrations(value, field, data_row, parent_data)
    if value.blank? && ((field == 'mrna_nuclease_concentration' && !data_row['mrna_nuclease'].blank?) || (field == 'protein_nuclease_concentration' && !data_row['protein_nuclease'].blank?))
      return 'red_cell'
    elsif data_row['mrna_nuclease'].blank? && data_row['protein_nuclease'].blank? && data_row['mrna_nuclease_concentration'].blank? && data_row['protein_nuclease_concentration'].blank?
      return 'red_cell'
    end
    return nil
  end

  def self.format_founder_counts(value, field, data_row, parent_data)

    field_order = ['crsp_total_transfered', 'crsp_no_founder_pups', 'founder_num_assays', 'crsp_num_founders_selected_for_breading']
    field_index = field_order.find_index(field)
    field_to_the_left = field_index == 0 ? nil : field_order[field_index - 1]
    field_to_the_right = field_index == (field_order.length + 1) ? nil : field_order[field_index + 1]

    if value.blank? && !field_to_the_left.blank? && !data_row[field_to_the_left].blank? && data_row[field_to_the_left].to_i != 0
      return 'red_cell'
    elsif value.blank? && !field_to_the_right.blank? && !data_row[field_to_the_right].blank? && data_row[field_to_the_right].to_i != 0
      return 'red_cell'
    elsif !value.blank? && !field_to_the_right.blank? && !data_row[field_to_the_right].blank? && data_row[field_to_the_right].to_i  > value.to_i 
      return 'orange_cell'
    end
    return nil
  end


  def self.format_founder_with_detected_mutation(value, field, data_row, parent_data)
    if value.blank? && !parent_data['founder_num_assays'].blank?
      return 'red_cell'
    elsif !parent_data['founder_num_assays'].blank? && parent_data['founder_num_assays'].to_i < value.to_i
      return 'orange_cell'    
    elsif !value.blank? && (value.to_i < data_row['no_nhej_g0_mutants'].to_i || value.to_i < data_row['no_deletion_g0_mutants'].to_i || value.to_i < data_row['no_hr_g0_mutants'].to_i || value.to_i < data_row['no_hdr_g0_mutants'].to_i)
      return 'orange_cell'
    end
    return nil
  end

  def self.format_founder_qc(value, field, data_row, parent_data)
    qc_fields = ['no_nhej_g0_mutants', 'no_deletion_g0_mutants', 'no_hr_g0_mutants', 'no_hdr_g0_mutants']
    if value.blank? && !parent_data['founder_num_assays'].blank? && data_row['no_g0_where_mutation_detected'].to_i != 0 && qc_fields.all?{|field| data_row[field].blank?}
      return 'red_cell'
    end
    return nil
  end

  def self.format_founder_hdr_qc(value, field, data_row, parent_data)
    if value.blank? && !data_row['no_hdr_g0_mutants'].blank? && data_row['no_hdr_g0_mutants_all_donors_inserted'].blank? && data_row['no_hdr_g0_mutants_subset_donors_inserted'].blank?
      return 'red_cell'
    elsif !data_row['no_hdr_g0_mutants'].blank? && data_row['no_hdr_g0_mutants'].to_i != (data_row['no_hdr_g0_mutants_all_donors_inserted'].to_i + data_row['no_hdr_g0_mutants_subset_donors_inserted'].to_i )
      return 'orange_cell'
    end
    return nil
  end

  def self.format_assay_type(value, field, data_row, parent_data)
    if value.blank? && !data_row['founder_num_assays'].blank?
      return 'red_cell'
    end
    return nil
  end

  def self.format_blank_red_if_genoype_confirmed(value, field, data_row, parent_data)
    if value.blank? && (  (data_row.has_key?('genotype_confirmed') && data_row['genotype_confirmed'] == "t") || (!parent_data.blank? && parent_data.has_key?('genotype_confirmed') && parent_data['genotype_confirmed'] == "t")  )
      return 'red_cell'
    end
    return nil
  end

  def self.format_orange_if_false_n_genoype_confirmed(value, field, data_row, parent_data)
    if value == "f" && (  (data_row.has_key?('genotype_confirmed') && data_row['genotype_confirmed'] == "t") || (!parent_data.blank? && parent_data.has_key?('genotype_confirmed') && parent_data['genotype_confirmed'] == "t")  )
      return 'orange_cell'
    end
    return nil
  end

  def self.format_blue(value, field, data_row, parent_data)
    return 'blue_cell'
  end

  def mi_attempt_sql
    <<-EOF
      WITH mfs AS (
        SELECT mi_attempts.id AS mi_attempt_id, #{MUTAGENESIS_FACTOR_FIELDS.map{|k, field| "mf.#{field}" }.join(', ')},
        json_agg( ROW( #{CRISPR_FIELDS.map{|k, field| "c.#{field}" }.join(', ')} ) ) AS crisprs
        FROM mutagenesis_factors mf
          JOIN mi_attempts ON  mi_attempts.mutagenesis_factor_id = mf.id
          JOIN targ_rep_crisprs  c  ON c.mutagenesis_factor_id = mf.id
        GROUP BY mi_attempts.id, #{MUTAGENESIS_FACTOR_FIELDS.map{|k, field| "mf.#{field}" }.join(', ')}
        )


      SELECT '=HYPERLINK("https://www.mousephenotype.org/imits/mi_attempts/' || mi_attempts.id || '")' AS mi_attempt_url,
             genes.mgi_accession_id, genes.marker_symbol, consortia.name AS consortium_name, centres.name AS production_centre_name,
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
        JOIN centres ON centres.id = mi_plans.production_centre_id #{ !@centre.blank? ? " AND centres.name = '#{@centre}'" : ''}
      WHERE mi_attempts.mutagenesis_factor_id IS NOT NULL
      GROUP BY mi_attempts.id, genes.mgi_accession_id, genes.marker_symbol, consortia.name, centres.name, mis.name, strains.name, parent_colony,
               #{FIELDS['crispr_mi'].map{|f| "mi_attempts.#{f}"}.join(', ')}
    EOF
  end

  def f1_colony_sql
    <<-EOF
      SELECT '=HYPERLINK("https://www.mousephenotype.org/imits/mi_attempts/' || mi_attempts.id || '")' AS mi_attempt_url, mi_attempts.external_ref,
      genes.mgi_accession_id, genes.marker_symbol, consortia.name AS consortium_name, centres.name AS production_centre_name,
      #{FIELDS['colonies'].map{|f| "colonies.#{f} AS #{f}"}.join(', ')}, strains.name AS background_strain_name, tc.trace_file_file_name AS trace_file_name,
      json_agg( ROW( #{ALLELE_FIELDS.map{|k, field| "alleles.#{field}" }.join(', ')} ) ) AS colonies_alleles
      FROM colonies
        JOIN alleles ON alleles.colony_id = colonies.id
        JOIN mi_attempts ON mi_attempts.id = colonies.mi_attempt_id
        JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
        JOIN genes ON genes.id = mi_plans.gene_id
        JOIN centres ON centres.id = mi_plans.production_centre_id #{ !@centre.blank? ? " AND centres.name = '#{@centre}'" : ''}
        JOIN consortia ON consortia.id = mi_plans.consortium_id
        LEFT JOIN strains ON strains.id = colonies.background_strain_id
        LEFT JOIN trace_calls tc ON tc.colony_id = colonies.id
      WHERE mi_attempts.mutagenesis_factor_id IS NOT NULL
      GROUP BY mi_attempts.id, mi_attempts.external_ref, genes.mgi_accession_id, genes.marker_symbol, consortia.name, centres.name,
      colonies.id, #{FIELDS['colonies'].map{|f| "colonies.#{f}"}.join(', ')}, strains.name, tc.trace_file_file_name
    EOF
  end
end
