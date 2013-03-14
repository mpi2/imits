# encoding: utf-8

class Public::PhenotypeAttempt < ::PhenotypeAttempt

  extend ::AccessAssociationByAttribute
  include ::Public::Serializable
  include ::Public::DistributionCentresAttributes
  include ::ApplicationModel::BelongsToMiPlan::Public

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
    colony_background_strain_name
    cre_excision_required
    tat_cre
    mi_plan_id
  }

  READABLE_ATTRIBUTES = %w{
    id
    distribution_centres_formatted_display
    status_name
    status_dates
    marker_symbol
    mouse_allele_symbol_superscript
    mouse_allele_symbol
  } + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*WRITABLE_ATTRIBUTES)

  accepts_nested_attributes_for :distribution_centres, :allow_destroy => true

  access_association_by_attribute :mi_attempt, :colony_name
  access_association_by_attribute :deleter_strain, :name

  validates :mi_attempt_colony_name, :presence => true

  validate do |me|
    if me.changed.include?('mi_attempt_id') and ! me.new_record?
      me.errors.add :mi_attempt_colony_name, 'cannot be changed'
    end
  end

  # BEGIN Callbacks

  # END Callbacks

  def status_name; status.name; end

  def status_dates
    retval = reportable_statuses_with_latest_dates
    retval.each do |status_name, date|
      retval[status_name] = date.to_s
    end
    return retval
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
#  colony_background_strain_id      :integer
#  cre_excision_required            :boolean         default(TRUE), not null
#  tat_cre                          :boolean         default(FALSE)
#
# Indexes
#
#  index_phenotype_attempts_on_colony_name  (colony_name) UNIQUE
#
