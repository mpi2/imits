class ImpcSummaryByMonthReport < BaseSummaryByMonthReport

  ## See superclass for inherited methods.

  def available_consortia
    [
        'BaSH',
        'DTCC',
        'DTCC-Legacy',
        'EUCOMM-EUMODIC',
        'Helmholtz GMC',
        'JAX',
        'KMPC',
        'MARC',
        'MGP',
        'MGP Legacy',
        'MRC',
        'Monterotondo',
        'Monterotondo R&D',
        'NarLabs',
        'NorCOMM2',
        'Phenomin',
        'RIKEN BRC',
        'UCD-KOMP',
        'Infrafrontier-S3'
    ]
  end

end