# encoding: utf-8

class QualityOverviewsController < ApplicationController
  require 'csv'

  def import

    infile = File.open('db/allele_overall_pass.csv')
    count, errors = 0, []
    @quality_overviews = Array.new
    CSV.parse(infile) do |row|
      count += 1
      next if count == 1 or row.join.blank?
        quality_overview = QualityOverview.build_from_csv(row)
        quality_overview.populate_mi_attempt_ids
        @quality_overviews.push(quality_overview)
    end
  end

  def index
     import

  end

  def show


  end

end
