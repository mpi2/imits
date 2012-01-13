class Public::PhenotypeAttempt < ::PhenotypeAttempt
  Status = ::PhenotypeAttempt::Status

  extend AccessAssociationByAttribute

  set_table_name 'phenotype_attempts'

  access_association_by_attribute :mi_attempt, :colony_name

  validates :mi_attempt_colony_name, :presence => true

  validate do |me|
    if me.changed.include?('mi_attempt_id') and ! me.new_record?
      me.errors.add :mi_attempt_colony_name, 'cannot be changed'
    end
  end

  validate :consortium_name_and_production_centre_name_from_mi_plan_validation

  def consortium_name
    @consortium_name
  end

  def consortium_name=(name)
    return @consortium_name = name
  end

  def production_centre_name
    @production_centre_name
  end

  def production_centre_name=(name)
    return @production_centre_name = name
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
#
# Indexes
#
#  index_phenotype_attempts_on_colony_name  (colony_name) UNIQUE
#

