class ReportsController < ApplicationController
  respond_to :html

  def index
  end

  def microinjection_list
    unless params[:commit].blank?
      filters = {}
      filters[:production_centre_id] = params[:production_centre_id] unless params[:production_centre_id].blank?

      report_column_order_and_names = {
        'pipeline.name'                                   => 'Pipeline',
        'production_centre.name'                          => 'Production Centre',
        'clone.clone_name'                                => 'Clone Name',
        'clone.allele_name'                               => 'Clone Allele Name',
        'mi_date'                                         => 'Injection Date',
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

      @report = MiAttempt.report_table( :all,
        :only       => report_column_order_and_names.keys.map{ |field| field.to_sym },
        :conditions => filters,
        :include    => {
          :production_centre        => { :only => [ :name ] },
          :clone                    => { :methods => [ :allele_name ], :only => [ :clone_name ], :include => { :pipeline => { :only => [ :name ] } } },
          :blast_strain             => { :methods => [ :name ], :only => [] },
          :colony_background_strain => { :methods => [ :name ], :only => [] },
          :test_cross_strain        => { :methods => [ :name ], :only => [] }
        }
      )

      @report.add_column( '% Pups Born',                              :after => 'total_pups_born' )                         { |row| calculate_percentage( row.total_pups_born, row.total_transferred ) }
      @report.add_column( '% Total Chimeras',                         :after => 'total_chimeras' )                          { |row| calculate_percentage( row.total_chimeras, row.total_pups_born ) }
      @report.add_column( '% Male Chimeras',                          :after => 'total_male_chimeras' )                     { |row| calculate_percentage( row.total_male_chimeras, row.total_chimeras ) }
      @report.add_column( '# Chimeras with Coat Colour Transmission', :after => 'number_of_chimeras_with_100_percent_glt' ) { |row| calculate_num_chimeras_with_cct( row ) }
      @report.add_column( '% Chimeras With GLT',                      :after => 'number_of_het_offspring' )                 { |row| calculate_percentage( calculate_max_glt( row ), row.total_male_chimeras ) }

      @report.remove_columns( report_column_order_and_names.dup.delete_if{ |key,value| !value.blank? }.keys )
      @report.rename_columns( report_column_order_and_names.dup.delete_if{ |key,value| value.blank? } )
    end
  end

  private

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
      sum = row.number_of_chimeras_with_0_to_9_percent_glt + row.number_of_chimeras_with_10_to_49_percent_glt \
          + row.number_of_chimeras_with_50_to_99_percent_glt + row.number_of_chimeras_with_100_percent_glt
      sum
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

end
