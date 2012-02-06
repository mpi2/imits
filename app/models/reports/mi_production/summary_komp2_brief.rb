# encoding: utf-8

class Reports::MiProduction::SummaryKomp2Brief

  extend Reports::MiProduction::SummariesCommon

  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS  
  DEBUG = Reports::MiProduction::SummariesCommon::DEBUG
  MAPPING_SUMMARIES = Reports::MiProduction::SummariesCommon::MAPPING_SUMMARIES
  ORDER_BY_MAP = Reports::MiProduction::SummariesCommon::ORDER_BY_MAP
  CONSORTIA = ['BaSH', 'DTCC', 'DTCC-Legacy', 'JAX']

  def self.generate(request = nil, params={})
    return Reports::MiProduction::SummaryByConsortium.generate(request, params, CONSORTIA, 'KOMP2 (brief)')
  end

end
