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
        quality_overview.populate_mi_attempt_id
        @quality_overviews.push(quality_overview)
    end

  end

  def group_by_consortium_and_centre(quality_overviews)
    @grouping_consortium_store = Hash.new
    quality_overviews.each do |quality_overview|
      if @grouping_consortium_store.include?(quality_overview.mi_plan_consortium)

      else
        grouping_centre_store = Hash.new
        if quality_overview.mi_plan_production_centre
          quality_overview_array = Array.new
          quality_overview_array.push(quality_overview)
          grouping_centre_store[quality_overview.mi_plan_production_centre] = quality_overview_array

          @grouping_consortium_store[quality_overview.mi_plan_consortium] = grouping_centre_store
        else
          logger.error("Missing quality overview mi_plan production centre name")
          logger.error(quality_overview.inspect)
        end
      end
    end
  end

  def index
    import
    group_by_consortium_and_centre(@quality_overviews)
  end

  def show


  end

end
