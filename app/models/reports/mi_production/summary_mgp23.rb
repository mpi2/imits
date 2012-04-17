# encoding: utf-8

class Reports::MiProduction::SummaryMgp23
  extend Reports::MiProduction::SummariesCommon

  CACHE_NAME = 'mi_production_intermediate'
  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS
  REPORT_TITLE = 'MGP Production Summary'

  CONSORTIA = ['MGP']

  DEBUG_HEADINGS = [
    'Genotype confirmed mice 6 months',
    'Microinjection aborted 6 months',
    'Languishing',
    'Distinct Genotype Confirmed ES Cells',
    'Distinct Old Non Genotype Confirmed ES Cells'
  ]

  HEADINGS = [
    'Sub-Project',
    'All genes',
    'ES QC failed',
    'ES QC confirmed',
    'ES cell QC',
    'Genotype confirmed mice',
    'Microinjection aborted',
    'Microinjections',
    'Chimaeras produced',
    'Phenotyping aborted',
    'Phenotyping completed',
    'Phenotyping started',
    'Cre excision completed',
    'Cre excision started',
    'Rederivation started',
    'Rederivation completed',
    'Registered for phenotyping',

    'Gene Pipeline efficiency (%)',
    'Clone Pipeline efficiency (%)'
  ] + DEBUG_HEADINGS

  def self.efficiency_6months(params, row)
    glt = row['Genotype confirmed mice 6 months'].to_i
    failures = row['Languishing'].to_i + row['Microinjection aborted 6 months'].to_i
    total = glt + failures
    pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
    pc = pc != 0 ? "%i" % pc : params[:format] != :csv ? '' : 0
    return pc
  end

  def self.efficiency_clone(params, row)
    a = row['Distinct Genotype Confirmed ES Cells'].to_i
    b = row['Distinct Old Non Genotype Confirmed ES Cells'].to_i
    pc =  a + b != 0 ? ((a.to_f / (a + b).to_f) * 100) : 0
    pc = pc != 0 ? "%i" % pc : params[:format] != :csv ? '' : 0
    return pc
  end

  def self.make_clean(value, params)
    return value if params[:format] == :csv
    return '' if ! value || value.to_s == "0"
    return value
  end
        
  def self.genotype_confirmed_6month(row)
    return false if row['Genotype confirmed Date'].blank?
    return Date.parse(row['Micro-injection in progress Date']) < 6.months.ago.to_date
  end

  def self.distinct_genotype_confirmed_es_cells_count(group)
    total = 0
    group.each { |row| total += row['Distinct Genotype Confirmed ES Cells'].to_i }
    return total
  end

  def self.distinct_old_non_genotype_confirmed_es_cells_count(group)
    total = 0
    group.each { |row| total += row['Distinct Old Non Genotype Confirmed ES Cells'].to_i }
    return total
  end
  
  def self.filter_intermediate_report_for_mgp_rows (cached_report)
    filtered_report = Table(
      :data => cached_report.data,
      :column_names => cached_report.column_names,
      :filters => lambda {|r|
        return r['Consortium'] == 'MGP'
      }
    )

    exclude_columns = [
      "Consortium",
      "Production Centre"
    ]

    exclude_columns.each do |name|
      filtered_report.remove_column name
    end
    
    if(!cached_report)
      raise "cached report doesn't exist"
    end
    
    return filtered_report
  end
  
  def self.summarise_by_grouping_column_and_set_column_order(grouping_column, reduced_report, params)
    grouped_report = Grouping( reduced_report, :by => [ grouping_column ] )
    
    list_heads = [
      'ES QC confirmed',
      'Microinjection aborted',
      'Cre excision started',
      'Phenotyping completed',
      'Phenotyping aborted',
      'ES QC failed',
      'ES cell QC',
      'Genotype confirmed mice',
      'Microinjections',
      'Phenotyping started',
      'Cre excision completed',
      'Rederivation started',
      'Rederivation completed',
      'Registered for phenotyping',
      'Genotype confirmed mice 6 months',
      'Microinjection aborted 6 months',
      'Languishing'
    ]

    hash = {}
    hash['All genes'] = lambda { |group| count_unique_instances_of( group, 'Gene', lambda { |row| count_row(row, 'All genes') } ) }

    list_heads.each do |item|
      hash[item] = lambda { |group| count_instances_of( group, 'Gene', lambda { |row| count_row(row, item) } ) }
    end

    new_grouped_report = grouped_report.summary(grouping_column, hash)
    
    new_columns = 
      [
        grouping_column,
        "All genes",
        "ES cell QC",
        "ES QC confirmed",
        "ES QC failed",
        "Production Centre",
        "Microinjections",
        "Chimaeras produced",
        "Genotype confirmed mice",
        "Microinjection aborted",
        "Gene Pipeline efficiency (%)",
        "Clone Pipeline efficiency (%)",
        'Genotype confirmed mice 6 months',
        'Microinjection aborted 6 months',
        'Languishing',
        "Registered for phenotyping",
        "Rederivation started",
        "Rederivation completed",
        "Cre excision started",
        "Cre excision completed",
        "Phenotyping started",
        "Phenotyping completed",
        "Phenotyping aborted"
      ]
    
    new_grouped_report.reorder(new_columns)
    
    new_grouped_report.each do |row|
      pc = efficiency_6months(params, row)
      pc2 = efficiency_clone(params, row)
      #glt = row['Genotype confirmed mice 6 months'].to_i
      #failures = row['Languishing'].to_i + row['Microinjection aborted 6 months'].to_i
      #total = glt + failures      
      row['Gene Pipeline efficiency (%)'] = make_clean(pc, params)
      row['Clone Pipeline efficiency (%)'] = make_clean(pc2, params)
    end
    
    return new_grouped_report
  end
  
  def self.link_columns(grouping_column, report)
    
    columns_to_link = 
      [
        "All genes",
        "ES cell QC",
        "ES QC confirmed",
        "ES QC failed",
        "Production Centre",
        "Microinjections",
        "Chimaeras produced",
        "Genotype confirmed mice",
        "Microinjection aborted",
        "Registered for phenotyping",
        "Rederivation started",
        "Rederivation completed",
        "Cre excision started",
        "Cre excision completed",
        "Phenotyping started",
        "Phenotyping completed",
        "Phenotyping aborted"
      ]

    make_link =  lambda {
      |row|
      columns_to_link.each do |col_name|
        old_value = row[col_name]
        new_value = ''
        if((old_value.to_s.length < 1)||(old_value == 0))
          new_value = ''
        else
          if(grouping_column == 'Sub-Project')
            sub_project = row['Sub-Project']
            new_value = "<a href=\"detail?sub_project=#{sub_project}&column=#{col_name}\">#{old_value}</a>"
          elsif (grouping_column == 'Priority')
            priority = row['Priority']
            new_value = "<a href=\"detail?priority=#{priority}&column=#{col_name}\">#{old_value}</a>"
          else
            raise "I don't know how to group by #{grouping_column}"
          end
        end
        row[col_name] = new_value
      end
    }
    
    linked_report = Table(
      :data => report.data,
      :column_names => report.column_names,
      :transforms => make_link
    )
    
    return linked_report
  end

  def self.count_row(row, key)

    return true if key == 'All genes'

    if key == 'ES QC failed'
      return row['MiPlan Status'] == 'Aborted - ES Cell QC Failed'
    end

    if key == 'ES QC confirmed'
      return row['MiPlan Status'] == 'Assigned - ES Cell QC Complete'
    end

    if key == 'ES cell QC'
      return ['Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Aborted - ES Cell QC Failed'].include?(row['MiPlan Status'])
    end

    if key == 'Genotype confirmed mice'
      return row['MiAttempt Status'] == 'Genotype confirmed'
    end

    if key == 'Genotype confirmed mice 6 months'
      return row['MiAttempt Status'] == 'Genotype confirmed' && genotype_confirmed_6month(row)
    end

    if key == 'Microinjection aborted'
      return row['MiAttempt Status'] == 'Micro-injection aborted'
    end

    if key == 'Microinjection aborted 6 months'
      return row['MiAttempt Status'] == 'Micro-injection aborted' && Date.parse(row['Micro-injection aborted Date']) < 6.months.ago.to_date
    end

    if key == 'Microinjections'
      return row['MiAttempt Status'] == 'Micro-injection in progress' || row['MiAttempt Status'] == 'Genotype confirmed' ||
        row['MiAttempt Status'] == 'Micro-injection aborted'
    end

    if key == 'Phenotyping aborted'
      return row['PhenotypeAttempt Status'] == 'Phenotype Attempt Aborted'
    end

    if key == 'Phenotyping completed'
      return row['PhenotypeAttempt Status'] == 'Phenotyping Complete'
    end

    if key == 'Phenotyping started'
      return row['PhenotypeAttempt Status'] == 'Phenotyping Started'
    end

    if key == 'Cre excision completed'
      return row['PhenotypeAttempt Status'] == 'Cre Excision Complete'
    end

    if key == 'Cre excision started'
      return row['PhenotypeAttempt Status'] == 'Cre Excision Started'
    end

    if key == 'Rederivation started'
      return row['PhenotypeAttempt Status'] == 'Rederivation started' && row['Rederivation Start Date'].to_s.length > 0
    end
    
    if key == 'Rederivation completed'
      return row['PhenotypeAttempt Status'] == 'Rederivation completed' && row['Rederivation Complete Date'].to_s.length > 0
    end

    valid_phenos = [
      'Rederivation Started',
      'Rederivation Complete',
      'Cre Excision Started',
      'Cre Excision Complete',
      'Phenotyping Started',
      'Phenotyping Complete'
    ]

    if key == 'Registered for phenotyping'
      return valid_phenos.include?(row['PhenotypeAttempt Status'])
    end

    if key == 'Distinct Genotype Confirmed ES Cells'
      return row[key] && row[key].to_s.length > 0
    end

    if key == 'Distinct Old Non Genotype Confirmed ES Cells'
      return row[key] && row[key].to_s.length > 0
    end

    if key == 'Languishing'
      return row.data['Overall Status'] == 'Micro-injection in progress' && Date.parse(row['Micro-injection in progress Date']) < 6.months.ago.to_date
    end

    return false
  end

  def self.generate(grouping_column, params)
    cached_report = ReportCache.find_by_name_and_format!(Reports::MiProduction::Intermediate.report_name, 'csv').to_table
    
    reduced_report = filter_intermediate_report_for_mgp_rows(cached_report)

    summarised_report = summarise_by_grouping_column_and_set_column_order(grouping_column, reduced_report, params)
    
    linked_report = link_columns(grouping_column, summarised_report )

    title = 'Production for MGP'

    return {
      :title => title,
      :csv => linked_report.to_csv,
      :html => linked_report.to_html,
      :table => linked_report
    }
  end
  
  def self.generate_detail(request, params)
    # column = column header from report
    column = params[:column]
    subproject = params[:sub_project]
    priority = params[:priority]

    cached_report = ReportCache.find_by_name_and_format!('mi_production_intermediate', 'csv').to_table

    report = Table(
      :data => cached_report.data,
      :column_names => cached_report.column_names,
      :filters => lambda {|r|
        if(subproject)
          (r['Consortium'] == 'MGP') &&
          (r['Sub-Project'] == subproject) &&
          count_row(r, column)
        elsif(priority)
          (r['Consortium'] == 'MGP') &&
          (r['Priority'] == priority) &&
          count_row(r, column)
        end
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

    report.rename_column 'Overall Status', 'Status'
    report.rename_column 'Mutation Sub-Type', 'Mutation Type'

    return {
      :title => "Production detail or #{subproject} and #{column}",
      :csv => report.to_csv,
      :html => report.to_html,
      :table => report
    }
  end
end
