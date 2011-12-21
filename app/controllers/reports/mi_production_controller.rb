# encoding: utf-8

class Reports::MiProductionController < ApplicationController
  respond_to :html, :csv

  before_filter :authenticate_user!

  def detail
    if request.format == :csv
      send_data_csv('mi_production_detail.csv', Reports::MiProduction::Detail.generate.to_csv)
    end
  end

  def intermediate
    report = ReportCache.find_by_name!('mi_production_intermediate')
    send_data_csv("mi_production_intermediate-#{report.compact_timestamp}.csv", report.csv_data)
  end

end
