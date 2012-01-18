# encoding: utf-8

#Yes: I am assuming the columns to the right will go:

#registered for pheno, rederivation start / finsihed ,
#cre start / finished pheno start / finished,
#THEN aborted. THEN the accumulation starts with pheno
#finished and continues left. The thing is that the
#aborted column must be accumulated onto the total
#at the far left, but no other column along the way

#TODO: fix new efficiency ticket
#TODO: fix 'Registered for Phenotyping'
  
class Reports::MiProduction::SummaryKomp21
  
  DEBUG = true

  CACHE_NAME = DEBUG ? 'mi_production_intermediate_test' : 'mi_production_intermediate'
  
  extend Reports::MiProduction::SummariesCommon

  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS  
  MAPPING_SUMMARIES_ORIG = {
    'All' => ['Phenotype Attempt Aborted', 'MI Aborted', 'ES QC failed'],
    'ES QC started' => ['Assigned - ES Cell QC In Progress'],
    'MI in progress' => ['Micro-injection in progress'],
#    'Chimaeras' => [],
    'Genotype Confirmed Mice' => ['Genotype confirmed'],
    'MI Aborted' => ['Micro-injection aborted'],
    'ES QC confirmed' => ['Assigned - ES Cell QC Complete'],
    'ES QC failed' => ['Aborted - ES Cell QC Failed'],
    
    'Registered for Phenotyping' => ['Phenotype Attempt Registered'],
    'Phenotyping Started' => ['Phenotyping Started'],
    'Rederivation Started' => ['Rederivation Started'],
    'Rederivation Complete' => ['Rederivation Complete'],
    'Cre Excision Started' => ['Cre Excision Started'],
    'Cre Excision Complete' => ['Cre Excision Complete'],
    'Phenotyping Complete' => ['Phenotyping Complete'],
    'Phenotype Attempt Aborted' => ['Phenotype Attempt Aborted']
  }

  MAPPING_SUMMARIES = {}
  
  CONSORTIA = ['BaSH', 'DTCC', 'JAX']
  REPORT_TITLE = "KOMP2 Report'"

  HEADINGS = ['Consortium', 'Production Centre',
              'All',
              'ES QC started',
              'ES QC confirmed',
              'MI in progress',
              #'Chimaeras',
              'Genotype Confirmed Mice',
              'Registered for Phenotyping',
              'Phenotyping Started',
              'Rederivation Started',
              'Rederivation Complete',
              'Cre Excision Started',
              'Cre Excision Complete',
              'Phenotyping Complete',
              'Phenotype Attempt Aborted',
              #'Pipeline efficiency (%)',
              #'Pipeline efficiency (by clone)'
              'MI Aborted',
              'ES QC failed',
            ]

  IGNORE = ['Consortium',
            'Production Centre',
            'Phenotype Attempt Aborted',
            'MI Aborted',
            'ES QC failed',
            'Pipeline efficiency (%)',
            'Pipeline efficiency (by clone)'
            ]
  
  (HEADINGS.size-1).downto(1).each do |i|
    MAPPING_SUMMARIES[HEADINGS[i]] = [] if IGNORE.include? HEADINGS[i]
    next if IGNORE.include? HEADINGS[i]
    MAPPING_SUMMARIES[HEADINGS[i]] = MAPPING_SUMMARIES_ORIG[HEADINGS[i]] + MAPPING_SUMMARIES[HEADINGS[i+1]]
  end
  
  #TODO: fix efficiency names

  def self.generate(request = nil, params={})
    
    if params[:consortium]
      title, report = subsummary_common(request, params)
      return title, report
    end

    debug = params['debug'] && params['debug'].to_s.length > 0

    script_name = request ? request.env['REQUEST_URI'] : ''

    cached_report = initialize
        
    heading = HEADINGS   
    heading.push 'Languishing' if debug
    heading.push 'Distinct Genotype Confirmed ES Cells' if debug
    heading.push 'Distinct Old Non Genotype Confirmed ES Cells' if debug
    
    report_table = Table(heading)
 
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )
    
    grouped_report.each do |consortium| 

      next if ! CONSORTIA.include?(consortium)

      summary = grouped_report.subgrouping(consortium).summary(

        'Production Centre',
        'All' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['All'].include? row.data['Overall Status'] } ) },
        'ES QC started' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status'] } ) },
        'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status'] } ) },
        'ES QC failed' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status'] } ) },
        'MI in progress' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['MI in progress'].include? row2.data['Overall Status'] } ) },
        'Genotype Confirmed Mice' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['Genotype Confirmed Mice'].include? row2.data['Overall Status'] } ) },
        'MI Aborted' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['MI Aborted'].include? row2.data['Overall Status'] } ) },
        'Registered for Phenotyping' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| registered_for_phenotyping(row2) } ) },
        'Languishing' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| languishing(row2) } ) },
        'Distinct Genotype Confirmed ES Cells' => lambda { |group| distinct_genotype_confirmed_es_cells(group) },
        'Distinct Old Non Genotype Confirmed ES Cells' => lambda { |group| distinct_old_non_genotype_confirmed_es_cells(group) },

        'Registered for Phenotyping' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['Registered for Phenotyping'].include? row2.data['Overall Status'] } ) },
        'Registered for Phenotyping' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['Registered for Phenotyping'].include? row2.data['Overall Status'] } ) },
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
            lambda { |row2| MAPPING_SUMMARIES['Phenotype Attempt Aborted'].include? row2.data['Overall Status'] } ) },

        ).each do |row|

          pc = efficiency(request, row)
          pc2 = efficiency2(request, row)

          report_table << {
            'Consortium' => consortium,
            'Production Centre' => row['Production Centre'],
            'All' => row['All'],
            'ES QC started' => row['ES QC started'],
            'ES QC confirmed' => row['ES QC confirmed'],
            'ES QC failed' => row['ES QC failed'],
            'MI in progress' => row['MI in progress'],
            'Genotype Confirmed Mice' => row['Genotype Confirmed Mice'],
            'MI Aborted' => row['MI Aborted'],
            'Languishing' => row['Languishing'],
            'Registered for Phenotyping' => row['Registered for Phenotyping'],
            'Distinct Genotype Confirmed ES Cells' => row['Distinct Genotype Confirmed ES Cells'],
            'Distinct Old Non Genotype Confirmed ES Cells' => row['Distinct Old Non Genotype Confirmed ES Cells'],
            'Pipeline efficiency (%)' => pc,
            'Pipeline efficiency (by clone)' => pc2,
            
            'Registered for Phenotyping' => row['Registered for Phenotyping'],
            'Registered for Phenotyping' => row['Registered for Phenotyping'],
            'Phenotyping Started' => row['Phenotyping Started'],
            'Rederivation Started' => row['Rederivation Started'],
            'Rederivation Complete' => row['Rederivation Complete'],
            'Cre Excision Started' => row['Cre Excision Started'],
            'Cre Excision Complete' => row['Cre Excision Complete'],
            'Phenotyping Complete' => row['Phenotyping Complete'],
            'Phenotype Attempt Aborted' => row['Phenotype Attempt Aborted']
          }
        
        end
    end

    return REPORT_TITLE, report_table
  end

  def self.csv_line(gene, status)
      gene_status_template = '"BaSH",,"High","BCM","GENE-TARGET","MGI:1921546","STATUS-TARGET","Assigned - ES Cell QC In Progress",,,,,,,10/10/11,16/11/11,,,,,,,,,,,,,0,0'
      template = gene_status_template
      template = template.gsub(/GENE-TARGET/, gene)
      template = template.gsub(/STATUS-TARGET/, status)
      return template
  end
  
  def self.initialize

    if DEBUG
    	report = ReportCache.find_by_name(CACHE_NAME)

      heading = '"Consortium","Sub-Project","Priority","Production Centre","Gene","MGI Accession ID","Overall Status","MiPlan Status","MiAttempt Status","PhenotypeAttempt Status","IKMC Project ID","Mutation Sub-Type","Allele Symbol","Genetic Background","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date","Phenotype Attempt Registered Date","Rederivation Started Date","Rederivation Complete Date","Cre Excision Started Date","Cre Excision Complete Date","Phenotyping Started Date","Phenotyping Complete Date","Phenotype Attempt Aborted Date"'
  
      csv = heading + "\n"
      
      ignore = IGNORE -
            [
             'Phenotype Attempt Aborted',
            'MI Aborted',
            'ES QC failed'
            ]
  
      (HEADINGS.size-1).downto(1).each do |i|
        next if (['All'] + ignore).include? HEADINGS[i]
        csv += csv_line('abc' + i.to_s, MAPPING_SUMMARIES_ORIG[HEADINGS[i]][0]) + "\n"
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


  #Accumulate all the numbers in cells to the 'right' towards the cells on
  #the 'left'.
  #
  #1) ES QC started cell now contains:
  #ES QC Confirmed +
  #ES QC Failed +
  #MI In progress +
  #Chimeras +
  #MI Aborted +
  #Genotype Confirmed +
  #Registered for phenotyping + 
  #...
  #and so on, for all cells (ie you accumulate the cells to the right)

  #Overall Status
  #Interest
  #Inspect - MI Attempt
  #Assigned - ES Cell QC In Progress
  #Assigned - ES Cell QC Complete
  #Micro-injection in progress
  #Genotype confirmed
  #Assigned
  #Conflict
  #Inspect - Conflict
  #Inspect - GLT Mouse
  #Withdrawn
  #Micro-injection aborted
  #Registered for Phenotyping
  #Phenotyping Complete
  #Aborted - ES Cell QC Failed

  #CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS  
  #MAPPING_SUMMARIES_ORIG = {
  #  'All' => [],
  #  'ES QC started' => ['Assigned - ES Cell QC In Progress'],
  #  'MI in progress' => ['Micro-injection in progress'],
  #  'Genotype Confirmed Mice' => ['Genotype confirmed'],
  #  'MI Aborted' => ['Micro-injection aborted'],
  #  'ES QC confirmed' => ['Assigned - ES Cell QC Complete'],
  #  'ES QC failed' => ['Aborted - ES Cell QC Failed'],
  #  'Registered for Phenotyping' => []
  #}










## MiAttemptStatus
#
#'Micro-injection in progress'},
#'Genotype confirmed'},
#'Micro-injection aborted'
#
## MiPlan::Status  
#  
#'Interest', 
#'Conflict', 
#'Inspect - GLT Mouse', 
#'Inspect - MI Attempt', 
#'Inspect - Conflict', 
#'Assigned', 
#'Assigned - ES Cell QC In Progress', 
#'Assigned - ES Cell QC Complete', 
#'Aborted - ES Cell QC Failed',
#'Inactive',
#'Withdrawn'
#
## PhenotypeAttempt::Status  
#  
#'Phenotype Attempt Aborted',
#'Registered for Phenotyping',
#'Rederivation Started',
#'Rederivation Complete',
#'Cre Excision Started',
#'Cre Excision Complete',
#'Phenotyping Started',
#'Phenotyping Complete'
