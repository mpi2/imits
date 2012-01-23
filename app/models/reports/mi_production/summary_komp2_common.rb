# encoding: utf-8

#TODO: do test for #5623
#TODO: fix efficiency names
#TODO: routine to prettify html
#TODO: subsummary_common routine
#TODO: apply links to cell counts
#TODO: do unit tests
#TODO: do integration tests

module Reports::MiProduction::SummaryKomp2Common
  
  DEBUG = false

  CACHE_NAME = DEBUG ? 'mi_production_intermediate_test' : 'mi_production_intermediate'
  
  extend Reports::MiProduction::SummariesCommon

  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS

  MAPPING_SUMMARIES = {
    'All' => ['Phenotype Attempt Aborted', 'Micro-injection aborted', 'Aborted - ES Cell QC Failed'],
    'ES QC started' => ['Assigned - ES Cell QC In Progress'],
    'MI in progress' => ['Micro-injection in progress'],

    #    'Chimaeras' => [],
    'Genotype Confirmed Mice' => ['Genotype confirmed'],
    'ES QC confirmed' => ['Assigned - ES Cell QC Complete'],
    
    'ES QC failed' => ['Aborted - ES Cell QC Failed'],
    'MI Aborted' => ['Micro-injection aborted'],
    'Phenotype Attempt Aborted' => ['Phenotype Attempt Aborted'],
    
    'Registered for Phenotyping' => ['Phenotype Attempt Registered'],
    'Phenotyping Started' => ['Phenotyping Started'],
    'Rederivation Started' => ['Rederivation Started'],
    'Rederivation Complete' => ['Rederivation Complete'],
    'Cre Excision Started' => ['Cre Excision Started'],
    'Cre Excision Complete' => ['Cre Excision Complete'],
    'Phenotyping Complete' => ['Phenotyping Complete']
  }
  
  CONSORTIA = ['BaSH', 'DTCC', 'JAX']
  
  HEADINGS = ['Consortium', 'Production Centre',
    'All',
    'ES QC started',
    'ES QC confirmed',
    'MI in progress',
    #              'Chimaeras',
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

  IGNORE = ['Consortium',
    'Production Centre',
    'Phenotype Attempt Aborted',
    'MI Aborted',
    'ES QC failed',
    'Pipeline efficiency (%)',
    'Pipeline efficiency (by clone)',
    'All',
    'Phenotyping Complete'
  ]

  def generate_common(request = nil, params={})

    debug = params['debug'] && params['debug'].to_s.length > 0

    cached_report = initialize
        
    heading = HEADINGS   
    heading.push 'Languishing' if debug
    heading.push 'Distinct Genotype Confirmed ES Cells' if debug
    heading.push 'Distinct Old Non Genotype Confirmed ES Cells' if debug
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
            lambda { |row2| process_row(row2, 'Phenotype Attempt Aborted') } ) }

      ).each do |row|
        
        next if row['Production Centre'].to_s.length < 1

        pc = efficiency(request, row)
        pc2 = efficiency2(request, row)

        clean_value = lambda {|value|
          return value if request && request.format == :csv
          return '' if ! value || value.to_s == "0"
          return value
        }
      
        report_table << {
          'Consortium' => consortium,
          'Production Centre' => row['Production Centre'],
          'All' => clean_value.call(row['All']),
          'ES QC started' => clean_value.call(row['ES QC started']),
          'ES QC confirmed' => clean_value.call(row['ES QC confirmed']),
          'ES QC failed' => clean_value.call(row['ES QC failed']),
          'MI in progress' => clean_value.call(row['MI in progress']),
          'Genotype Confirmed Mice' => clean_value.call(row['Genotype Confirmed Mice']),
          'MI Aborted' => clean_value.call(row['MI Aborted']),
          'Languishing' => clean_value.call(row['Languishing']),
          'Registered for Phenotyping' => clean_value.call(row['Registered for Phenotyping']),
          'Distinct Genotype Confirmed ES Cells' => clean_value.call(row['Distinct Genotype Confirmed ES Cells']),
          'Distinct Old Non Genotype Confirmed ES Cells' => clean_value.call(row['Distinct Old Non Genotype Confirmed ES Cells']),
          'Pipeline efficiency (%)' => clean_value.call(pc),
          'Pipeline efficiency (by clone)' => clean_value.call(pc2),
            
          'Phenotyping Started' => clean_value.call(row['Phenotyping Started']),
          'Rederivation Started' => clean_value.call(row['Rederivation Started']),
          'Rederivation Complete' => clean_value.call(row['Rederivation Complete']),
          'Cre Excision Started' => clean_value.call(row['Cre Excision Started']),
          'Cre Excision Complete' => clean_value.call(row['Cre Excision Complete']),
          'Phenotyping Complete' => clean_value.call(row['Phenotyping Complete']),
          'Phenotype Attempt Aborted' => clean_value.call(row['Phenotype Attempt Aborted'])
        }
        
      end
    end

    return report_table
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
  
  def initialize

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

  def process_row(row, key)
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

    return MAPPING_SUMMARIES[key].include? row.data['Overall Status'] if keys2.include? key
    return true if key == 'All'
    return     (MAPPING_SUMMARIES['Genotype Confirmed Mice'].include?(row.data['Overall Status'])) ||
      ((MAPPING_SUMMARIES['Registered for Phenotyping'].include? row.data['Overall Status']) &&
        (row.data['Genotype confirmed Date'] && row.data['Genotype confirmed Date'].to_s.length > 0)) if key == 'Genotype Confirmed Mice'

    return (row && row['PhenotypeAttempt Status'] && row['PhenotypeAttempt Status'].to_s.length > 1 || MAPPING_SUMMARIES['Registered for Phenotyping'].include?(row.data['Overall Status'])) if key == 'Registered for Phenotyping'
  
    raise "process_row: invalid key detected '#{key}'"
  end

end

