# encoding: utf-8

class Reports::MiProduction::SummaryKomp23

  extend Reports::MiProduction::SummariesCommon

  DEBUG = false
  DEBUG_SUBSUMMARY = true
  CACHE_NAME = 'mi_production_intermediate'
  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS
  REPORT_TITLE = 'KOMP2 Report 3'
  
  CONSORTIA = ['BaSH', 'DTCC', 'DTCC-Legacy', 'JAX']
  
  HEADINGS = ['Consortium', 'Production Centre',
    'All',
    'ES QC Failures',
    'ES QC confirmed',
    'ES QCs',
    'Genotype Confirmed',
    'MI Aborted',
    'MIs',
    'Chimaeras',
    'Phenotype Attempt Aborted',
    'Phenotyping Complete',
    'Phenotype data starts',
    'Cre Excision Complete',
    'Cre Excision Starts',
    'Rederivation Starts',
    'Rederivation Completes',
    'Phenotype Registrations',
    
    'Pipeline efficiency (%)',
    'Pipeline efficiency (by clone)'
  ]

  def self.efficiency(request, row)
    glt = integer(row['Genotype Confirmed'])
    glt2 = integer(row['Phenotyped Count'])
    glt += glt2
    failures = integer(row['Languishing']) + integer(row['MI Aborted'])
    total = integer(row['Genotype Confirmed']) + failures
    pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
    pc = pc != 0 ? "%i" % pc : request && request.format != :csv ? '' : 0
    return pc
  end

  def self.efficiency2(request, row)
    a = integer(row['Distinct Genotype Confirmed ES Cells'])
    b = integer(row['Distinct Old Non Genotype Confirmed ES Cells'])
    pc =  a + b != 0 ? ((a.to_f / (a + b).to_f) * 100) : 0
    pc = pc != 0 ? "%i" % pc : request && request.format != :csv ? '' : 0
    return pc
  end

  def self.languishing(row)
    label = 'Micro-injection in progress'
    date = 'Micro-injection in progress Date'
    return false if row.data['Overall Status'] != label
    today = Date.today
    return false if ! row[date] || row[date].length < 1
    before = Date.parse(row[date])
    return false if ! before
    gap = today - before
    return gap && gap > 180
  end
  
  def self.distinct_genotype_confirmed_es_cells(group)
    total = 0
    group.each do |row|
      value = integer(row['Distinct Genotype Confirmed ES Cells'])
      total += value
    end
    return total
  end

  def self.distinct_old_non_genotype_confirmed_es_cells(group)
    total = 0
    group.each do |row|
      value = integer(row['Distinct Old Non Genotype Confirmed ES Cells'])
      total += value
    end
    return total
  end

  def self.generate_common(request = nil, params={}, links = false)

    debug = params['debug'] && params['debug'].to_s.length > 0

