# encoding: utf-8

class Reports::MiAttempts

  class ReportByGene

    public

#    def get_list_old
#      unless params[:commit].blank?
#        report = generate_mi_list_report( params )
#
#        if report.nil?
#          redirect_to cleaned_redirect_params( :mi_attempts_by_gene, params ) if request.format == :csv
#          return
#        end
#
#        @report = Table(
#          [
#            'Consortium',
#            'Production Centre',
#            '# Genes Injected',
#            '# Genes Genotype Confirmed',
#            '# Genes For EMMA'
#          ]
#        )
#
#        grouped_report = Grouping( report, :by => [ 'Consortium', 'Production Centre' ], :order => [:name]  )
#
#        grouped_report.each do |consortium|
#
#          puts "\nCONSORTIUM: " + consortium +"\n\n"
#
#          subgrouping = grouped_report.subgrouping(consortium)
#
#          summ = subgrouping.summary(
#            'Production Centre',
#            '# Genes Injected'           => lambda { |group| count_unique_instances_of( group, 'Marker Symbol' ) },
#            '# Genes Genotype Confirmed' => lambda { |group| count_unique_instances_of( group, 'Marker Symbol', lambda { |row| row.data['Status'] == 'Genotype confirmed' ? true : false } ) },
#            '# Genes For EMMA'           =>
#              lambda {
#              |group| count_unique_instances_of(
#                group,
#                'Marker Symbol',
#                lambda { |row| ((row.data['Status'] == 'Genotype confirmed') && (row.data['Suitable for EMMA?'])) ? true : false }
#              )
#            },
#            :order => [ 'Production Centre', '# Genes Injected', '# Genes Genotype Confirmed' , '# Genes For EMMA']
#          )
#
#          puts "summ:\n\n" + summ.inspect
#
#          summ.each do |row|
#            @report << {
#              'Consortium' => consortium,
#              'Production Centre' => row['Production Centre'],
#              '# Genes Injected' => row['# Genes Injected'],
#              '# Genes Genotype Confirmed' => row['# Genes Genotype Confirmed'],
#              '# Genes For EMMA' => row['# Genes For EMMA']
#            }
#          end
#
#        end
#
##        if request.format == :csv
##          send_data(
##            @report.to_csv,
##            :type     => 'text/csv; charset=utf-8; header=present',
##            :filename => 'mi_attempts_by_gene.csv'
##          )
##        end
#
#        return @report
#
#      end
#    end

    def self.get_list(params)
      unless params[:commit].blank?
        report = generate_mi_list_report( params )

        if report.nil?
          redirect_to cleaned_redirect_params( :mi_attempts_by_gene, params ) if request.format == :csv
          return
        end

        @report = Table(
          [
            'Consortium',
            'Production Centre',
            '# Genes Injected',
            '# Genes Genotype Confirmed',
            '# Genes For EMMA'
          ]
        )

        grouped_report = Grouping( report, :by => [ 'Consortium', 'Production Centre' ], :order => [:name]  )

        grouped_report.each do |consortium|

          puts "\nCONSORTIUM: " + consortium +"\n\n"

          subgrouping = grouped_report.subgrouping(consortium)

          summ = subgrouping.summary(
            'Production Centre',
            '# Genes Injected'           => lambda { |group| count_unique_instances_of( group, 'Marker Symbol' ) },
            '# Genes Genotype Confirmed' => lambda { |group| count_unique_instances_of( group, 'Marker Symbol', lambda { |row| row.data['Status'] == 'Genotype confirmed' ? true : false } ) },
            '# Genes For EMMA'           =>
              lambda {
              |group| count_unique_instances_of(
                group,
                'Marker Symbol',
                lambda { |row| ((row.data['Status'] == 'Genotype confirmed') && (row.data['Suitable for EMMA?'])) ? true : false }
              )
            },
            :order => [ 'Production Centre', '# Genes Injected', '# Genes Genotype Confirmed' , '# Genes For EMMA']
          )

          puts "summ:\n\n" + summ.inspect

          summ.each do |row|
            @report << {
              'Consortium' => consortium,
              'Production Centre' => row['Production Centre'],
              '# Genes Injected' => row['# Genes Injected'],
              '# Genes Genotype Confirmed' => row['# Genes Genotype Confirmed'],
              '# Genes For EMMA' => row['# Genes For EMMA']
            }
          end

        end

#        if request.format == :csv
#          send_data(
#            @report.to_csv,
#            :type     => 'text/csv; charset=utf-8; header=present',
#            :filename => 'mi_attempts_by_gene.csv'
#          )
#        end

        return @report

      end
    end

      def self.generate_mi_list_report( params={} )
    report_column_order_and_names = {
      'consortium.name'                                             => 'Consortium',
      'production_centre.name'                                      => 'Production Centre',
      'pipeline.name'                                               => 'ES Cell Pipeline',
      'es_cell.name'                                                => 'Clone Name',
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
            :es_cell                  => { :only => [:name], :methods => [:allele_symbol], :include => { :pipeline => { :only => [:name] } } },
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


  def self.process_filter_params( params={} )
    return {
      :production_centre_id => process_filter_param(params[:production_centre_id]),
      :consortium_id        => process_filter_param(params[:consortium_id])
    }.delete_if { |key,value| value.nil? }
  end

  def self.process_filter_param( param=[] )
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

  end

end
