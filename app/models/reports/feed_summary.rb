# encoding: utf-8

class Reports::FeedSummary

  extend Reports::Helper

  LOSE_ABORTS = false
  ADD_COUNTS = false
  GENE_DISTINCT = true
  COMMON_COLUMNS = [
    '# Assigned - ES Cell QC In Progress',
    '# Assigned - ES Cell QC Complete',
    '# Micro-injection in progress',
    '# Genotype confirmed',
    '# Micro-injection aborted'
  ]
  MAIN_COLUMNS = [ 'Production Centre' ] + COMMON_COLUMNS
 
  def self.subfeed(params)
    specs = params[:specs]
    array = specs.split('/')
    raise "Invalid parameters (#{array.size})" if array.size != 4

    centre = CGI.unescape array[1]
    column = CGI.unescape array[3]
    column = column.gsub(/^\#\s+/, "")
    raise "Invalid parameters: '#{array[0]}'" if array[0] != 'centre' || array[2] != 'status'
    
    cached_report = get_cached_report('mi_production_detail')
    
    genes = []
    counter = 1

    @report = Table(:data => cached_report.data,
      :column_names => ADD_COUNTS ? ['Count'] + cached_report.column_names : cached_report.column_names,
      :filters => lambda {|r|
        if r['Production Centre'] == centre && r['Status'] == column
          return true if ! GENE_DISTINCT
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

    @title = "Simple Feed: Centre: #{centre} - Type: #{column} (#{@report.size})"
      
    return @title, @report
    
  end

  def self.clean_table(request, table, filter=true)    
    report = Table(:data => table.data,
      :column_names => table.column_names,
      :transforms => lambda {|r|
        COMMON_COLUMNS.each do |name|          
          tname = CGI.escape(name)
          cname = CGI.escape(r['Production Centre'])
          r[name] = r[name] == 0 ? '' : "<a href='#{request.env['SCRIPT_NAME']}/feeds/list/centre/#{cname}/status/#{tname}'>#{r[name]}</a>"
        end
      },
      :filters => lambda {|r| ! filter || (r['Production Centre'] && r['Production Centre'].length > 0) }
    )
    report.remove_column('# Micro-injection aborted') if LOSE_ABORTS
    return report
  end

  def self.generate(request)
    cached_report = get_cached_report('mi_production_detail')
      
    report_table = Table( MAIN_COLUMNS )

    grouped_report = Grouping( cached_report, :by => [ 'Production Centre' ], :order => [:name]  )

    grouped_report.summary(
      'Production Centre',
      '# Assigned - ES Cell QC In Progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| ((row.data['Status'] == 'Assigned - ES Cell QC In Progress')) ? true : false } ) },
      '# Assigned - ES Cell QC Complete' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| ((row.data['Status'] == 'Assigned - ES Cell QC Complete')) ? true : false } ) },
      '# Micro-injection in progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| ((row.data['Status'] == 'Micro-injection in progress')) ? true : false } ) },
      '# Genotype confirmed' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| ((row.data['Status'] == 'Genotype confirmed')) ? true : false } ) },
      '# Micro-injection aborted' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| ((row.data['Status'] == 'Micro-injection aborted')) ? true : false } ) }
    ).each do |row|
      report_table << {
        'Production Centre' => row['Production Centre'],
        '# Assigned - ES Cell QC In Progress' => row['# Assigned - ES Cell QC In Progress'],
        '# Assigned - ES Cell QC Complete' => row['# Assigned - ES Cell QC Complete'],
        '# Micro-injection in progress' => row['# Micro-injection in progress'],
        '# Genotype confirmed' => row['# Genotype confirmed'],
        '# Micro-injection aborted' => row['# Micro-injection aborted']
      }
    end
   
    report_table.sort_rows_by!( '# Genotype confirmed', :order => :descending )

    report = clean_table(request, report_table)
    
    return report
  end

end
