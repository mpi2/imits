# encoding: utf-8

class Public::PhenotypeAttempt < ::PhenotypeAttempt

  extend AccessAssociationByAttribute

  FULL_ACCESS_ATTRIBUTES = [
    'consortium_name',
    'production_centre_name',
    'mi_attempt_colony_name',
    'is_active',
    'rederivation_started',
    'rederivation_complete',
    'number_of_cre_matings_started',
    'number_of_cre_matings_successful',
    'phenotyping_started',
    'phenotyping_complete'
  ]

  READABLE_ATTRIBUTES = [
    'id',
    'status_name'
  ] + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*FULL_ACCESS_ATTRIBUTES)

  access_association_by_attribute :mi_attempt, :colony_name

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
      centre = Centre.find_by_name(production_centre_name)
    else
      centre = mi_attempt.mi_plan.production_centre
    end

    if consortium_name
      consortium = Consortium.find_by_name(consortium_name)
    else
      consortium = mi_attempt.mi_plan.consortium
    end

    self.mi_plan = MiPlan.where(
      :gene_id => gene.id,
      :production_centre_id => centre.id,
      :consortium_id => consortium.id
    ).first
  end

  # END Callbacks

  attr_accessor :consortium_name, :production_centre_name

  def as_json(options = {})
    options ||= {}
    options.symbolize_keys!

    options[:methods] = READABLE_ATTRIBUTES
    options[:only] = options[:methods]
    return super(options)
  end

  def status_name; status.name; end
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
#
# Indexes
#
#  index_phenotype_attempts_on_colony_name  (colony_name) UNIQUE
#

