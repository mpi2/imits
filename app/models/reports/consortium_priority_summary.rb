# encoding: utf-8

class Reports::ConsortiumPrioritySummary

  extend Reports::Helper
  extend ActionView::Helpers::UrlHelper
  
  CSV_LINKS = true  
  ADD_COUNTS = false
  LIMIT_CONSORTIA = false
  ADD_ALL_PRIORITIES = false
  CONSORTIA = [ 'BaSH', 'DTCC', 'Helmholtz GMC', 'JAX', 'MARC', 'MGP', 'Monterotondo', 'NorCOMM2', 'Phenomin', 'RIKEN BRC' ]
  ORDER_BY_MAP = { 'Low' => 1, 'Medium' => 2, 'High' => 3}
  MAPPING1 = {
    'All' => ['Interest',
              'Assigned - ES Cell QC In Progress',
              'Assigned - ES Cell QC Complete',
              'Micro-injection in progress',
              'Assigned',
              'Inspect - MI Attempt',
              'Conflict',
              'Genotype confirmed',
              'Inspect - Conflict',
              'Inspect - GLT Mouse'],
    'Activity' => ['Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Micro-injection in progress', 'Genotype confirmed'],
    'Mice in production' => ['Micro-injection in progress', 'Genotype confirmed'],
    'GLT Mice' => ['Genotype confirmed'],
    'Aborted' => ['Micro-injection aborted']
  }
  MAPPING2 = {
    'ES QC started' => ['Assigned - ES Cell QC In Progress'],
    'ES QC finished' => ['Assigned - ES Cell QC Complete'],
    'MI in progress' => ['Micro-injection in progress'],
    'GLT Mice' => ['Genotype confirmed'],
    'Aborted' => ['Micro-injection aborted']
  }

  def self.subsummary1(params)
    consortium = params[:consortium]
    status = params[:type]

    cached_report = get_cached_report('mi_production_detail')

    genes = []

    counter = 1
    report = Table(:data => cached_report.data,
      :column_names => ADD_COUNTS ? ['Count'] + cached_report.column_names : cached_report.column_names,
      :filters => lambda {|r|
        if r['Consortium'] == consortium && MAPPING1[status].include?(r.data['Status'])
          return false if genes.include?(r['Gene'])
          genes.push r['Gene']
          return true
        end
      },
      :transforms => lambda {|r|
        return if ! ADD_COUNTS
        r['Count'] = counter
        counter += 1
      }
    )

    title = "Production Summary 1 Detail: Consortium: #{consortium} - Type: #{status} (#{report.size})"
    
    return title, report

  end
  
  def self.generate1(request = nil, params = {})

    if params[:consortium]
      return subsummary1(params)
    end
    
    script_name = request ? request.env['REQUEST_URI'] : ''
  
    cached_report = get_cached_report('mi_production_detail')

    report_table = Table( [ 'Consortium', 'All', 'Activity', 'Mice in production', 'GLT Mice' ] )
   
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Priority' ] )
        
    grouped_report.summary(
      'Consortium',
      'All'                => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['All'].include? row.data['Status'] } ) },
      'Activity'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Activity'].include? row.data['Status'] } ) },
      'Mice in production' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Mice in production'].include? row.data['Status'] } ) },
      'GLT Mice'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['GLT Mice'].include? row.data['Status'] } ) },
      'Aborted'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Aborted'].include? row.data['Status'] } ) }
    ).each do |row|
            
      make_link = lambda {|key|
        consortium = CGI.escape row['Consortium']
        type = CGI.escape key
        row[key].to_s != '0' ?
        "<a title='Click to see list of #{key}' href='#{script_name}?consortium=#{consortium}&type=#{type}'>#{row[key]}</a>" :
        ''
      }

      report_table << {        
        'Consortium' => row['Consortium'],
        'All' => make_link.call('All'),
        'Activity' => make_link.call('Activity'),
        'Mice in production' => make_link.call('Mice in production'),
        'GLT Mice' => make_link.call('GLT Mice')
      }
    end
   
    report_table.sort_rows_by!( ['Consortium'] )
    
    return 'Production Summary 1 (feed)', report_table
  end
  
  def self.subsummary2(params)
    consortium = params[:consortium]
    column = params[:type]
    column = column.gsub(/^\#\s+/, "")
    priority = CGI.unescape params[:priority]

    cached_report = get_cached_report('mi_production_detail')

    genes = []
    counter = 1
    report = Table(:data => cached_report.data,
      :column_names => ADD_COUNTS ? ['Count'] + cached_report.column_names : cached_report.column_names,
      :filters => lambda {|r|
        if r['Consortium'] == consortium && r['Priority'] == priority && (column == 'All' || MAPPING2[column].include?(r.data['Status']))
          return false if genes.include?(r['Gene'])
          genes.push r['Gene']
          return true
        end
      },
      :transforms => lambda {|r|
        return if ! ADD_COUNTS
        r['Count'] = counter
        counter += 1
      }
    )

    title = "Production Summary Detail 2: Consortium: #{consortium} - Type: #{column} - Priority: #{priority} (#{report.size})"
    
    return title, report

  end
  
  def self.generate2(request = nil, params={})

    if params[:consortium]
      return subsummary2(params)
    end

    script_name = request ? request.env['REQUEST_URI'] : ''

    cached_report = get_cached_report('mi_production_detail')

    report_table = Table( ['Consortium', 'Priority', 'All', 'ES QC started', 'ES QC finished', 'MI in progress', 'Aborted', 'GLT Mice', 'Pipeline efficiency (%)', 'order_by'] )
 
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
          return row[key] if request && request.format == :csv
          consort = CGI.escape consortium
          type = CGI.escape key
          priority = CGI.escape row['Priority']
          row[key].to_s != '0' ?
          "<a title='Click to see list of #{key}' href='#{script_name}?consortium=#{consort}&type=#{key}&priority=#{priority}'>#{row[key]}</a>" :
          ''
        }

        glt = Integer(row['GLT Mice'])
        total = Integer(row['GLT Mice']) + Integer(row['Aborted'])
        pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
        pc = pc != 0 ? "%.2f" % pc : request && request.format != :csv ? '' : 0

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
          'Pipeline efficiency (%)' => pc,
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
        
    return 'Production Summary 2', report_table
  end

end
