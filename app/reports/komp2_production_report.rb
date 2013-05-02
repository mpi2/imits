class Komp2ProductionReport < BaseProductionReport

  ## See superclass for inherited methods.

  class << self
    # KOMP2 Consortia
    def available_consortia
      ['BaSH', 'DTCC', 'JAX']
    end
  end

end