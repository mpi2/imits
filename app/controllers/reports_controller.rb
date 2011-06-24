class ReportsController < ApplicationController
  respond_to :html
  before_filter :authenticate_user!

  def index
  end

  def microinjection_list
    unless params[:commit].blank?
      @report = generate_mi_list_report( params )
      @report = Grouping( @report, :by => params[:grouping] ) unless params[:grouping].blank?
    end
  end
  
  def production_summary
    unless params[:commit].blank?
      report = generate_mi_list_report( params )
      report.add_column( 'Month Injected' ) { |row| Date.new( row.data['Injection Date'].year, row.data['Injection Date'].month, 1 ) }

      grouped_report = Grouping( report, :by => 'Month Injected' )
      @summary = grouped_report.summary(
        'Month Injected',
        '# Clones Injected'           => lambda { |group| count_unique_instances_of( group, 'Clone Name' ) },
        '# at Birth'                  => lambda { |group| count_unique_instances_of( group, 'Clone Name', lambda { |row| row.data['# Pups Born'].to_i > 0 ? true : false } ) },
        '# at Weaning'                => lambda { |group| count_unique_instances_of( group, 'Clone Name', lambda { |row| row.data['# Male Chimeras'].to_i > 0 ? true : false } ) },
        '# Clones Genotype Confirmed' => lambda { |group| count_unique_instances_of( group, 'Clone Name', lambda { |row| row.data['Status'] == 'Genotype confirmed' ? true : false } ) }
      )

      @summary.add_column( '% of Injected (at Birth)',    :after => '# at Birth' )                  { |row| calculate_percentage( row.data['# at Birth'], row.data['# Clones Injected'] ) }
      @summary.add_column( '% Clones Genotype Confirmed', :after => '# Clones Genotype Confirmed' ) { |row| calculate_percentage( row.data['# Clones Genotype Confirmed'], row.data['# Clones Injected'] ) }
    end
  end

  protected

  def generate_mi_list_report( params )
    report_column_order_and_names = {
      'pipeline.name'                                   => 'Pipeline',
      'production_centre.name'                          => 'Production Centre',
      'clone.clone_name'                                => 'Clone Name',
      'clone.allele_name'                               => 'Clone Allele Name',
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
        :clone                    => { :methods => [ :allele_name ], :only => [ :clone_name ], :include => { :pipeline => { :only => [ :name ] } } },
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
