# encoding: utf-8

module Reports::Helper

    def generate_mi_list_report( params={} )
      report_column_order_and_names = {
        'consortium.name'                                             => 'Consortium',
        'production_centre.name'                                      => 'Production Centre',
        'pipeline.name'                                               => 'ES Cell Pipeline',
        'es_cell.name'                                                => 'Clone Name',
        'es_cell.parental_cell_line'                                  => 'ES Cell Parental Cell Line',
        'gene.mgi_accession_id'                                       => 'MGI Accession ID',
        'gene.marker_symbol'                                          => 'Marker Symbol',
        'es_cell.allele_symbol'                                       => 'Clone Allele Name',
        'mi_attempts.mi_date'                                         => 'Injection Date',
        'mi_attempts.status'                                          => 'Status',
        'colony_background_strain.name'                               => 'Background Strain',
        'blast_strain.name'                                           => 'Blastocyst Strain',
        'mi_attempts.total_transferred'                               => '# Blastocysts Transferred',
        'mi_attempts.total_pups_born'                                 => '# Pups Born',
        'mi_attempts.total_chimeras'                                  => '# Total Chimeras',
        'mi_attempts.total_male_chimeras'                             => '# Male Chimeras',
        'mi_attempts.total_female_chimeras'                           => '# Female Chimeras',
        'mi_attempts.number_of_males_with_0_to_39_percent_chimerism'  => '# Male Chimeras/Coat Colour < 40%',
        'mi_attempts.number_of_males_with_40_to_79_percent_chimerism' => '# Male Chimeras/Coat Colour 40-79%',
        'mi_attempts.number_of_males_with_80_to_99_percent_chimerism' => '# Male Chimeras/Coat Colour 80-99%',
        'mi_attempts.number_of_males_with_100_percent_chimerism'      => '# Male Chimeras/Coat Colour 100%',
        'test_cross_strain.name'                                      => 'Test Cross Strain',
        'mi_attempts.number_of_chimera_matings_attempted'             => '# Chimeras Set-Up',
        'mi_attempts.number_of_chimeras_with_0_to_9_percent_glt'      => '# Chimeras < 10% GLT',
        'mi_attempts.number_of_chimeras_with_10_to_49_percent_glt'    => '# Chimeras 10-49% GLT',
        'mi_attempts.number_of_chimeras_with_50_to_99_percent_glt'    => '# Chimeras 50-99% GLT',
        'mi_attempts.number_of_chimeras_with_100_percent_glt'         => '# Chimeras 100% GLT',
        'mi_attempts.number_of_cct_offspring'                         => '# Coat Colour Offspring',
        'mi_attempts.number_of_chimeras_with_glt_from_genotyping'     => '# Chimeras with Genotype-Confirmed Transmission',
        'mi_attempts.number_of_het_offspring'                         => '# Heterozygous Offspring',
        'mi_attempts.colony_name'                                     => 'Colony Name',
        'mi_attempts.is_suitable_for_emma'                            => 'Suitable for EMMA?',
        'mi_attempts.is_active'                                       => 'Active?',
        'mi_attempts.comments'                                        => 'Comments',
        'mi_attempts.number_of_chimeras_with_glt_from_cct'            => nil
      }

      report = MiPlan.with_mi_attempt.report_table( :all,
        :only       => report_column_order_and_names.keys,
        :conditions => process_filter_params( params ),
        :include    => {
          :consortium        => { :only => [:name] },
          :production_centre => { :only => [:name] },
          :gene              => { :only => [:marker_symbol,:mgi_accession_id] },
          :mi_attempts => {
            :only => [
              :mi_date,
              :total_transferred,
              :total_pups_born,
              :total_chimeras,
              :total_male_chimeras,
              :total_female_chimeras,
              :number_of_males_with_0_to_39_percent_chimerism,
              :number_of_males_with_40_to_79_percent_chimerism,
              :number_of_males_with_80_to_99_percent_chimerism,
              :number_of_males_with_100_percent_chimerism,
              :number_of_chimera_matings_attempted,
              :number_of_chimeras_with_0_to_9_percent_glt,
              :number_of_chimeras_with_10_to_49_percent_glt,
              :number_of_chimeras_with_50_to_99_percent_glt,
              :number_of_chimeras_with_100_percent_glt,
              :number_of_cct_offspring,
              :number_of_chimeras_with_glt_from_genotyping,
              :number_of_het_offspring,
              :colony_name,
              :is_suitable_for_emma,
              :is_active,
              :comments,
              :number_of_chimeras_with_glt_from_cct
            ],
            :methods => [:status],
            :include => {
              :es_cell                  => { :only => [:name, :parental_cell_line], :methods => [:allele_symbol], :include => { :pipeline => { :only => [:name] } } },
              :blast_strain             => { :only => [], :methods => [:name] },
              :colony_background_strain => { :only => [], :methods => [:name] },
              :test_cross_strain        => { :only => [], :methods => [:name] }
            }
          }
        }
      )

      return nil if report.size == 0

      report.add_column( '% Pups Born',                              :after => 'mi_attempts.total_pups_born' )                         { |row| calculate_percentage( row.data['mi_attempts.total_pups_born'], row.data['mi_attempts.total_transferred'] ) }
      report.add_column( '% Total Chimeras',                         :after => 'mi_attempts.total_chimeras' )                          { |row| calculate_percentage( row.data['mi_attempts.total_chimeras'], row.data['mi_attempts.total_pups_born'] ) }
      report.add_column( '% Male Chimeras',                          :after => 'mi_attempts.total_male_chimeras' )                     { |row| calculate_percentage( row.data['mi_attempts.total_male_chimeras'], row.data['mi_attempts.total_chimeras'] ) }
      report.add_column( '# Chimeras with Coat Colour Transmission', :after => 'mi_attempts.number_of_chimeras_with_100_percent_glt' ) { |row| calculate_num_chimeras_with_cct( row ) }
      report.add_column( '% Chimeras With GLT',                      :after => 'mi_attempts.number_of_het_offspring' )                 { |row| calculate_percentage( calculate_max_glt( row ), row.data['mi_attempts.total_male_chimeras'] ) }

      report.remove_columns( report_column_order_and_names.dup.delete_if{ |key,value| !value.blank? }.keys )
      report.rename_columns( report_column_order_and_names.dup.delete_if{ |key,value| value.blank? } )

      return report
    end

    def process_filter_params( params={} )
      return {
        :production_centre_id => process_filter_param(params[:production_centre_id]),
        :consortium_id        => process_filter_param(params[:consortium_id])
      }.delete_if { |key,value| value.nil? }
    end

    def process_filter_param( param=[] )
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
      if row.data['mi_attempts.number_of_chimeras_with_glt_from_cct']
        row.data['mi_attempts.number_of_chimeras_with_glt_from_cct']
      else
        sum = [
          0,
          row.data['mi_attempts.number_of_chimeras_with_0_to_9_percent_glt'],
          row.data['mi_attempts.number_of_chimeras_with_10_to_49_percent_glt'],
          row.data['mi_attempts.number_of_chimeras_with_50_to_99_percent_glt'],
          row.data['mi_attempts.number_of_chimeras_with_100_percent_glt']
        ].compact.reduce(:+)
      end
    end

    def calculate_max_glt( row )
      values = [
        row.data['mi_attempts.number_of_chimeras_with_glt_from_genotyping'],
        row.data['# Chimeras with Coat Colour Transmission']
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

    def cleaned_redirect_params( action, params )
      redirect_params = { :action => action, :commit => true }
      [
        :consortium_id,
        :production_centre_id,
        :grouping,
        :include_plans_with_active_attempts
      ].each do |parameter|
        redirect_params[parameter] = params[parameter] unless params[parameter].blank?
      end
      return redirect_params
    end

  def get_cached_report(name)
    #get cached report
    detail_cache = ReportCache.find_by_name(name)
    raise 'cannot get cached report' if ! detail_cache
    
    #get string representing csv
    csv1 = detail_cache.csv_data
    raise 'cannot get cached report CSV' if ! csv1

    #build csv object
    csv2 = CSV.parse(csv1)
    raise 'cannot parse CSV' if ! csv2

    header = csv2.shift
    raise 'cannot get CSV header' if ! header

    #build ruport object
    table = Ruport::Data::Table.new :data => csv2, :column_names => header
    raise 'cannot build ruport instance from CSV' if ! table
    
    return table
  end

end
