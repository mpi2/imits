# encoding: utf-8

class Reports::ConsortiumPrioritySummary

  extend Reports::Helper
  
  LIMIT_CONSORTIA = true
  CONSORTIA = [ 'BaSH', 'DTCC', 'Helmholtz GMC', 'JAX', 'MARC', 'MGP', 'Monterotondo', 'NorCOMM2', 'Phenomin', 'RIKEN BRC' ]
  ORDER_BY_MAP = { 'Low' => 1, 'Medium' => 2, 'High' => 3}

  def self.generate1
    cached_report = get_cached_report('mi_production_detail')

    report_table = Table( [ 'Consortium', 'Priority', 'All', 'Activity', 'Mice in production', 'GLT Mice', 'order_by' ] )

    #:breakdown => {
    #    'All' => {'All' => ['Priority']},
    #    'Activity' => {
    #        'Assigned - ES Cell QC In Progress' => ['Priority'],
    #        'Assigned - ES Cell QC Complete' => ['Priority'],
    #        'Micro-injection in progress' => ['Priority'],
    #        'Genotype confirmed' => ['Priority']
    #    },
    #    'Mice in production' => {
    #        'Micro-injection in progress' => ['Priority'],
    #        'Genotype confirmed' => ['Priority']
    #    },
    #    'GLT Mice' => {
    #        'Genotype confirmed' => ['Priority']
    #    }
    #}
    
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Priority' ] )    
    activity = ['Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Micro-injection in progress', 'Genotype confirmed']    
    production = ['Micro-injection in progress', 'Genotype confirmed']    
    glt = ['Genotype confirmed']
    
    grouped_report.each do |consortium|
      next if LIMIT_CONSORTIA && ! CONSORTIA.include?(consortium)
      grouped_report.subgrouping(consortium).summary(
        'Priority',
        'All'                => lambda { |group| count_unique_instances_of( group, 'Gene' ) },
        'Activity'           => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| activity.include? row.data['Status'] } ) },
        'Mice in production' => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| production.include? row.data['Status'] } ) },
        'GLT Mice'           => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| glt.include? row.data['Status'] } ) }
      ).each do |row|
        report_table << {
          'Consortium' => consortium,
          'Priority' => row['Priority'],
          'All' => row['All'],
          'Activity' => row['Activity'],
          'Mice in production' => row['Mice in production'],
          'GLT Mice' => row['GLT Mice'],
          'order_by' => ORDER_BY_MAP[row['Priority']]
        }
      end
    end
   
    report_table.sort_rows_by!( ['Consortium', 'order_by'] )
    
    report_table.remove_column('order_by')

    return report_table
  end

  def self.generate2
    cached_report = get_cached_report('mi_production_detail')

    report_table = Table( ['Consortium', 'Priority', 'All', 'ES QC started', 'ES QC finished', 'MI in progress', 'GLT Mice', 'order_by'] )
 
    #:breakdown => {
    #       'All' => {'All'=>['Priority']},
    #       'ES QC started' => {'Assigned - ES Cell QC In Progress' => ['Priority']},
    #       'ES QC finished' => {'Assigned - ES Cell QC Complete' => ['Priority']},
    #       'MI in progress' => {'Micro-injection in progress' => ['Priority']},
    #       'GLT Mice' => {'Genotype confirmed' => ['Priority']}
    #   }

    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Priority' ] )
    
    es_qc_started = ['Assigned - ES Cell QC In Progress']
    es_qc_finished = ['Assigned - ES Cell QC Complete']
    mi_in_progress = ['Micro-injection in progress']    
    glt = ['Genotype confirmed']
    
    grouped_report.each do |consortium|
      next if LIMIT_CONSORTIA && ! CONSORTIA.include?(consortium)
      grouped_report.subgrouping(consortium).summary(
        'Priority',
        'All'            => lambda { |group| count_unique_instances_of( group, 'Gene' ) },
        'ES QC started'  => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| es_qc_started.include? row.data['Status'] } ) },
        'ES QC finished' => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| es_qc_finished.include? row.data['Status'] } ) },
        'MI in progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| mi_in_progress.include? row.data['Status'] } ) },
        'GLT Mice'       => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| glt.include? row.data['Status'] } ) }
      ).each do |row|
        report_table << {
          'Consortium' => consortium,
          'Priority' => row['Priority'],
          'All' => row['All'],
          'ES QC started' => row['ES QC started'],
          'ES QC finished' => row['ES QC finished'],
          'MI in progress' => row['MI in progress'],
          'GLT Mice' => row['GLT Mice'],
          'order_by' => ORDER_BY_MAP[row['Priority']]
        }
      end
    end
  
    report_table.sort_rows_by!( ['Consortium', 'order_by'] )    
    report_table.remove_column('order_by')
    return report_table
  end

end
