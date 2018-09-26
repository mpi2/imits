class ImpcProductionReport < BaseProductionReport

  ## See superclass for inherited methods.

  class << self

    def title
      "IMPC Production summary"
    end

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
        'Infrafrontier-S3',
        'CCP'
      ]
    end
  end
end
