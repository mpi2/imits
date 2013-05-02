class Komp2SummaryByMonthReport < BaseSummaryByMonthReport

  ## See superclass for inherited methods.

  class << self

    # KOMP2 consortia
    def available_consortia
      ['BaSH', 'DTCC', 'JAX']
    end

  end

end