#    cached_report = initialize
    cached_report = ReportCache.find_by_name!(CACHE_NAME).to_table
    
    script_name = request ? request.env['REQUEST_URI'] : ''

    heading = HEADINGS   
    heading.push 'Languishing' if debug #&& ! heading.include? 'Languishing'
    heading.push 'Distinct Genotype Confirmed ES Cells' if debug #&& ! heading.include? 'Distinct Genotype Confirmed ES Cells'
    heading.push 'Distinct Old Non Genotype Confirmed ES Cells' if debug #&& ! heading.include? 'Distinct Old Non Genotype Confirmed ES Cells'
    report_table = Table(heading)

    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )
    
    grouped_report.each do |consortium| 

      next if ! CONSORTIA.include?(consortium)
      
      grouped_report.subgrouping(consortium).summary('Production Centre', 
        'All' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| process_row(row, 'All') } ) },
        'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| process_row(row, 'ES QC confirmed') } ) },
        'MI Aborted' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'MI Aborted') } ) },
        
        'Languishing' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| languishing(row2) } ) },
        'Distinct Genotype Confirmed ES Cells' => lambda { |group| distinct_genotype_confirmed_es_cells(group) },
        'Distinct Old Non Genotype Confirmed ES Cells' => lambda { |group| distinct_old_non_genotype_confirmed_es_cells(group) },

        'Cre Excision Starts' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Cre Excision Starts') } ) },
        'Cre Excision Complete' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Cre Excision Complete') } ) },
        'Phenotyping Complete' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Phenotyping Complete') } ) },
        'Phenotype Attempt Aborted' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Phenotype Attempt Aborted') } ) },
        'ES QC Failures' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'ES QC Failures') } ) },
        'ES QCs' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'ES QCs') } ) },
        'Genotype Confirmed' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Genotype Confirmed') } ) },
        'MIs' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'MIs') } ) },
        'Phenotype data starts' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Phenotype data starts') } ) },
        'Cre Excision Complete' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Cre Excision Complete') } ) },
        'Rederivation Starts' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Rederivation Starts') } ) },
        'Rederivation Completes' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Rederivation Completes') } ) },
        'Phenotype Registrations' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Phenotype Registrations') } ) }
                
        ).each do |row|
        
        next if row['Production Centre'].to_s.length < 1

        pc = efficiency(request, row)
        pc2 = efficiency2(request, row)

        make_clean = lambda {|value|
          return value if request && request.format == :csv
          return '' if ! value || value.to_s == "0"
          return value
        }
        
        make_link = lambda {|rowx, key|
          return rowx[key] if request && request.format == :csv
          return '' if rowx[key].to_s.length < 1
          return '' if rowx[key] == 0
          return rowx[key] if ! links

          consort = CGI.escape consortium
          pcentre = CGI.escape rowx['Production Centre']
          pcentre = pcentre ? "&pcentre=#{pcentre}" : ''
          type = CGI.escape key
          separator = /\?/.match(script_name) ? '&' : '?'
          return "<a title='Click to see list of #{key}' href='#{script_name}#{separator}consortium=#{consort}#{pcentre}&type=#{type}'>#{rowx[key]}</a>"
        }
      
        report_table << {
          'Consortium' => consortium,
          'Production Centre' => row['Production Centre'],
          'All' => make_link.call(row, 'All'),
          'ES QC confirmed' => make_link.call(row, 'ES QC confirmed'),
          'MI Aborted' => make_link.call(row, 'MI Aborted'),
          'Languishing' => make_link.call(row, 'Languishing'),
          
          'Distinct Genotype Confirmed ES Cells' => make_link.call(row, 'Distinct Genotype Confirmed ES Cells'),
          'Distinct Old Non Genotype Confirmed ES Cells' => make_link.call(row, 'Distinct Old Non Genotype Confirmed ES Cells'),
          'Pipeline efficiency (%)' => make_clean.call(pc),
          'Pipeline efficiency (by clone)' => make_clean.call(pc2),
            
          'Cre Excision Started' => make_link.call(row, 'Cre Excision Started'),
          'Cre Excision Complete' => make_link.call(row, 'Cre Excision Complete'),
          'Phenotyping Complete' => make_link.call(row, 'Phenotyping Complete'),
          'Phenotype Attempt Aborted' => make_link.call(row, 'Phenotype Attempt Aborted'),
          
          'ES QC Failures' => make_link.call(row, 'ES QC Failures'),
          'ES QCs' => make_link.call(row, 'ES QCs'),
          'Genotype Confirmed' => make_link.call(row, 'Genotype Confirmed'),
          'MIs' => make_link.call(row, 'MIs'),
          'Phenotype data starts' => make_link.call(row, 'Phenotype data starts'),
          'Rederivation Completes' => make_link.call(row, 'Rederivation Completes'),
          'Phenotype Registrations' => make_link.call(row, 'Phenotype Registrations')
          
        }
        
      end
    end

    return report_table
  end
  
  def self.process_row(row, key)
    
    return true if key == 'All'
    
    if key == 'ES QC Failures'
      return row['MiPlan Status'] == 'Aborted - ES Cell QC Failed'
    end
    
    if key == 'ES QC confirmed'
      return row['MiPlan Status'] == 'Assigned - ES Cell QC Complete'
    end
    
    if key == 'ES QCs'
      return ['Assigned - ES Cell QC Complete', 'Assigned - ES Cell QC Complete', 'Aborted - ES Cell QC Failed'].include? row['MiPlan Status']
    end
    
    if key == 'Genotype Confirmed'
      #return true
      return row['MiAttempt Status'] == 'Genotype confirmed'
    end
    
    if key == 'MI Aborted'
      return row['MiAttempt Status'] == 'Micro-injection aborted'
    end
    
    if key == 'MIs'
      return row['MiAttempt Status'] == 'Micro-injection in progress' || row['MiAttempt Status'] == 'Genotype confirmed' ||
        row['MiAttempt Status'] == 'Micro-injection aborted'
    end
    
    if key == 'Phenotype Attempt Aborted'
      return row['PhenotypeAttempt Status'] == 'Phenotype Attempt Aborted'
    end
    
    if key == 'Phenotyping Complete'
      return row['PhenotypeAttempt Status'] == 'Phenotyping Complete'
    end
    
    if key == 'Phenotype data starts'
      return row['PhenotypeAttempt Status'] == 'Phenotyping Started' || row['PhenotypeAttempt Status'] == 'Phenotyping Complete'
    end
    
    if key == 'Cre Excision Complete'
      return row['PhenotypeAttempt Status'] == 'Cre Excision Complete' ||
        row['PhenotypeAttempt Status'] == 'Phenotyping Started' || row['PhenotypeAttempt Status'] == 'Phenotyping Complete' ||
        row['PhenotypeAttempt Status'] == 'Phenotyping Complete'
    end
    
    if key == 'Cre Excision Starts'
      return row['PhenotypeAttempt Status'] == 'Cre Excision Started' ||
        row['PhenotypeAttempt Status'] == 'Cre Excision Complete' ||
        row['PhenotypeAttempt Status'] == 'Phenotyping Started' || row['PhenotypeAttempt Status'] == 'Phenotyping Complete' ||
        row['PhenotypeAttempt Status'] == 'Phenotyping Complete'
    end
    
    valid_phenos2 = [
    'Rederivation Started',
    'Rederivation Complete',
    'Cre Excision Started',
    'Cre Excision Complete',
    'Phenotyping Started',
    'Phenotyping Complete'
    ]
    
    if key == 'Rederivation Starts'
      return valid_phenos2.include? row['PhenotypeAttempt Status'] && row['Rederivation Started Date'].to_s.length > 0
    end

    valid_phenos3 = [
    'Rederivation Complete',
    'Cre Excision Started',
    'Cre Excision Complete',
    'Phenotyping Started',
    'Phenotyping Complete'
    ]
    
    if key == 'Rederivation Completes'
      return valid_phenos3.include? row['PhenotypeAttempt Status'] && row['Rederivation Complete Date'].to_s.length > 0
    end
    
    if key == 'Phenotype Registrations'
      return row['PhenotypeAttempt Status'] == 'Phenotype Attempt Registered'
    end
  
    if key == 'Distinct Genotype Confirmed ES Cells'
      return row[key] && row[key].to_s.length > 0
    end
    
    if key == 'Distinct Old Non Genotype Confirmed ES Cells'
      return row[key] && row[key].to_s.length > 0
    end

    return languishing(row) if key == 'Languishing'

    return false
  
  end

  def self.integer(value)
    return Integer(value && value.to_s.length > 0 ? value : 0)
  end
  
  def self.subsummary_common(params)
    consortium = params[:consortium]
    type = params[:type]
    type = type ? type.gsub(/^\#\s+/, "") : nil
    priority = params[:priority]
    subproject = params[:subproject]    
    pcentre = params[:pcentre]    
#    debug = params['debug'] && params['debug'].to_s.length > 0
  
    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table
      
    report = Table(:data => cached_report.data,
      :column_names => cached_report.column_names,
      :filters => lambda {|r|
        
        return false if (r['Consortium'] != consortium || r['Production Centre'] != pcentre)

        return languishing(r) if type == 'Languishing'
        
        return process_row(r, type)
      
      },
      :transforms => lambda {|r|
        r['Mutation Sub-Type'] = fix_mutation_type r['Mutation Sub-Type']
      }
    )
    
    exclude_columns = [
      "MiPlan Status",
      "MiAttempt Status",
      "PhenotypeAttempt Status"
    ]
    
    exclude_columns.each do |name|
      report.remove_column name
    end
    
    consortium = consortium ? "Consortium: '#{consortium}' - " : ''
    pcentre = pcentre ? "Centre: '#{pcentre}' - " : ''
    type = type ? "Type: '#{type}' - " : ''
    
    report.rename_column 'Overall Status', 'Status'
    report.rename_column 'Mutation Sub-Type', 'Mutation Type'
  
    title = "Production Summary Detail"
    title = "Production Summary Detail: #{consortium}#{pcentre}#{type} (#{report.size})" if DEBUG_SUBSUMMARY
    
    return title, report
  end
  
  def self.generate(request = nil, params={})
    
    if params[:consortium]
      title, report = subsummary_common(params)
      rv = request && request.format == :csv ? report.to_csv : report.to_html
      return title, rv
    end

    report = generate_common(request, params, true)

    report.rename_column('All', 'All Genes')
  
    return REPORT_TITLE, request && request.format == :csv ? report.to_csv : report.to_html
  
  end
  
end
