# encoding: utf-8

class Reports::ConsortiumPrioritySummary

  extend Reports::Helper
  
  LIMIT_CONSORTIA = false
  ADD_ALL_PRIORITIES = true
  CONSORTIA = [ 'BaSH', 'DTCC', 'Helmholtz GMC', 'JAX', 'MARC', 'MGP', 'Monterotondo', 'NorCOMM2', 'Phenomin', 'RIKEN BRC' ]
  ORDER_BY_MAP = { 'Low' => 1, 'Medium' => 2, 'High' => 3}
  ROOT1 = '/reports/summary1'
  ROOT2 = '/reports/summary2'
  MAPPING1 = {
    'activity' => ['Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Micro-injection in progress', 'Genotype confirmed'],
    'mip' => ['Micro-injection in progress', 'Genotype confirmed'],
    'glt' => ['Genotype confirmed'],
    'aborted' => ['Micro-injection aborted']
  }
  MAPPING2 = {
    'ES QC started' => ['Assigned - ES Cell QC In Progress'],
    'ES QC finished' => ['Assigned - ES Cell QC Complete'],
    'MI in progress' => ['Micro-injection in progress'],
    'GLT Mice' => ['Genotype confirmed'],
    'Aborted' => ['Micro-injection aborted']
  }

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

    counter = 1
    report = Table(:data => cached_report.data,
      :column_names => ['Count'] + cached_report.column_names,
      :filters => lambda {|r|
        if r['Consortium'] == consortium && (column == 'all' || MAPPING1[column].include?(r.data['Status']))
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
        
    grouped_report.summary(
      'Consortium',
      'All'                => lambda { |group| count_unique_instances_of( group, 'Gene' ) },
      'Activity'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['activity'].include? row.data['Status'] } ) },
      'Mice in production' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['mip'].include? row.data['Status'] } ) },
      'GLT Mice'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['glt'].include? row.data['Status'] } ) },
      'Aborted'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['aborted'].include? row.data['Status'] } ) }
    ).each do |row|

      glt = Integer(row['GLT Mice'])
      total = Integer(row['GLT Mice']) + Integer(row['Aborted'])
      pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
      pc = "%.2f" % pc
            
      report_table << {        
        'Consortium' => row['Consortium'],
        'All' => row['All'].to_s != '0' ? "<a href='#{ROOT1}/consortium/#{row['Consortium']}/type/all'>#{row['All']}</a>" : '',
        'Activity' => row['Activity'].to_s != '0' ? "<a href='#{ROOT1}/consortium/#{row['Consortium']}/type/activity'>#{row['Activity']}</a>" : '',
        'Mice in production' => row['Mice in production'].to_s != '0' ? "<a href='#{ROOT1}/consortium/#{row['Consortium']}/type/mip'>#{row['Mice in production']}</a>" : '',
        'GLT Mice' => row['GLT Mice'].to_s != '0' ? "<a href='#{ROOT1}/consortium/#{row['Consortium']}/type/glt'>#{row['GLT Mice']}</a>" : '',
        'Aborted' => row['Aborted'].to_s != '0' ? "<a href='#{ROOT1}/consortium/#{row['Consortium']}/type/aborted'>#{row['Aborted']}</a>" : '',
        'Pipeline efficiency (%)' => pc
      }
    end
   
    report_table.sort_rows_by!( ['Consortium'] )
    
    return report_table
  end

  def self.subsummary2(params)
    specs = params[:specs]
    array = specs.split('/')
    raise "Invalid parameters (#{array.size})" if array.size != 6

    consortium = CGI.unescape array[1]
    column = CGI.unescape array[3]
    column = column.gsub(/^\#\s+/, "")
    priority = CGI.unescape array[5]
    raise "Invalid parameters: '#{array[0]}'" if array[0] != 'consortium' || array[2] != 'type' || array[4] != 'priority'

    cached_report = get_cached_report('mi_production_detail')

    genes = []
    
    puts "column: '#{column}'"
    puts "map: " + MAPPING2.inspect

    counter = 1
    report = Table(:data => cached_report.data,
      :column_names => ['Count'] + cached_report.column_names,
      :filters => lambda {|r|
        if r['Consortium'] == consortium && r['Priority'] == priority && (column == 'all' || MAPPING2[column].include?(r.data['Status']))
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

    title = "subsummary2: consortium: '#{consortium}' - type: '#{column}' - priority: '#{priority}' (#{report.size})"
    
    return title, report

  end
  
  def self.generate2
    cached_report = get_cached_report('mi_production_detail')

    report_table = Table( ['Consortium', 'Priority', 'All', 'ES QC started', 'ES QC finished', 'MI in progress', 'Aborted', 'GLT Mice', 'order_by'] )
 
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Priority' ] )
    
    grouped_report.each do |consortium|
      
      next if LIMIT_CONSORTIA && ! CONSORTIA.include?(consortium)
      
      summary = grouped_report.subgrouping(consortium).summary(
        'Priority',
        'All'            => lambda { |group| count_unique_instances_of( group, 'Gene' ) },
        'ES QC started'  => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING2['ES QC started'].include? row.data['Status'] } ) },
        'ES QC finished' => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING2['ES QC finished'].include? row.data['Status'] } ) },
        'MI in progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING2['MI in progress'].include? row.data['Status'] } ) },
        'GLT Mice'       => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING2['GLT Mice'].include? row.data['Status'] } ) },
        'Aborted'       => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING2['Aborted'].include? row.data['Status'] } ) }
      )
      
      p_found = []

      summary.each do |row|

        make_link = lambda {|key|
          row[key].to_s != '0' ?
          "<a title='Click to see list of #{key}!' href='#{ROOT2}/consortium/#{consortium}/type/#{key}/priority/#{row['Priority']}'>#{row[key]}</a>" :
          ''
        }

        p_found.push row['Priority']
        report_table << {
          'Consortium' => consortium,
          'Priority' => row['Priority'],
          'All' => make_link.call('All'),
          'ES QC started' => make_link.call('ES QC started'),
          'ES QC finished' => make_link.call('ES QC finished'),
          'MI in progress' => make_link.call('MI in progress'),
          'GLT Mice' => make_link.call('GLT Mice'),
          'Aborted' => make_link.call('Aborted'),
          'order_by' => ORDER_BY_MAP[row['Priority']]
        }
      end
      
      next if ! ADD_ALL_PRIORITIES
      
      p_remain = [ 'Low', 'Medium', 'High' ] - p_found
      p_remain.each do |priority|
        report_table << {
          'Consortium' => consortium,
          'Priority' => priority,
          'order_by' => ORDER_BY_MAP[priority]
        }
      end
      
    end
  
    report_table.sort_rows_by!( ['Consortium', 'order_by'] )    
    report_table.remove_column('order_by')
    return report_table
  end

end
