class ReportsController < ApplicationController
  respond_to :html, :csv

  before_filter :authenticate_user!

  def index
  end

  def microinjection_list
    unless params[:commit].blank?
      @report = generate_mi_list_report( params )
      @report.sort_rows_by!( 'Injection Date', :order => :descending )
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

  def planned_microinjection_list
    unless params[:commit].blank?
      @report = generate_planned_mi_list_report( params )
      @report = Grouping( @report, :by => params[:grouping], :order => :name ) unless params[:grouping].blank?

      if request.format == :csv
        send_data(
          @report.to_csv,
          :type     => 'text/csv; charset=utf-8; header=present',
          :filename => 'planned_microinjection_list.csv'
        )
      end

    end
  end

  def planned_microinjection_summary_and_conflicts
    all_mi_plans = generate_planned_mi_list_report

    # Counts of mi_plans grouped by status

    # TODO - put an order_by field on the status table and grab this array out of the status table in the future!
    statuses = [ 'Interest', 'Conflict', 'Declined - MI Attempt', 'Declined - Conflict', 'Assigned' ]

    mi_plans_grouped_by_consortia = Grouping( all_mi_plans, :by => ['Consortium'], :order => :name )
    status_args = { :order => ['Consortium']+statuses }
    statuses.each do |status|
      status_args[status] = lambda { |group| count_unique_instances_of( group, 'Marker Symbol', lambda { |row| row.data['Status'] == status } ) }
    end

    @summary_by_status = mi_plans_grouped_by_consortia.summary( 'Consortium',status_args )
    @summary_by_status.add_column('TOTAL BY CONSORTIUM') { |row| statuses.map{ |status| row[status] }.reduce(:+) }

    totals = ['TOTAL BY STATUS']
    statuses.each { |status| totals.push( @summary_by_status.sum(status) ) }
    totals.push( @summary_by_status.sum('TOTAL BY CONSORTIUM') )
    @summary_by_status << totals

    # Counts of mi_plans grouped by status and priority

    @summary_by_status_and_priority = Table([ 'Consortium', 'Status', '# High Priority', '# Medium Priority', '# Low Priority' ])

    mi_plans_grouped_by_status_consortia = Grouping( all_mi_plans, :by => ['Status','Consortium'], :order => :name )
    mi_plans_grouped_by_status_consortia.each do |status|
      summary = mi_plans_grouped_by_status_consortia.subgrouping(status).summary(
        'Consortium',
        '# High Priority'   => lambda { |group| count_unique_instances_of( group, 'Marker Symbol', lambda { |row| row.data['Priority'] == 'High' } ) },
        '# Medium Priority' => lambda { |group| count_unique_instances_of( group, 'Marker Symbol', lambda { |row| row.data['Priority'] == 'Medium' } ) },
        '# Low Priority'    => lambda { |group| count_unique_instances_of( group, 'Marker Symbol', lambda { |row| row.data['Priority'] == 'Low' } ) },
        :order => [ 'Consortium', '# High Priority', '# Medium Priority', '# Low Priority' ]
      )

      summary.each_entry do |row|
        hash = row.to_hash
        hash['Status'] = status
        @summary_by_status_and_priority << hash
      end
    end

    @summary_by_status_and_priority = Grouping( @summary_by_status_and_priority, :by => ['Status'], :order => :name )

    # Details on conflicting and declined mi_plans

    @conflict_report = all_mi_plans.sub_table { |row| row['Status'] == 'Conflict' }
    @conflict_report.remove_columns(['Status'])

    @declined_due_to_conflict_report = all_mi_plans.sub_table { |row| row['Status'] == 'Declined - Conflict' }
    @declined_due_to_conflict_report.remove_columns(['Status'])

    @declined_due_to_existing_mi_report = all_mi_plans.sub_table { |row| row['Status'] == 'Declined - MI Attempt' }
    @declined_due_to_existing_mi_report.remove_columns(['Status'])

    if request.format == :csv
      response.headers['Content-Type'] = 'text/csv'
      response.headers['Content-Disposition'] = 'attachment; filename=planned_microinjection_summary_and_conflicts.csv'
    end
  end

  protected

  def generate_planned_mi_list_report( params={} )
    report_column_order_and_names = {
      'consortium.name'         => 'Consortium',
      'production_centre.name'  => 'Production Centre',
      'gene.marker_symbol'      => 'Marker Symbol',
      'gene.mgi_accession_id'   => 'MGI Accession ID',
      'mi_plan_priority.name'   => 'Priority',
      'mi_plan_status.name'     => 'Status'
    }

    all_mi_plans = MiPlan.without_active_mi_attempt.report_table(
      :all,
      :only       => [],
      :conditions => process_filter_params( params ),
      :include    => {
        :consortium         => { :only => [:name] },
        :production_centre  => { :only => [:name] },
        :gene               => { :only => [:marker_symbol,:mgi_accession_id] },
        :mi_plan_priority   => { :only => [:name] },
        :mi_plan_status     => { :only => [:name] }
      }
    )

    all_mi_plans.remove_columns( report_column_order_and_names.dup.delete_if{ |key,value| !value.blank? }.keys )
    all_mi_plans.rename_columns( report_column_order_and_names.dup.delete_if{ |key,value| value.blank? } )

    all_mi_plans = all_mi_plans.sort_rows_by('Marker Symbol', :order => :ascending)

    return all_mi_plans
  end

  def generate_mi_list_report( params={} )
    report_column_order_and_names = {
      'consortium.name'                                             => 'Consortium',
      'production_centre.name'                                      => 'Production Centre',
      'pipeline.name'                                               => 'ES Cell Pipeline',
      'es_cell.name'                                                => 'Clone Name',
      'gene.mgi_accession_id'                                       => 'MGI Accession ID',
      'gene.marker_symbol'                                          => 'Marker Symbol',
      'es_cell.allele_symbol'                                       => 'Clone Allele Name',
      'mi_attempts.mi_date'                                         => 'Injection Date',
      'mi_attempt_status.description'                               => 'Status',
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
        :mi_attempts       => {
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
          :include => {
            :es_cell                  => { :only => [:name], :methods => [:allele_symbol], :include => { :pipeline => { :only => [:name] } } },
            :blast_strain             => { :only => [], :methods => [:name] },
            :colony_background_strain => { :only => [], :methods => [:name] },
            :test_cross_strain        => { :only => [], :methods => [:name] },
            :mi_attempt_status        => { :only => [:description] }
          }
        }
      }
    )

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
    filters = {}
    filters[:production_centre_id] = process_filter_param(params[:production_centre_id])
    filters[:consortium_id]        = process_filter_param(params[:consortium_id])
    filters.delete_if { |key,val| val.nil? }
    return filters
  end

  def process_filter_param( param=[] )
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

end
