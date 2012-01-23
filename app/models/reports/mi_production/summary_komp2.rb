# encoding: utf-8

class Reports::MiProduction::SummaryKomp2

  extend Reports::MiProduction::SummariesCommon
  extend Reports::MiProduction::SummaryKomp2Common

  CSV_LINKS = Reports::MiProduction::SummaryKomp2Common::CSV_LINKS  
  REPORT_TITLE = 'KOMP2 Report'
  
  #TODO: fix return value so we dont do to_csv etc.

  def self.generate(request = nil, params={})
    
    if params[:consortium]
      title, report = subsummary_common(params)
      rv = request && request.format == :csv ? report.to_csv : report.to_html
      return title, rv
    end

    report = generate_common(request, params)

    #headings = Reports::MiProduction::SummaryKomp2Common::HEADINGS

    #['Consortium', 'Production Centre',
    #    'All',
    #    'ES QC started',
    #    'ES QC confirmed',
    #    'MI in progress',
    #    #              'Chimaeras',
    #    'Genotype Confirmed Mice',
    #    'Registered for Phenotyping',
    #    'Phenotyping Started',
    #    'Rederivation Started',
    #    'Rederivation Complete',
    #    'Cre Excision Started',
    #    'Cre Excision Complete',
    #    'Phenotyping Complete',
    #    'ES QC failed',
    #    'MI Aborted',
    #    'Phenotype Attempt Aborted'
    #    #              'Pipeline efficiency (%)',
    #    #              'Pipeline efficiency (by clone)'
    #  ]

    reordered = ['Consortium',
      'All',
      'ES QC started',
      'ES QC confirmed',
      'ES QC failed',
      'Production Centre',
      'MI in progress',
      'MI Aborted',
      'Genotype Confirmed Mice',
      'Pipeline efficiency (%)',
      'Pipeline efficiency (by clone)',
      'Registered for Phenotyping'
    ]

    report.remove_columns("Phenotyping Started", "Rederivation Started", "Rederivation Complete", "Cre Excision Started", "Cre Excision Complete", "Phenotyping Complete")
    report.reorder(reordered)
  
    return REPORT_TITLE, request && request.format == :csv ? report.to_csv : report.to_html
  end
  
end
