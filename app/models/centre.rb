class Centre < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  validates :name, :presence => true, :uniqueness => true

  has_many :mi_plans, :foreign_key => 'production_centre_id'
  has_many :targ_rep_es_cells, :foreign_key => 'user_mouse_clinic_id'
  has_many :mi_attempt_distribution_centres, :class_name => "MiAttempt::DistributionCentre"
  has_many :phenotype_attempt_distribution_centres, :class_name => "PhenotypeAttempt::DistributionCentre"

  has_many :tracking_goals

  default_scope :order => 'name ASC'

  def has_children?
    ! (mi_plans.empty? && mi_attempt_distribution_centres.empty? && phenotype_attempt_distribution_centres.empty?)
  end

  def destroy
    return false if has_children?
    super
  end

  def self.readable_name
    return 'centre'
  end

  def get_all_gtc_mi_attempt_distribution_centres

    mi_distribution_centres_filtered = []

    mi_distribution_centres = self.mi_attempt_distribution_centres
    mi_distribution_centres.each do |mi_distribution_centre|
      mi_attempt = mi_distribution_centre.mi_attempt
      unless mi_attempt.status.name == 'Genotype confirmed'
        next
      end
      #TODO remove - limits selection to specific consortia
      # BaSH, JAX, DTCC
      # unless mi_attempt.mi_plan.consortium.name == 'JAX'
      #   next
      # end # end filter

      mi_distribution_centres_filtered.push(mi_distribution_centre)
    end

    return mi_distribution_centres_filtered
  end

  def get_all_cre_excised_phenotype_attempt_distribution_centres

    phenotype_distribution_centres_filtered = []

    phenotype_distribution_centres = self.phenotype_attempt_distribution_centres
    phenotype_distribution_centres.each do |phenotype_distribution_centre|
      mouse_allele_mod = phenotype_distribution_centre.mouse_allele_mod
      if mouse_allele_mod.nil?
        next
      end
      unless mouse_allele_mod.status.name == 'Cre Excision Complete'
        next
      end
      #TODO remove - limits selection to specific consortia
      # BaSH, JAX, DTCC
      unless mouse_allele_mod.mi_plan.consortium.name == 'BaSH'
        next
      end # end filter

      phenotype_distribution_centres_filtered.push(phenotype_distribution_centre)
    end

    return phenotype_distribution_centres_filtered
  end
end

# == Schema Information
#
# Table name: centres
#
#  id            :integer          not null, primary key
#  name          :string(100)      not null
#  created_at    :datetime
#  updated_at    :datetime
#  contact_name  :string(100)
#  contact_email :string(100)
#
# Indexes
#
#  index_centres_on_name  (name) UNIQUE
#
