class ImpcProductionReport < BaseProductionReport

  ## See superclass for inherited methods.

  class << self

    def title
      "IMPC Production summary"
    end

    def available_consortia
      [
        'BaSH',
        'CCP-IMG',
        'DTCC',
        'DTCC-Legacy',
        'EUCOMM-EUMODIC',
        'Helmholtz GMC',
        'Infrafrontier-S3',
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
        'UCD-KOMP'
      ]
    end
  end
end
