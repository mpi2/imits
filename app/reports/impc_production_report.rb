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
        'MARC',
        'MGP',
        'MGP Legacy',
        'MRC',
        'Monterotondo',
        'NorCOMM2',
        'Phenomin',
        'RIKEN BRC',
        'UCD-KOMP'
      ]
    end
  end
end