class ReportsController < ApplicationController
  respond_to :html, :csv

  before_filter :authenticate_user!

  def index
  end

  def microinjection_list
    unless params[:commit].blank?
      @report = generate_mi_list_report( params )
      @report.sort_rows_by!( 'Injected Date', :order => :descending )
      @report = Grouping( @report, :by => params[:grouping], :order => :name ) unless params[:grouping].blank?

      if request.format == :csv
        send_data(
          @report.to_csv,
          :type     => 'text/csv; charset=utf-8; header=present',
          :filename => 'microinjection_list.csv'
        )
      end
    end
  end

  def production_summary
    unless params[:commit].blank?
      report = generate_mi_list_report( params )

      report.add_column( 'Month Injected' ) do |row|
        "#{row.data['Injection Date'].year}-#{sprintf('%02d', row.data['Injection Date'].month)}" if row.data['Injection Date']
      end

      @report = Table(
        [
          'Production Centre',
          'Month Injected',
          '# Clones Injected',
          '# at Birth',
          '% of Injected (at Birth)',
          '# at Weaning',
          '# Clones Genotype Confirmed',
          '% Clones Genotype Confirmed'
        ]
      )

      grouped_report = Grouping( report, :by => [ 'Production Centre', 'Month Injected' ] )
      grouped_report.each do |production_centre|
        summary = grouped_report.subgrouping(production_centre).summary(
          'Month Injected',
          '# Clones Injected'           => lambda { |group| count_unique_instances_of( group, 'Clone Name' ) },
          '# at Birth'                  => lambda { |group| count_unique_instances_of( group, 'Clone Name', lambda { |row| row.data['# Pups Born'].to_i > 0 ? true : false } ) },
          '# at Weaning'                => lambda { |group| count_unique_instances_of( group, 'Clone Name', lambda { |row| row.data['# Male Chimeras'].to_i > 0 ? true : false } ) },
          '# Clones Genotype Confirmed' => lambda { |group| count_unique_instances_of( group, 'Clone Name', lambda { |row| row.data['Status'] == 'Genotype confirmed' ? true : false } ) }
        )

        summary.add_column( '% of Injected (at Birth)',    :after => '# at Birth' )                  { |row| calculate_percentage( row.data['# at Birth'], row.data['# Clones Injected'] ) }
        summary.add_column( '% Clones Genotype Confirmed', :after => '# Clones Genotype Confirmed' ) { |row| calculate_percentage( row.data['# Clones Genotype Confirmed'], row.data['# Clones Injected'] ) }

        summary.each_entry do |row|
          hash = row.to_hash
          hash['Production Centre'] = production_centre
          @report << hash
        end
      end

      @report.sort_rows_by!( nil, :order => :descending ) do |row|
        if row.data['Month Injected']
          datestr = row.data['Month Injected'].split('-')
          Date.new( datestr[0].to_i, datestr[1].to_i, 1 )
        else
          Date.new( 1966, 6, 30 )
        end
      end

      @report = Grouping( @report, :by => [ 'Production Centre' ], :order => :name )

      if request.format == :csv
        send_data(
          @report.to_csv,
          :type     => 'text/csv; charset=utf-8; header=present',
          :filename => 'production_summary.csv'
        )
      end
    end
  end

  def gene_summary
    unless params[:commit].blank?
      report         = generate_mi_list_report( params )
      grouped_report = Grouping( report, :by => [ 'Production Centre' ], :order => :name )

      @report  = grouped_report.summary(
        'Production Centre',
        '# Genes Injected'           => lambda { |group| count_unique_instances_of( group, 'Marker Symbol' ) },
        '# Genes Genotype Confirmed' => lambda { |group| count_unique_instances_of( group, 'Marker Symbol', lambda { |row| row.data['Status'] == 'Genotype confirmed' ? true : false } ) },
        :order => [ 'Production Centre', '# Genes Injected', '# Genes Genotype Confirmed' ]
      )

      if request.format == :csv
        send_data(
          @report.to_csv,
          :type     => 'text/csv; charset=utf-8; header=present',
          :filename => 'gene_summary.csv'
        )
      end
    end
  end

  def planned_mis
    report_column_order_and_names = {
      'consortium.name'       => 'Consortium',
      'gene.marker_symbol'    => 'Marker Symbol',
      'gene.mgi_accession_id' => 'MGI Accession ID',
      'mi_plan_priority.name' => 'Priority',
      'mi_plan_status.name'   => 'Status'
    }
    
    all_mi_plans = MiPlan.report_table(
      :all,
      :only => [],
      :include => {
        :consortium       => { :only => [ :name ] },
        :gene             => { :only => [ :marker_symbol, :mgi_accession_id ] },
        :mi_plan_priority => { :only => [ :name ] },
        :mi_plan_status   => { :only => [ :name ] }
      }
    )
    
    all_mi_plans.remove_columns( report_column_order_and_names.dup.delete_if{ |key,value| !value.blank? }.keys )
    all_mi_plans.rename_columns( report_column_order_and_names.dup.delete_if{ |key,value| value.blank? } )
    
    @summary = Table([ 'Status', 'Consortium', '# High Priority', '# Medium Priority', '# Low Priority' ])
    
    grouped_report = Grouping( all_mi_plans, :by => ['Status','Consortium'], :order => :name )
    grouped_report.each do |status|
      summary = grouped_report.subgrouping(status).summary(
        'Consortium',
        '# High Priority'   => lambda { |group| count_unique_instances_of( group, 'Marker Symbol', lambda { |row| row.data['Priority'] == 'High' } ) },
        '# Medium Priority' => lambda { |group| count_unique_instances_of( group, 'Marker Symbol', lambda { |row| row.data['Priority'] == 'Medium' } ) },
        '# Low Priority'    => lambda { |group| count_unique_instances_of( group, 'Marker Symbol', lambda { |row| row.data['Priority'] == 'Low' } ) },
        :order => [ 'Consortium', '# High Priority', '# Medium Priority', '# Low Priority' ]
      )
      
      summary.each_entry do |row|
        hash = row.to_hash
        hash['Status'] = status
        @summary << hash
      end
    end
    
    @summary = Grouping( @summary, :by => ['Status'], :order => :name )
    
    @conflict_report = all_mi_plans.sub_table { |row| row['Status'] == 'Conflict' }
    @conflict_report.remove_columns(['Status'])
  end

  protected

  def generate_mi_list_report( params )
    report_column_order_and_names = {
      'pipeline.name'                                   => 'Pipeline',
      'production_centre.name'                          => 'Production Centre',
      'es_cell.name'                                    => 'Clone Name',
      'es_cell.marker_symbol'                           => 'Marker Symbol',
      'es_cell.allele_symbol'                           => 'Clone Allele Name',
      'mi_date'                                         => 'Injection Date',
      'mi_attempt_status.description'                   => 'Status',
      'colony_background_strain.name'                   => 'Background Strain',
      'blast_strain.name'                               => 'Blastocyst Strain',
      'total_transferred'                               => '# Blastocysts Transferred',
      'total_pups_born'                                 => '# Pups Born',
      'total_chimeras'                                  => '# Total Chimeras',
      'total_male_chimeras'                             => '# Male Chimeras',
      'total_female_chimeras'                           => '# Female Chimeras',
      'number_of_males_with_0_to_39_percent_chimerism'  => '# Male Chimeras/Coat Colour < 40%',
      'number_of_males_with_40_to_79_percent_chimerism' => '# Male Chimeras/Coat Colour 40-79%',
      'number_of_males_with_80_to_99_percent_chimerism' => '# Male Chimeras/Coat Colour 80-99%',
      'number_of_males_with_100_percent_chimerism'      => '# Male Chimeras/Coat Colour 100%',
      'test_cross_strain.name'                          => 'Test Cross Strain',
      'number_of_chimera_matings_attempted'             => '# Chimeras Set-Up',
      'number_of_chimeras_with_0_to_9_percent_glt'      => '# Chimeras < 10% GLT',
      'number_of_chimeras_with_10_to_49_percent_glt'    => '# Chimeras 10-49% GLT',
      'number_of_chimeras_with_50_to_99_percent_glt'    => '# Chimeras 50-99% GLT',
      'number_of_chimeras_with_100_percent_glt'         => '# Chimeras 100% GLT',
      'number_of_cct_offspring'                         => '# Coat Colour Offspring',
      'number_of_chimeras_with_glt_from_genotyping'     => '# Chimeras with Genotype-Confirmed Transmission',
      'number_of_het_offspring'                         => '# Heterozygous Offspring',
      'colony_name'                                     => 'Colony Name',
      'is_suitable_for_emma'                            => 'Suitable for EMMA?',
      'comments'                                        => 'Comments',
      'number_of_chimeras_with_glt_from_cct'            => nil
    }

    report = MiAttempt.report_table( :all,
      :only       => report_column_order_and_names.keys,
      :conditions => process_filter_params( params ),
      :include    => {
        :production_centre        => { :only => [ :name ] },
        :es_cell                  => { :methods => [ :allele_symbol ], :only => [ :name, :marker_symbol ], :include => { :pipeline => { :only => [ :name ] } } },
        :blast_strain             => { :methods => [ :name ], :only => [] },
        :colony_background_strain => { :methods => [ :name ], :only => [] },
        :test_cross_strain        => { :methods => [ :name ], :only => [] },
        :mi_attempt_status        => { :only => [:description] }
      }
    )

    report.add_column( '% Pups Born',                              :after => 'total_pups_born' )                         { |row| calculate_percentage( row.total_pups_born, row.total_transferred ) }
    report.add_column( '% Total Chimeras',                         :after => 'total_chimeras' )                          { |row| calculate_percentage( row.total_chimeras, row.total_pups_born ) }
    report.add_column( '% Male Chimeras',                          :after => 'total_male_chimeras' )                     { |row| calculate_percentage( row.total_male_chimeras, row.total_chimeras ) }
    report.add_column( '# Chimeras with Coat Colour Transmission', :after => 'number_of_chimeras_with_100_percent_glt' ) { |row| calculate_num_chimeras_with_cct( row ) }
    report.add_column( '% Chimeras With GLT',                      :after => 'number_of_het_offspring' )                 { |row| calculate_percentage( calculate_max_glt( row ), row.total_male_chimeras ) }

    report.remove_columns( report_column_order_and_names.dup.delete_if{ |key,value| !value.blank? }.keys )
    report.rename_columns( report_column_order_and_names.dup.delete_if{ |key,value| value.blank? } )

    return report
  end

  def process_filter_params( params )
    params[:production_centre_id]  = process_filter_param(params[:production_centre_id])
    params[:pipeline_id]           = process_filter_param(params[:pipeline_id])

    filters = {}

    filters[:production_centre_id] = params[:production_centre_id] unless params[:production_centre_id].nil?
    filters[:'pipelines.id']       = params[:pipeline_id] unless params[:pipeline_id].nil?

    return filters
  end

  def process_filter_param( param )
    param ||= []
    param.delete_if { |elm| elm.blank? }
    if param.empty?
      return nil
    else
      return param
    end
  end

  def calculate_percentage( dividend, divisor )
    if dividend and ( divisor and divisor > 0 )
      ( ( dividend.to_f / divisor.to_f ) * 100.00 ).round
    else
      0
    end
  end

  def calculate_num_chimeras_with_cct( row )
    if row.number_of_chimeras_with_glt_from_cct
      row.number_of_chimeras_with_glt_from_cct
    else
      sum  = 0
      nums = [
        row.number_of_chimeras_with_0_to_9_percent_glt,
        row.number_of_chimeras_with_10_to_49_percent_glt,
        row.number_of_chimeras_with_50_to_99_percent_glt,
        row.number_of_chimeras_with_100_percent_glt
      ].compact

      nums.each { |elm| sum += elm }

      return sum
    end
  end

  def calculate_max_glt( row )
    values = [
      row.number_of_chimeras_with_glt_from_genotyping,
      row.data['# Chimeras with Coat Colour Transmission'],
      row.number_of_chimeras_with_glt_from_genotyping
    ].compact.sort

    return values.first unless values.empty?
  end

  def count_unique_instances_of( group, data_name, row_condition=nil )
    array = []
    group.each do |row|
      if row_condition.nil?
        array.push( row.data[data_name] )
      else
        array.push( row.data[data_name] ) if row_condition.call(row)
      end
    end
    array.uniq.size
  end

end
