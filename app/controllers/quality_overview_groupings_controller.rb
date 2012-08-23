# encoding: utf-8

class QualityOverviewGroupingsController < ApplicationController

  respond_to :html

  before_filter :authenticate_user!

  def index
    quality_overviews = QualityOverview.import(ALLELE_OVERALL_PASS_PATH)
    grouping_consortium_store = QualityOverviewGrouping.group_by_consortium_and_centre(quality_overviews)
    quality_overview_groupings = QualityOverviewGrouping.construct_quality_review_groupings(grouping_consortium_store)
    quality_overview_groupings_sorted = QualityOverviewGrouping.sort(quality_overview_groupings)
    @quality_overview_groupings = QualityOverviewGrouping.group(quality_overview_groupings_sorted)
  end

end
