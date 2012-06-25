# encoding: utf-8

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

end
