# encoding: utf-8

class QualityOverviewsController < ApplicationController

  require 'open-uri'

  respond_to :html, :csv

  def index
    @quality_overviews = import(ALLELE_OVERALL_PASS_PATH)
  end

  def import(file_path)

    infile = open(file_path)
    count = 0
    quality_overviews = Array.new
    CSV.parse(infile) do |row|
      count += 1
      next if count == 1 or row.join.blank?
        quality_overview = QualityOverview.build_from_csv(row)
        quality_overview.populate_related_data

        quality_overviews.push(quality_overview)
    end
    return quality_overviews
  end
  protected :import

  def export_to_csv
    require 'csv'
    @quality_overviews = import(ALLELE_OVERALL_PASS_PATH)

    first_row = @quality_overviews.first.column_names

    csv = CSV.generate(:force_quotes => true) do |line|
      line << first_row
      @quality_overviews.each do |quality_overview|
        line << quality_overview.to_csv.flatten
      end
    end

    send_data csv,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=quality-overviews-#{Time.now.strftime('%d-%m-%y--%H-%M')}.csv"

  end

end
