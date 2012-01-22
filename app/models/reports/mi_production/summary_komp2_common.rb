# encoding: utf-8

#TODO: fix efficiency names

module Reports::MiProduction::SummaryKomp2Common
  
  DEBUG = false
  ACCUMULATE = true

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
    'Phenotype Attempt Aborted'
    #              'Pipeline efficiency (%)',
    #              'Pipeline efficiency (by clone)'
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

  def self.generate_common(request = nil, params={})

    debug = params['debug'] && params['debug'].to_s.length > 0

    cached_report = initialize
        
    heading = HEADINGS   
    heading.push 'Languishing' if debug
    heading.push 'Distinct Genotype Confirmed ES Cells' if debug
    heading.push 'Distinct Old Non Genotype Confirmed ES Cells' if debug
    summary = nil

    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )
    
    grouped_report.each do |consortium| 

      next if ! CONSORTIA.include?(consortium)

      summary = grouped_report.subgrouping(consortium).summary(

        'Production Centre',
        'All' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| all(row) } ) },
        'ES QC started' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status'] } ) },
        'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status'] } ) },
        'ES QC failed' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status'] } ) },
        'MI in progress' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['MI in progress'].include? row2.data['Overall Status'] } ) },
        'Genotype Confirmed Mice' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| glt(row) } ) },
        'MI Aborted' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['MI Aborted'].include? row2.data['Overall Status'] } ) },
        'Registered for Phenotyping' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| registered_for_phenotyping(row2) } ) },
        
        'Languishing' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| languishing(row2) } ) },
        'Distinct Genotype Confirmed ES Cells' => lambda { |group| distinct_genotype_confirmed_es_cells(group) },
        'Distinct Old Non Genotype Confirmed ES Cells' => lambda { |group| distinct_old_non_genotype_confirmed_es_cells(group) },

        'Phenotyping Started' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['Phenotyping Started'].include? row2.data['Overall Status'] } ) },
        'Rederivation Started' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['Rederivation Started'].include? row2.data['Overall Status'] } ) },
        'Rederivation Complete' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['Rederivation Complete'].include? row2.data['Overall Status'] } ) },
        'Cre Excision Started' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['Cre Excision Started'].include? row2.data['Overall Status'] } ) },
        'Cre Excision Complete' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['Cre Excision Complete'].include? row2.data['Overall Status'] } ) },
        'Phenotyping Complete' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['Phenotyping Complete'].include? row2.data['Overall Status'] } ) },
        'Phenotype Attempt Aborted' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['Phenotype Attempt Aborted'].include? row2.data['Overall Status'] } ) }

      )

    end

    return summary
  end

  def self.csv_line(consortium, centre, gene, status)
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

end
