# encoding: utf-8

class Reports::MiProduction::SummaryKomp23

  extend Reports::MiProduction::SummariesCommon

  DEBUG = false
  DEBUG_INTERMEDIATE = true
  CACHE_NAME = DEBUG ? 'mi_production_intermediate_test' : 'mi_production_intermediate'
  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS

    #keys2 = [
    #  'Phenotype Attempt Aborted',
    #  'ES QC started',
    #  'ES QC confirmed',
    #  'ES QC failed',
    #  'MI in progress',
    #  'MI Aborted',
    #  'Phenotyping Started',
    #  'Rederivation Started',
    #  'Rederivation Complete',
    #  'Cre Excision Started',
    #  'Cre Excision Complete',
    #  'Phenotyping Complete',
    #  'Phenotype Attempt Aborted'
    #]

#  MAPPING_SUMMARIES = {
##    'All' => [],
#    'ES QC started' => ['Assigned - ES Cell QC In Progress'],
#    'MI in progress' => ['Micro-injection in progress'],
#    
##    'MIs' => ['Micro-injection in progress', '', ''],
#
#    'Chimaeras' => [],
#    
#    'Genotype Confirmed Mice' => ['Genotype confirmed'],
#    'ES QC confirmed' => ['Assigned - ES Cell QC Complete'],
#    
#    'ES QC failed' => ['Aborted - ES Cell QC Failed'],
#    'MI Aborted' => ['Micro-injection aborted'],
#    'Phenotype Attempt Aborted' => ['Phenotype Attempt Aborted'],
#    
#    'Registered for Phenotyping' => ['Phenotype Attempt Registered'],
#    'Phenotyping Started' => ['Phenotyping Started'],
#    'Rederivation Started' => ['Rederivation Started'],
#    'Rederivation Complete' => ['Rederivation Complete'],
#    'Cre Excision Started' => ['Cre Excision Started'],
#    'Cre Excision Complete' => ['Cre Excision Complete'],
#    'Phenotyping Complete' => ['Phenotyping Complete']
#  }
  
  CONSORTIA = ['BaSH', 'DTCC', 'DTCC-Legacy', 'JAX']
  
  HEADINGS = ['Consortium', 'Production Centre',
    'All',
    'ES QC Failures',
    'ES QC confirmed',
    'ES QCs',
    
    'ES QC started',
    'MI in progress',
    'Chimaeras',
    'Genotype Confirmed Mice',
    'Registered for Phenotyping',
    'Phenotyping Started',
    'Rederivation Started',
    'Rederivation Complete',
    'Cre Excision Started',
    'Cre Excision Complete',
    'Phenotyping Complete',
    'ES QC failed',
    'MI Aborted',
    'Phenotype Attempt Aborted',
    'Pipeline efficiency (%)',
    'Pipeline efficiency (by clone)'
  ]

  def self.generate_common(request = nil, params={}, links = false)

    debug = params['debug'] && params['debug'].to_s.length > 0

    cached_report = initialize
    script_name = request ? request.env['REQUEST_URI'] : ''

    heading = HEADINGS   
    heading.push 'Languishing' if debug #&& ! heading.include? 'Languishing'
    heading.push 'Distinct Genotype Confirmed ES Cells' if debug #&& ! heading.include? 'Distinct Genotype Confirmed ES Cells'
    heading.push 'Distinct Old Non Genotype Confirmed ES Cells' if debug #&& ! heading.include? 'Distinct Old Non Genotype Confirmed ES Cells'
    report_table = Table(heading)

    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )
    
    grouped_report.each do |consortium| 

      next if ! CONSORTIA.include?(consortium)

      grouped_report.subgrouping(consortium).summary(

        'Production Centre',
        'All' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| process_row(row, 'All') } ) },
        'ES QC started' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| process_row(row, 'ES QC started') } ) },
        'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| process_row(row, 'ES QC confirmed') } ) },
        'ES QC failed' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| process_row(row, 'ES QC failed') } ) },
        'MI in progress' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2,'MI in progress') } ) },
        'Genotype Confirmed Mice' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| process_row(row, 'Genotype Confirmed Mice') } ) },
        'MI Aborted' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'MI Aborted') } ) },
        'Registered for Phenotyping' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Registered for Phenotyping') } ) },
        
        'Languishing' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| languishing(row2) } ) },
        'Distinct Genotype Confirmed ES Cells' => lambda { |group| distinct_genotype_confirmed_es_cells(group) },
        'Distinct Old Non Genotype Confirmed ES Cells' => lambda { |group| distinct_old_non_genotype_confirmed_es_cells(group) },

        'Phenotyping Started' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Phenotyping Started') } ) },
        'Rederivation Started' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Rederivation Started') } ) },
        'Rederivation Complete' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Rederivation Complete') } ) },
        'Cre Excision Started' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Cre Excision Started') } ) },
        'Cre Excision Complete' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Cre Excision Complete') } ) },
        'Phenotyping Complete' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Phenotyping Complete') } ) },
        'Phenotype Attempt Aborted' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'Phenotype Attempt Aborted') } ) },
        'ES QC Failures' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| process_row(row2, 'ES QC Failures') } ) }

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

        #make_efficiency1 = lambda {|rowx, pc|
        #    return "#{pc}</td>" if ! debug
        #    return " title='Calculated: glt / (glt + languishing) - #{rowx['Genotype Confirmed Mice']} / (#{rowx['Genotype Confirmed Mice']} + #{rowx['Languishing']})'>#{pc}</td>"
        #  }
        #  make_efficiency2 = lambda {|rowx, pc|
        #    return "<td>#{pc}</td>" if ! debug
        #    return "<td title='Calculated: Distinct Genotype Confirmed ES Cells / (Distinct Genotype Confirmed ES Cells + Distinct Old Non Genotype Confirmed ES Cells)" +
        #  " - #{rowx['Distinct Genotype Confirmed ES Cells']} / (#{rowx['Distinct Genotype Confirmed ES Cells']} + #{rowx['Distinct Old Non Genotype Confirmed ES Cells']})'>#{pc}</td>"
        #  }
      
        report_table << {
          'Consortium' => consortium,
          'Production Centre' => row['Production Centre'],
          'All' => make_link.call(row, 'All'),
          'ES QC started' => make_link.call(row, 'ES QC started'),
          'ES QC confirmed' => make_link.call(row, 'ES QC confirmed'),
          'ES QC failed' => make_link.call(row, 'ES QC failed'),
          'MI in progress' => make_link.call(row, 'MI in progress'),
          'Genotype Confirmed Mice' => make_link.call(row, 'Genotype Confirmed Mice'),
          'MI Aborted' => make_link.call(row, 'MI Aborted'),
          'Languishing' => make_link.call(row, 'Languishing'),
          'Registered for Phenotyping' => make_link.call(row, 'Registered for Phenotyping'),
          
          'Distinct Genotype Confirmed ES Cells' => make_link.call(row, 'Distinct Genotype Confirmed ES Cells'),
          'Distinct Old Non Genotype Confirmed ES Cells' => make_link.call(row, 'Distinct Old Non Genotype Confirmed ES Cells'),
          'Pipeline efficiency (%)' => make_clean.call(pc),
          'Pipeline efficiency (by clone)' => make_clean.call(pc2),
            
          'Phenotyping Started' => make_link.call(row, 'Phenotyping Started'),
          'Rederivation Started' => make_link.call(row, 'Rederivation Started'),
          'Rederivation Complete' => make_link.call(row, 'Rederivation Complete'),
          'Cre Excision Started' => make_link.call(row, 'Cre Excision Started'),
          'Cre Excision Complete' => make_link.call(row, 'Cre Excision Complete'),
          'Phenotyping Complete' => make_link.call(row, 'Phenotyping Complete'),
          'Phenotype Attempt Aborted' => make_link.call(row, 'Phenotype Attempt Aborted')
        }
        
      end
    end

    return report_table
  end
  
  def anchor(hash, value)
  end

  def csv_line(consortium, centre, gene, status)
    gene_status_template = '"CONSORTIUM-TARGET",,"High","CENTRE-TARGET","GENE-TARGET","MGI:1921546","STATUS-TARGET","Assigned - ES Cell QC In Progress",,,,,,,10/10/11,16/11/11,,,,,,,,,,,,,0,0'
    template = gene_status_template
    template = template.gsub(/CONSORTIUM-TARGET/, consortium)
    template = template.gsub(/CENTRE-TARGET/, centre)
    template = template.gsub(/GENE-TARGET/, gene)
    template = template.gsub(/STATUS-TARGET/, status)
    return template
  end
  
  def self.initialize

    if DEBUG
      report = ReportCache.find_by_name(CACHE_NAME)

      heading = '"Consortium","Sub-Project","Priority","Production Centre","Gene","MGI Accession ID","Overall Status","MiPlan Status","MiAttempt Status","PhenotypeAttempt Status","IKMC Project ID","Mutation Sub-Type","Allele Symbol","Genetic Background","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date","Phenotype Attempt Registered Date","Rederivation Started Date","Rederivation Complete Date","Cre Excision Started Date","Cre Excision Complete Date","Phenotyping Started Date","Phenotyping Complete Date","Phenotype Attempt Aborted Date"'
  
      csv = heading + "\n"

      ignore = [
        'Consortium',
        'Production Centre',
        'Pipeline efficiency (%)',
        'Pipeline efficiency (by clone)'
      ]

      (HEADINGS.size-1).downto(1).each do |i|
        next if (['All'] + ignore).include? HEADINGS[i]
        csv += csv_line('BaSH', 'BCM', 'abc' + i.to_s, MAPPING_SUMMARIES[HEADINGS[i]][0]) + "\n"
        csv += csv_line('BaSH', 'MRC - Harwell', 'abc' + i.to_s, MAPPING_SUMMARIES[HEADINGS[i]][0]) + "\n"
        csv += csv_line('BaSH', 'WTSI', 'abc' + i.to_s, MAPPING_SUMMARIES[HEADINGS[i]][0]) + "\n"
        csv += csv_line('DTCC', 'TCP', 'abc' + i.to_s, MAPPING_SUMMARIES[HEADINGS[i]][0]) + "\n"
        csv += csv_line('DTCC', 'UCD', 'abc' + i.to_s, MAPPING_SUMMARIES[HEADINGS[i]][0]) + "\n"
        csv += csv_line('JAX', 'JAX', 'abc' + i.to_s, MAPPING_SUMMARIES[HEADINGS[i]][0]) + "\n"
      end

      if report
        report.csv_data = csv
        report.save!
      else
        ReportCache.create!(
          :name => CACHE_NAME,
          :csv_data => csv
        )
      end
    end

    report = ReportCache.find_by_name!(CACHE_NAME).to_table
    
    return report
  end

  def self.process_row(row, key)
    
    #TODO: fix me!
    #keys2 = [
    #  'Phenotype Attempt Aborted',
    #  'ES QC started',
    #  'ES QC confirmed',
    #  'ES QC failed',
    #  'MI in progress',
    #  'MI Aborted',
    #  'Phenotyping Started',
    #  'Rederivation Started',
    #  'Rederivation Complete',
    #  'Cre Excision Started',
    #  'Cre Excision Complete',
    #  'Phenotyping Complete',
    #  'Phenotype Attempt Aborted'
    #]
    #
    #return MAPPING_SUMMARIES[key].include? row.data['Overall Status'] if keys2.include? key
    
   # return MAPPING_SUMMARIES[key].include? row.data['Overall Status'] if MAPPING_SUMMARIES[key]

    return true if key == 'All'
    
    if key == 'ES QC Failures'
      return row['MiPlan Status'] == 'Aborted - ES Cell QC Failed'
    end
    
    if key == 'ES QC confirmed'
      return row['MiPlan Status'] == 'Assigned - ES Cell QC Complete'
    end
    
    if key == 'ES QCs'
      return row['MiPlan Status'] == 'Assigned - ES Cell QC Complete' ||
        row['MiPlan Status'] == 'Assigned - ES Cell QC Complete' ||
        row['MiPlan Status'] == 'Aborted - ES Cell QC Failed'
    end
    
    return false
    #return     (MAPPING_SUMMARIES['Genotype Confirmed Mice'].include?(row.data['Overall Status'])) ||
    #  ((MAPPING_SUMMARIES['Registered for Phenotyping'].include? row.data['Overall Status']) &&
    #    (row.data['Genotype confirmed Date'] && row.data['Genotype confirmed Date'].to_s.length > 0)) if key == 'Genotype Confirmed Mice'
    #
    #return (row && row['PhenotypeAttempt Status'] && row['PhenotypeAttempt Status'].to_s.length > 1 || MAPPING_SUMMARIES['Registered for Phenotyping'].include?(row.data['Overall Status'])) if key == 'Registered for Phenotyping'
    #
    #return integer(row[key]) > 0 if key == 'Distinct Genotype Confirmed ES Cells'
    #
    #return integer(row[key]) > 0 if key == 'Distinct Old Non Genotype Confirmed ES Cells'
    #
    #raise "process_row: invalid key detected '#{key}'"
  end

  def self.integer(value)
    return Integer(value && value.to_s.length > 0 ? value : 0)
  end
  
  def self.prettify_table(table)
    centres = {}
    sub_table = table.sub_table { |r|
      centres[r["Consortium"]] ||= []
      centres[r["Consortium"]].push r['Production Centre']
    }

    #grouped_report = Grouping( table, :by => [ 'Consortium', 'Production Centre' ] )
    #
    #summary = grouped_report.summary(
    #  'Consortium',
    #  'All' => lambda { |group| count_instances_of( group, 'Gene',
    #        lambda { |row| all(row) } ) },
    #  'ES QC started' => lambda { |group| count_instances_of( group, 'Gene',
    #      lambda { |row| MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status'] } ) },
    #  'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
    #      lambda { |row| MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status'] } ) },
    #  'ES QC failed' => lambda { |group| count_instances_of( group, 'Gene',
    #      lambda { |row| MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status'] } ) }
    #)
    
    summaries = {}
      #
      #table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'All')}</td>"
      #table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'ES QC started')}</td>"
      #table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'ES QC confirmed')}</td>"
      #table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'ES QC failed')}</td>"
      #
      
    table.sum { |r|
      CONSORTIA.each do |name|
        summaries[name] ||= {}
        summaries[name]['All'] ||= 0
        summaries[name]['ES QC started'] ||= 0
        summaries[name]['ES QC confirmed'] ||= 0
        summaries[name]['ES QC failed'] ||= 0

        summaries[name]['All'] += integer(r['All'])
        summaries[name]['ES QC started'] += integer(r['ES QC started'])
        summaries[name]['ES QC confirmed'] += integer(r['ES QC confirmed'])
        summaries[name]['ES QC failed'] += integer(r['ES QC failed'])
      end
      0
    }

    array = []
    array.push '<table>'
    array.push '<tr>'
    table.column_names.each do |name|
      array.push "<th>#{name}</th>"
    end
    array.push '</tr>'

    rows = table.column('Consortium').size - 1
    for i in (0..rows)
      array.push '<tr>'
      table.column_names.each do |name|
        array.push "<td>#{table.column(name)[i]}</td>"
      end
      array.push '</tr>'
    end
    
    array.push '</table>'
    return array.join("\n")
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
        
        ##TODO: fix this
        #
        #if ! /Languishing/.match(type)
        #  return r['Consortium'] == consortium &&
        #    (pcentre.nil? || r['Production Centre'] == pcentre) &&
        #    (priority.nil? || r['Priority'] == priority) &&
        #    (type.nil? || (type == 'All' && all(r)) || (type == 'Registered for Phenotyping' && registered_for_phenotyping(r)) || MAPPING_SUMMARIES[type].include?(r.data['Overall Status'])) &&
        #    (subproject.nil? || r['Sub-Project'] == subproject)
        #else
        #  return r['Consortium'] == consortium &&
        #    (pcentre.nil? || r['Production Centre'] == pcentre) &&
        #    (priority.nil? || r['Priority'] == priority) &&
        #    (subproject.nil? || r['Sub-Project'] == subproject) &&
        #    languishing(r) if type == 'Languishing'
        #  return r['Consortium'] == consortium &&
        #    (pcentre.nil? || r['Production Centre'] == pcentre) &&
        #    (priority.nil? || r['Priority'] == priority) &&
        #    (subproject.nil? || r['Sub-Project'] == subproject) &&
        #    languishing2(r) if type == 'Languishing2'
        #end

        keys2 = [
          'Phenotype Attempt Aborted',
          'ES QC started',
          'ES QC confirmed',
          'ES QC failed',
          'MI in progress',
          'MI Aborted',
          'Phenotyping Started',
          'Rederivation Started',
          'Rederivation Complete',
          'Cre Excision Started',
          'Cre Excision Complete',
          'Phenotyping Complete',
          'Phenotype Attempt Aborted'
        ]

        return false if (r['Consortium'] != consortium || r['Production Centre'] != pcentre)

        #return MAPPING_SUMMARIES[type].include?(r.data['Overall Status']) if keys2.include? type
        #
        #return true if type == 'All'
        #
        #return     (MAPPING_SUMMARIES['Genotype Confirmed Mice'].include?(r.data['Overall Status'])) ||
        #  ((MAPPING_SUMMARIES['Registered for Phenotyping'].include? r.data['Overall Status']) &&
        #    (r.data['Genotype confirmed Date'] && r.data['Genotype confirmed Date'].to_s.length > 0)) if type == 'Genotype Confirmed Mice'
        #
        #return (r && r['PhenotypeAttempt Status'] && r['PhenotypeAttempt Status'].to_s.length > 1 ||
        #  MAPPING_SUMMARIES['Registered for Phenotyping'].include?(r.data['Overall Status'])) if type == 'Registered for Phenotyping'
        #
        #return languishing(r) if type == 'Languishing'
        #
        #return false

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
    title = "Production Summary Detail: #{consortium}#{pcentre}#{type} (#{report.size})" if DEBUG_INTERMEDIATE
    
    return title, report
  end

  CSV_LINKS = Reports::MiProduction::SummaryKomp2Common::CSV_LINKS  
  REPORT_TITLE = 'KOMP2 Report 3'
  
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
