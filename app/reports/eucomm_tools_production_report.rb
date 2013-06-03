class EucommToolsProductionReport < BaseProductionReport

  ## See superclass for inherited methods.

  class << self
    def title
      "EUCOMMToolsCre Production summary"
    end
    
    def available_consortia
      [
          'EUCOMMToolsCre'
      ]
    end
  end
end