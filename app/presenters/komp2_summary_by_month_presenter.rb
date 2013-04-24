class Komp2SummaryByMonthPresenter < BaseSummaryByMonthPresenter

  class << self
    def available_consortia
      ['BaSH', 'DTCC', 'JAX']
    end
  end

end