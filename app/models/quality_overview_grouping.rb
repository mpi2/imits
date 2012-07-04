# encoding: utf-8
require 'csv'
require 'open-uri'

class QualityOverviewGrouping

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :consortium, :production_centre
  attr_accessor :quality_overviews

  attr_accessor :number_of_genotype_confirmed_colonies, :colonies_with_overall_pass, :percentage_pass
  attr_accessor :confirm_locus_targeted_total, :confirm_structure_targeted_allele_total
  attr_accessor :confirm_downstream_lox_p_site_total, :confirm_no_additional_vector_insertions_total

  def persisted?
    false
  end

  def initialize
    self.confirm_locus_targeted_total = 0
    self.confirm_structure_targeted_allele_total = 0
    self.confirm_downstream_lox_p_site_total = 0
    self.confirm_no_additional_vector_insertions_total = 0
    self.colonies_with_overall_pass = 0
    self.percentage_pass = 0
  end

  def calculate_percentage_pass

   self.percentage_pass =  begin
                             ((self.colonies_with_overall_pass.to_f / self.number_of_genotype_confirmed_colonies.to_f) * 100).round(2)
                           rescue ZeroDivisionError
                             0
                           end
  end

  def quality_overview_data
    self.number_of_genotype_confirmed_colonies = self.quality_overviews.length

    self.quality_overviews.each do |quality_overview|
        overall_pass = true
      if quality_overview.confirm_locus_targeted != nil || !quality_overview.confirm_locus_targeted.blank?
        self.confirm_locus_targeted_total = self.confirm_locus_targeted_total + 1
        overall_pass = false
      end
      if quality_overview.confirm_structure_targeted_allele != nil || !quality_overview.confirm_structure_targeted_allele.blank?
        self.confirm_structure_targeted_allele_total = self.confirm_structure_targeted_allele_total + 1
        overall_pass = false
      end
      if quality_overview.confirm_downstream_lox_p_site != nil || !quality_overview.confirm_downstream_lox_p_site.blank?
        self.confirm_downstream_lox_p_site_total = self.confirm_downstream_lox_p_site_total + 1
        overall_pass = false
      end
      if quality_overview.confirm_no_additional_vector_insertions != nil || !quality_overview.confirm_no_additional_vector_insertions.blank?
        self.confirm_no_additional_vector_insertions_total = self.confirm_no_additional_vector_insertions_total + 1
        overall_pass = false
      end
      if overall_pass
        self.colonies_with_overall_pass = self.colonies_with_overall_pass + 1
      end
    end

  end

  def self.group_by_consortium_and_centre(quality_overviews)
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

  def self.construct_quality_review_groupings(grouping_store)
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

  def self.sort(quality_overview_groupings)
    quality_overview_groupings.sort!{|qga,qgb| [qga.consortium, qga.production_centre] <=> [qgb.consortium, qgb.production_centre]}
    return quality_overview_groupings
  end

end
