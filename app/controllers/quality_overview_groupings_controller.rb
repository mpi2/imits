# encoding: utf-8

class QualityOverviewGroupingsController < ApplicationController
  require 'csv'

  def summary
    quality_overviews = import('db/allele_overall_pass.csv')
    grouping_consortium_store = group_by_consortium_and_centre(quality_overviews)
    @quality_overview_groupings = construct_quality_review_groupings(grouping_consortium_store)
  end

  def import(file_path)

    infile = File.open(file_path)
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

  def group_by_consortium_and_centre(quality_overviews)
    grouping_consortium_store = Hash.new

    quality_overviews.each do |quality_overview|
      if grouping_consortium_store.keys.include?(quality_overview.mi_plan_consortium)

        grouping_centre_store = grouping_consortium_store.fetch(quality_overview.mi_plan_consortium)
        if grouping_centre_store.keys.include?(quality_overview.mi_plan_production_centre)
          quality_overview_array = grouping_centre_store.fetch(quality_overview.mi_plan_production_centre)

          quality_overview_array.push(quality_overview)

          grouping_centre_store.store(quality_overview.mi_plan_production_centre, quality_overview_array)

          grouping_consortium_store.store(quality_overview.mi_plan_consortium, grouping_centre_store)
        else
          grouping_centre_store = Hash.new

          quality_overview_array = Array.new
          quality_overview_array.push(quality_overview)
          grouping_centre_store = grouping_consortium_store.fetch(quality_overview.mi_plan_consortium)
          grouping_centre_store.store(quality_overview.mi_plan_production_centre, quality_overview_array)

          grouping_consortium_store.store(quality_overview.mi_plan_consortium, grouping_centre_store)
        end
      else
          grouping_centre_store = Hash.new

          quality_overview_array = Array.new
          quality_overview_array.push(quality_overview)
          grouping_centre_store[quality_overview.mi_plan_production_centre] = quality_overview_array

          grouping_consortium_store[quality_overview.mi_plan_consortium] = grouping_centre_store

      end
    end
    return grouping_consortium_store
  end
  protected :group_by_consortium_and_centre

  def construct_quality_review_groupings(grouping_store)
    quality_overview_groupings = Array.new

    grouping_store.each_pair do |consortium_name, centre_group|

      centre_group.each_pair do |centre_name, quality_overview_array|
        quality_overview_grouping = QualityOverviewGrouping.new
        quality_overview_grouping.consortium = consortium_name
        quality_overview_grouping.production_centre = centre_name

        quality_overview_grouping.quality_overviews = quality_overview_array
        quality_overview_grouping.quality_overview_data
        quality_overview_grouping.calculate_percentage_pass
        quality_overview_groupings.push(quality_overview_grouping)
      end
    end
    return quality_overview_groupings
  end
  protected :construct_quality_review_groupings

end
