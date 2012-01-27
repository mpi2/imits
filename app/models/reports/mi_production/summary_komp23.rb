# encoding: utf-8

class Reports::MiProduction::SummaryKomp23

  extend Reports::MiProduction::SummariesCommon

  DEBUG = false
  DEBUG_COLUMNS = true
  CACHE_NAME = 'mi_production_intermediate'
  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS
  REPORT_TITLE = 'KOMP2 Report 3'
  
  CONSORTIA = ['BaSH', 'DTCC', 'JAX']

  DEBUG_HEADINGS = [
    'Genotype Confirmed 6 months',
    'MI Aborted 6 months',
    'Languishing',
    'Distinct Genotype Confirmed ES Cells',
    'Distinct Old Non Genotype Confirmed ES Cells'
  ]

  HEADINGS = [
    'Consortium',
    'Production Centre',
    'All',
    'ES QC Failures',
    'ES QC confirms',
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
    'Gene Pipeline efficiency (%)',
    'Clone Pipeline efficiency (%)'
  ] + DEBUG_HEADINGS

  #def self.efficiency_6months(request, row)
  #  glt = integer(row['Genotype Confirmed 6 months'])
  #  failures = integer(row['Languishing']) + integer(row['MI Aborted'])
  #  total = glt + failures
  #  pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
  #  pc = pc != 0 ? "%i" % pc : request && request.format != :csv ? '' : 0
  #  return pc
  #end
  
  def self.efficiency_6months(request, row)
    glt = integer(row['Genotype Confirmed 6 months'])
    failures = integer(row['Languishing']) + integer(row['MI Aborted 6 months'])
    total = glt + failures
    pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
    pc = pc != 0 ? "%i" % pc : request && request.format != :csv ? '' : 0
    return pc
  end
  
  def self.efficiency_clone(request, row)
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
    return false if row[date].blank?
    before = Date.parse(row[date])
    return false if ! before
    return before < 6.months.ago.to_date
  end
  
  def self.genotype_confirmed_6month(row)
    date = 'Genotype confirmed Date'
    today = Date.today
    return false if row[date].blank?
    date = 'Micro-injection in progress Date'
    before = Date.parse(row[date])    
    return before < 6.months.ago.to_date
  end

  def self.distinct_genotype_confirmed_es_cells_count(group)
    total = 0
    group.each do |row|
      value = integer(row['Distinct Genotype Confirmed ES Cells'])
      total += value
    end
    return total
  end

  def self.distinct_old_non_genotype_confirmed_es_cells_count(group)
    total = 0
    group.each do |row|
      value = integer(row['Distinct Old Non Genotype Confirmed ES Cells'])
      total += value
    end
    return total
  end

  def self.generate_common(request = nil, params={}, links = false, limit_consortia = true)

    debug = params['debug'] && params['debug'].to_s.length > 0
    pretty = params['pretty'] && params['pretty'].to_s.length > 0
    
    links = pretty ? false : links

    cached_report = ReportCache.find_by_name!(CACHE_NAME).to_table
    
    script_name = request ? request.env['REQUEST_URI'] : ''

    heading = HEADINGS   
    report_table = Table(heading)

    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )

    list_heads = [
      'All', 
      'ES QC confirms', 
      'MI Aborted', 
      'Cre Excision Starts', 
      'Cre Excision Complete', 
      'Phenotyping Complete', 
      'Phenotype Attempt Aborted', 
      'ES QC Failures', 
      'ES QCs', 
      'Genotype Confirmed', 
      'MIs', 
      'Phenotype data starts', 
      'Cre Excision Complete', 
      'Rederivation Starts', 
      'Rederivation Completes', 
      'Phenotype Registrations', 
      'Genotype Confirmed 6 months',
      'MI Aborted 6 months'
    ]
    
    hash = {}
    hash['Languishing'] = lambda { |group| count_instances_of( group, 'Gene', lambda { |row2| languishing(row2) } ) }
    hash['Distinct Genotype Confirmed ES Cells'] = lambda { |group| distinct_genotype_confirmed_es_cells_count(group) }
    hash['Distinct Old Non Genotype Confirmed ES Cells'] = lambda { |group| distinct_old_non_genotype_confirmed_es_cells_count(group) }    
    list_heads.each do |item|
      hash[item] = lambda { |group| count_instances_of( group, 'Gene', lambda { |row| count_row(row, item) } ) }
    end
    
    grouped_report.each do |consortium| 

      next if limit_consortia && ! CONSORTIA.include?(consortium)
      
      grouped_report.subgrouping(consortium).summary('Production Centre', hash).each do |row|
        
        next if row['Production Centre'].to_s.length < 1

        pc = efficiency_6months(request, row)
        pc2 = efficiency_clone(request, row)

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
        
        list_heads = [
          'All',
          'ES QC confirms',
          'MI Aborted',
          'Languishing',
          'Distinct Genotype Confirmed ES Cells',
          'Distinct Old Non Genotype Confirmed ES Cells',
          'Cre Excision Started',
          'Cre Excision Complete',
          'Phenotyping Complete',
          'Phenotype Attempt Aborted',
          'ES QC Failures',
          'ES QCs',
          'Genotype Confirmed',
          'MIs',
          'Phenotype data starts',
          'Rederivation Starts',
          'Cre Excision Starts',
          'Rederivation Completes',
          'Phenotype Registrations',
          'Genotype Confirmed 6 months',
          'MI Aborted 6 months'
        ]

        new_hash = {}
        new_hash['Consortium'] = consortium
        new_hash['Production Centre'] = row['Production Centre']
        new_hash['Gene Pipeline efficiency (%)'] = make_clean.call(pc)
        new_hash['Clone Pipeline efficiency (%)'] = make_clean.call(pc2)
        list_heads.each do |item|
          new_hash[item] = make_link.call(row, item)
        end
      
        report_table << new_hash
        
      end
    end

    return report_table
  end
  
  def self.count_row(row, key)
    
    return true if key == 'All'
    
    if key == 'ES QC Failures'
      return row['MiPlan Status'] == 'Aborted - ES Cell QC Failed'
    end
    
    if key == 'ES QC confirms'
      return row['MiPlan Status'] == 'Assigned - ES Cell QC Complete'
    end
    
    if key == 'ES QCs'
      return ['Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Aborted - ES Cell QC Failed'].include?(row['MiPlan Status'])
    end
    
    if key == 'Genotype Confirmed'
      return row['MiAttempt Status'] == 'Genotype confirmed'
    end
    
    if key == 'Genotype Confirmed 6 months'
      return row['MiAttempt Status'] == 'Genotype confirmed' && genotype_confirmed_6month(row)
    end
    
    if key == 'MI Aborted'
      return row['MiAttempt Status'] == 'Micro-injection aborted'
    end
    
    if key == 'MI Aborted 6 months'
      return row['MiAttempt Status'] == 'Micro-injection aborted' && Date.parse(row['Micro-injection aborted Date']) < 6.months.ago.to_date
    end
    
    #today = Date.today
    #return false if row[date].blank?
    #before = Date.parse(row[date])
    #return false if ! before
    #return before < 6.months.ago.to_date
    
    
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
      return valid_phenos2.include?(row['PhenotypeAttempt Status']) && row['Rederivation Started Date'].to_s.length > 0
    end

    valid_phenos3 = [
      'Rederivation Complete',
      'Cre Excision Started',
      'Cre Excision Complete',
      'Phenotyping Started',
      'Phenotyping Complete'
    ]
    
    if key == 'Rederivation Completes'
      return valid_phenos3.include?(row['PhenotypeAttempt Status']) && row['Rederivation Complete Date'].to_s.length > 0
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
  
  def self.subsummary(params)
    consortium = params[:consortium]
    type = params[:type]
    type = type ? type.gsub(/^\#\s+/, "") : nil
    priority = params[:priority]
    subproject = params[:subproject]    
    pcentre = params[:pcentre]    
    details = params['details'] && params['details'].to_s.length > 0
  
    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table
      
    report = Table(:data => cached_report.data,
      :column_names => cached_report.column_names,
      :filters => lambda {|r|
        
        return false if r['Consortium'] != consortium
        return false if pcentre && pcentre.to_s.length > 0 && r['Production Centre'] != pcentre
        
        # deliberately ignore anything without a production centre
        
        return false if ! r['Production Centre'] || r['Production Centre'].to_s.length < 1

        return languishing(r) if type == 'Languishing'

        return r[type] && r[type].to_s.length > 0 && r[type].to_i != 0 if type == 'Distinct Genotype Confirmed ES Cells'
        return r[type] && r[type].to_s.length > 0 && r[type].to_i != 0 if type == 'Distinct Old Non Genotype Confirmed ES Cells'
        
        return count_row(r, type)
      
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
    title = "Production Summary Detail: #{consortium}#{pcentre}#{type} (#{report.size})" if details
    
    return title, report
  end
  
  def self.generate(request = nil, params={}, limit_consortia = true)
    
    if params[:consortium]
      title, report = subsummary(params)
      rv = request && request.format == :csv ? report.to_csv : report.to_html
      return title, rv
    end
    
    details = params['details'] && params['details'].to_s.length > 0
    do_table = params['table'] && params['table'].to_s.length > 0
    pretty = true

    report = generate_common(request, params, false, limit_consortia)

    report.rename_column('All', 'All Genes')
  
    new_columns = [
      "Consortium",
      "All Genes",
      "ES QCs",
      "ES QC confirms",
      "ES QC Failures",
      "Production Centre",
      "MIs",
      "Chimaeras",
      "Genotype Confirmed",
      "MI Aborted",
      "Gene Pipeline efficiency (%)",
      "Clone Pipeline efficiency (%)",
      "Phenotype Registrations",
      "Rederivation Starts",
      "Rederivation Completes",
      "Cre Excision Starts",
      "Cre Excision Complete",
      "Phenotype data starts",
      "Phenotyping Complete",
      "Phenotype Attempt Aborted",
    ] + (details ? DEBUG_HEADINGS : [])

    report.reorder(new_columns)
    
    title = limit_consortia ? REPORT_TITLE : 'Production for IMPC Consortia'
    
    return title, report if do_table

    html = pretty ? prettify_table(request, report) : report.to_html
    return title, request && request.format == :csv ? report.to_csv : html
  
  end

  def self.prettify_table(request, table)

    script_name = request ? request.env['REQUEST_URI'] : ''

    centres = {}
    sub_table = table.sub_table { |r|
      centres[r["Consortium"]] ||= []
      centres[r["Consortium"]].push r['Production Centre'] if ! centres[r["Consortium"]].include?(r['Production Centre'])
    }

    summaries = {}
    grouped_report = Grouping( table, :by => [ 'Consortium' ] )
    labels = ['All Genes', 'ES QCs', 'ES QC confirms', 'ES QC Failures']
              
    grouped_report.each do |consortium|
      summaries[consortium] = {}
      labels.each { |item| summaries[consortium][item] = grouped_report[consortium].sigma(item) }
    end

    array = []
    array.push '<table>'
    array.push '<tr>'
        
    table.column_names.each do |name|
      array.push "<th>#{name}</th>"
    end

    other_columns = table.column_names - ["Consortium", "All Genes", "ES QCs", "ES QC confirms",  "ES QC Failures"]
    rows = table.data.size 

    make_link = lambda {|value, consortium, pcentre, type|
      return '' if value.to_s.length < 1
      return '' if value == 0
    
      consortium = CGI.escape consortium
      pcentre = pcentre ? CGI.escape(pcentre) : ''
      #      otype = type
      type = CGI.escape type
      separator = /\?/.match(script_name) ? '&' : '?'
      #      return "<a title='Click to see list of #{otype}' href='#{script_name}#{separator}consortium=#{consortium}&pcentre=#{pcentre}&type=#{type}'>#{value}</a>"
      return "<a href='#{script_name}#{separator}consortium=#{consortium}&pcentre=#{pcentre}&type=#{type}'>#{value}</a>"
    }

    #make_efficiency1 = lambda {|rowx, pc|
    #    return "<td>#{pc}</td>" if ! debug
    #    return "<td title='Calculated: glt / (glt + languishing) - #{rowx['Genotype Confirmed Mice']} / (#{rowx['Genotype Confirmed Mice']} + #{rowx['Languishing']})'>#{pc}</td>"
    #}
    #make_efficiency2 = lambda {|rowx, pc|
    #    return "<td>#{pc}</td>" if ! debug
    #    return "<td title='Calculated: Distinct Genotype Confirmed ES Cells / (Distinct Genotype Confirmed ES Cells + Distinct Old Non Genotype Confirmed ES Cells)" +
    #  " - #{rowx['Distinct Genotype Confirmed ES Cells']} / (#{rowx['Distinct Genotype Confirmed ES Cells']} + #{rowx['Distinct Old Non Genotype Confirmed ES Cells']})'>#{pc}</td>"
    #}
    
    grouped_report.each do |consortium_name1|
      array.push '</tr>'
      array.push "<td rowspan='#{centres[consortium_name1].size.to_s}'>#{consortium_name1}</td>"
      array.push "<td rowspan='#{centres[consortium_name1].size.to_s}'>" + make_link.call(summaries[consortium_name1]['All Genes'], consortium_name1, nil, 'All') + "</td>"
      array.push "<td rowspan='#{centres[consortium_name1].size.to_s}'>" + make_link.call(summaries[consortium_name1]['ES QCs'], consortium_name1, nil, 'ES QCs') + "</td>"
      array.push "<td rowspan='#{centres[consortium_name1].size.to_s}'>" + make_link.call(summaries[consortium_name1]['ES QC confirms'], consortium_name1, nil, 'ES QC confirms') + "</td>"
      array.push "<td rowspan='#{centres[consortium_name1].size.to_s}'>" + make_link.call(summaries[consortium_name1]['ES QC Failures'], consortium_name1, nil, 'ES QC Failures') + "</td>"

      i=0
      while i < rows
        
        if table.column('Consortium')[i] != consortium_name1
          i+=1
          next
        end
        
        ignore_columns = ['Production Centre', 'Gene Pipeline efficiency (%)', 'Clone Pipeline efficiency (%)']
        
        other_columns.each do |consortium_name2|
          array.push "<td>#{table.column(consortium_name2)[i]}</td>" if ignore_columns.include?(consortium_name2)
          next if ignore_columns.include?(consortium_name2)
          array.push "<td>" + make_link.call(table.column(consortium_name2)[i], consortium_name1, table.column('Production Centre')[i], consortium_name2) + "</td>"
        end

        array.push '</tr>'
        
        i+=1
      
      end
      
    end  
    
    array.push '</table>'
    return array.join("\n")
  end
  
end
