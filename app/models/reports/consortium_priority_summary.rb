# encoding: utf-8

class Reports::ConsortiumPrioritySummary

  extend Reports::Helper
  
  LIMIT_CONSORTIA = false
  ADD_ALL_PRIORITIES = true
  CONSORTIA = [ 'BaSH', 'DTCC', 'Helmholtz GMC', 'JAX', 'MARC', 'MGP', 'Monterotondo', 'NorCOMM2', 'Phenomin', 'RIKEN BRC' ]
  ORDER_BY_MAP = { 'Low' => 1, 'Medium' => 2, 'High' => 3}
  ROOT = '/reports/list'

  def self.subsummary1(params)
    specs = params[:specs]
    array = specs.split('/')
    raise "Invalid parameters (#{array.size})" if array.size != 4

    consortium = CGI.unescape array[1]
    column = CGI.unescape array[3]
    column = column.gsub(/^\#\s+/, "")
    raise "Invalid parameters: '#{array[0]}'" if array[0] != 'consortium' || array[2] != 'type'

    cached_report = get_cached_report('mi_production_detail')

    genes = []

    mapping = {
      'activity' => ['Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Micro-injection in progress', 'Genotype confirmed'],
      'mip' => ['Micro-injection in progress', 'Genotype confirmed'],
      'glt' => ['Genotype confirmed'],
      'aborted' => ['Micro-injection aborted']
    }

    counter = 1
    report = Table(:data => cached_report.data,
      :column_names => ['Count'] + cached_report.column_names,
      :filters => lambda {|r|
        if r['Consortium'] == consortium && (column == 'all' || mapping[column].include?(r.data['Status']))
          return false if genes.include?(r['Gene'])
          genes.push r['Gene']
          return true
        end
      },
      :transforms => lambda {|r|
        r['Count'] = counter
        counter += 1
      }
    )

    title = "subsummary1: consortium: '#{consortium}' - type: '#{column}' (#{report.size})"
    
    return title, report

  end
  
  def self.generate1
    cached_report = get_cached_report('mi_production_detail')

    report_table = Table( [ 'Consortium', 'All', 'Activity', 'Mice in production', 'Aborted', 'GLT Mice', 'Pipeline efficiency (%)' ] )
   
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Priority' ] )
    
    mapping = {
      'activity' => ['Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Micro-injection in progress', 'Genotype confirmed'],
      'mip' => ['Micro-injection in progress', 'Genotype confirmed'],
      'glt' => ['Genotype confirmed'],
      'aborted' => ['Micro-injection aborted']
    }
    
    grouped_report.summary(
      'Consortium',
      'All'                => lambda { |group| count_unique_instances_of( group, 'Gene' ) },
      'Activity'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| mapping['activity'].include? row.data['Status'] } ) },
      'Mice in production' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| mapping['mip'].include? row.data['Status'] } ) },
      'GLT Mice'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| mapping['glt'].include? row.data['Status'] } ) },
      'Aborted'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| mapping['aborted'].include? row.data['Status'] } ) }
    ).each do |row|

      glt = Integer(row['GLT Mice'])
      total = Integer(row['GLT Mice']) + Integer(row['Aborted'])
      pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
      pc = "%.2f" % pc
            
      report_table << {        
        'Consortium' => row['Consortium'],
        'All' => row['All'].to_s != '0' ? "<a href='#{ROOT}/consortium/#{row['Consortium']}/type/all'>#{row['All']}</a>" : '',
        'Activity' => row['Activity'].to_s != '0' ? "<a href='#{ROOT}/consortium/#{row['Consortium']}/type/activity'>#{row['Activity']}</a>" : '',
        'Mice in production' => row['Mice in production'].to_s != '0' ? "<a href='#{ROOT}/consortium/#{row['Consortium']}/type/mip'>#{row['Mice in production']}</a>" : '',
        'GLT Mice' => row['GLT Mice'].to_s != '0' ? "<a href='#{ROOT}/consortium/#{row['Consortium']}/type/glt'>#{row['GLT Mice']}</a>" : '',
        'Aborted' => row['Aborted'].to_s != '0' ? "<a href='#{ROOT}/consortium/#{row['Consortium']}/type/aborted'>#{row['Aborted']}</a>" : '',
        'Pipeline efficiency (%)' => pc
      }
    end
   
    report_table.sort_rows_by!( ['Consortium'] )
    
    return report_table
  end

  def self.generate2
    cached_report = get_cached_report('mi_production_detail')

    report_table = Table( ['Consortium', 'Priority', 'All', 'ES QC started', 'ES QC finished', 'MI in progress', 'Aborted', 'GLT Mice', 'order_by'] )
 
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Priority' ] )
    
    mapping = {
      :es_qc_started => ['Assigned - ES Cell QC In Progress'],
      :es_qc_finished => ['Assigned - ES Cell QC Complete'],
      :mi_in_progress => ['Micro-injection in progress'],
      :glt => ['Genotype confirmed'],
      :aborted => ['Micro-injection aborted']
    }
    
    grouped_report.each do |consortium|
      
      next if LIMIT_CONSORTIA && ! CONSORTIA.include?(consortium)
      
      summary = grouped_report.subgrouping(consortium).summary(
        'Priority',
        'All'            => lambda { |group| count_unique_instances_of( group, 'Gene' ) },
        'ES QC started'  => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| mapping[:es_qc_started].include? row.data['Status'] } ) },
        'ES QC finished' => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| mapping[:es_qc_finished].include? row.data['Status'] } ) },
        'MI in progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| mapping[:mi_in_progress].include? row.data['Status'] } ) },
        'GLT Mice'       => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| mapping[:glt].include? row.data['Status'] } ) },
        'Aborted'       => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| mapping[:aborted].include? row.data['Status'] } ) }
      )
      
      p_found = []

      summary.each do |row|
        p_found.push row['Priority']
        report_table << {
          'Consortium' => consortium,
          'Priority' => row['Priority'],
          'All' => row['All'],
          'ES QC started' => row['ES QC started'],
          'ES QC finished' => row['ES QC finished'],
          'MI in progress' => row['MI in progress'],
          'GLT Mice' => row['GLT Mice'],
          'Aborted' => row['Aborted'],
          'order_by' => ORDER_BY_MAP[row['Priority']]
        }
      end
      
      next if ! ADD_ALL_PRIORITIES
      
      p_remain = [ 'Low', 'Medium', 'High' ] - p_found
      p_remain.each do |priority|
        report_table << {
          'Consortium' => consortium,
          'Priority' => priority,
          'All' => 0,
          'ES QC started' => 0,
          'ES QC finished' => 0,
          'MI in progress' => 0,
          'GLT Mice' => 0,
          'Aborted' => 0,
          'order_by' => ORDER_BY_MAP[priority]
        }
      end
      
    end
  
    report_table.sort_rows_by!( ['Consortium', 'order_by'] )    
    report_table.remove_column('order_by')
    return report_table
  end

  #def self.generate20
  #  cached_report = get_cached_report('mi_production_detail')
  #
  #  report_table = Table( ['Consortium', 'Priority', 'All', 'ES QC started', 'ES QC finished', 'MI in progress', 'Aborted', 'GLT Mice', 'order_by'] )
  #
  #  #:breakdown => {
  #  #       'All' => {'All'=>['Priority']},
  #  #       'ES QC started' => {'Assigned - ES Cell QC In Progress' => ['Priority']},
  #  #       'ES QC finished' => {'Assigned - ES Cell QC Complete' => ['Priority']},
  #  #       'MI in progress' => {'Micro-injection in progress' => ['Priority']},
  #  #       'GLT Mice' => {'Genotype confirmed' => ['Priority']}
  #  #   }
  #
  #  grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Priority' ] )
  #  
  #  es_qc_started = ['Assigned - ES Cell QC In Progress']
  #  es_qc_finished = ['Assigned - ES Cell QC Complete']
  #  mi_in_progress = ['Micro-injection in progress']    
  #  glt = ['Genotype confirmed']
  #  aborted = ['Aborted - ES Cell QC Failed']
  #  
  #  grouped_report.each do |consortium|
  #    next if LIMIT_CONSORTIA && ! CONSORTIA.include?(consortium)
  #    grouped_report.subgrouping(consortium).summary(
  #      'Priority',
  #      'All'            => lambda { |group| count_unique_instances_of( group, 'Gene' ) },
  #      'ES QC started'  => lambda { |group| count_unique_instances_of( group, 'Gene',
  #          lambda { |row| es_qc_started.include? row.data['Status'] } ) },
  #      'ES QC finished' => lambda { |group| count_unique_instances_of( group, 'Gene',
  #          lambda { |row| es_qc_finished.include? row.data['Status'] } ) },
  #      'MI in progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
  #          lambda { |row| mi_in_progress.include? row.data['Status'] } ) },
  #      'GLT Mice'       => lambda { |group| count_unique_instances_of( group, 'Gene',
  #          lambda { |row| glt.include? row.data['Status'] } ) },
  #      'Aborted'       => lambda { |group| count_unique_instances_of( group, 'Gene',
  #          lambda { |row| aborted.include? row.data['Status'] } ) }
  #    ).each do |row|
  #      report_table << {
  #        'Consortium' => consortium,
  #        'Priority' => row['Priority'],
  #        'All' => row['All'],
  #        'ES QC started' => row['ES QC started'],
  #        'ES QC finished' => row['ES QC finished'],
  #        'MI in progress' => row['MI in progress'],
  #        'GLT Mice' => row['GLT Mice'],
  #        'Aborted' => row['Aborted'],
  #        'order_by' => ORDER_BY_MAP[row['Priority']]
  #      }
  #    end
  #  end
  #
  #  report_table.sort_rows_by!( ['Consortium', 'order_by'] )    
  #  report_table.remove_column('order_by')
  #  return report_table
  #end
  #
end
