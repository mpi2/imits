# encoding: utf-8

class QualityOverviewsController < ApplicationController
  require 'csv'
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

    @quality_overviews = import(ALLELE_OVERALL_PASS_PATH)

    respond_to do |format|
      format.csv { render :csv => @quality_overviews }
    end
  end

end
