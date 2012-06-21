# encoding: utf-8

class QualityOverviewsController < ApplicationController
  require 'csv'

  def import
    infile = 'allele_overall_pass.csv'
    count, errors = 0, []
    @quality_overviews = Array.new
    CSV.parse(infile) do |row|
      count += 1
      if count != 1 or !row.join.blank?
        quality_overview = QualityOverview.build_from_csv(row)
        @quality_overviews.push(quality_overview)
      end
    end
  end

  def index
     import
     puts @quality_overviews.inspect
  end

  def show


  end

end
