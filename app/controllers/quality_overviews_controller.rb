# encoding: utf-8
require 'csv'

class QualityOverviewsController < ApplicationController

  respond_to :html, :csv

  before_filter :authenticate_user!

  def index
    quality_overviews = QualityOverview.import(ALLELE_OVERALL_PASS_PATH)
    quality_overviews_sorted = QualityOverview.sort(quality_overviews)
    @quality_overviews = QualityOverview.group(quality_overviews_sorted)
  end

  protected :import

  def export_to_csv

    quality_overviews = QualityOverview.import(ALLELE_OVERALL_PASS_PATH)
    @quality_overviews = QualityOverview.sort(quality_overviews)
    header_row = @quality_overviews.first.column_names

    csv = CSV.generate(:force_quotes => true) do |line|
      line << header_row
      @quality_overviews.each do |quality_overview|
        line << quality_overview.column_values.flatten
      end
    end

    send_data csv,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=quality-overviews-#{Time.now.strftime('%d-%m-%y--%H-%M')}.csv"

  end

end
