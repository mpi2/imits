# encoding: utf-8

class Public::PhenotypeAttempt < ::PhenotypeAttempt

  extend AccessAssociationByAttribute
  include Public::Serializable
  include Public::DistributionCentresAttributes

  FULL_ACCESS_ATTRIBUTES = %w{
    colony_name
    consortium_name
    production_centre_name
    mi_attempt_colony_name
    is_active
    rederivation_started
    rederivation_complete
    number_of_cre_matings_successful
    phenotyping_started
    phenotyping_complete
    mouse_allele_type
    deleter_strain_name
    distribution_centres_attributes
  }

  READABLE_ATTRIBUTES = %w{
    id
    distribution_centres_formatted_display
    status_name
    marker_symbol
  } + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*WRITABLE_ATTRIBUTES)

  accepts_nested_attributes_for :distribution_centres, :allow_destroy => true

  access_association_by_attribute :mi_attempt, :colony_name
  access_association_by_attribute :deleter_strain, :name

  validates :mi_attempt_colony_name, :presence => true
  validates :mi_plan, :presence => {:message => 'cannot be found with supplied parameters.  Please either create it first or check consortium_name and/or production_centre_name supplied'}

  validate do |me|
    if me.changed.include?('mi_attempt_id') and ! me.new_record?
      me.errors.add :mi_attempt_colony_name, 'cannot be changed'
    end
  end

  validate :consortium_name_and_production_centre_name_from_mi_plan_validation

  # BEGIN Callbacks

  def set_mi_plan
    return if mi_plan
    return if mi_attempt.nil?

    if production_centre_name
      centre_to_set = Centre.find_by_name(production_centre_name)
    else
      centre_to_set = mi_attempt.production_centre
    end

    if consortium_name
      consortium_to_set = Consortium.find_by_name(consortium_name)
    else
      consortium_to_set = mi_attempt.consortium
    end

    self.mi_plan = MiPlan.where(
      :gene_id => gene.id,
      :production_centre_id => centre_to_set.id,
      :consortium_id => consortium_to_set.id
    ).first
  end

  # END Callbacks

  def status_name; status.name; end

  def consortium_name
    if ! @consortium_name.blank?
      return @consortium_name
    else
      if self.mi_plan
        @consortium_name = consortium.name
      end
    end
  end

  def consortium_name=(arg)
    @consortium_name = arg
  end

  def production_centre_name
    if ! @production_centre_name.blank?
      return @production_centre_name
    else
      if self.mi_plan
        @production_centre_name = production_centre.try(:name)
      end
    end
  end

  def production_centre_name=(arg)
    @production_centre_name = arg
  end

  def self.translations
    return {
      'marker_symbol' => 'mi_plan_gene_marker_symbol',
      'consortium' => 'mi_plan_consortium',
      'production_centre' => 'mi_plan_production_centre'
    }
  end
end

# == Schema Information
#
# Table name: phenotype_attempts
#
#  id                               :integer         not null, primary key
#  mi_attempt_id                    :integer         not null
#  status_id                        :integer         not null
#  is_active                        :boolean         default(TRUE), not null
#  rederivation_started             :boolean         default(FALSE), not null
#  rederivation_complete            :boolean         default(FALSE), not null
#  number_of_cre_matings_started    :integer         default(0), not null
#  number_of_cre_matings_successful :integer         default(0), not null
#  phenotyping_started              :boolean         default(FALSE), not null
#  phenotyping_complete             :boolean         default(FALSE), not null
#  created_at                       :datetime
#  updated_at                       :datetime
#  mi_plan_id                       :integer         not null
#  colony_name                      :string(125)     not null
#  mouse_allele_type                :string(2)
#  deleter_strain_id                :integer
#
# Indexes
#
#  index_phenotype_attempts_on_colony_name  (colony_name) UNIQUE
#

