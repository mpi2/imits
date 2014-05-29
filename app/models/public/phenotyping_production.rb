# encoding: utf-8

class Public::PhenotypingProduction < ::PhenotypingProduction

  extend ::AccessAssociationByAttribute
  include ::Public::Serializable
  include ::ApplicationModel::BelongsToMiPlan::Public

  FULL_ACCESS_ATTRIBUTES = %w{
    mi_plan_id
    consortium_name
    production_centre_name
    colony_name
    phenotyping_experiments_started
    phenotyping_started
    phenotyping_complete
    report_to_public
    is_active
    ready_for_website
    _destroy
}

  READABLE_ATTRIBUTES = %w{
    id
    status_name
    mouse_allele_mod_status_name
  } + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*WRITABLE_ATTRIBUTES)

  # BEGIN Callbacks

  # END Callbacks

  def self.translations
    return {
      'marker_symbol' => 'mi_plan_gene_marker_symbol',
      'consortium' => 'mi_plan_consortium',
      'production_centre' => 'mi_plan_production_centre'
    }
  end

  def status_name; status.name; end

  def mouse_allele_mod_status_name; mouse_allele_mod.status.name; end
end

# == Schema Information
#
# Table name: phenotyping_productions
#
#  id                              :integer          not null, primary key
#  mi_plan_id                      :integer          not null
#  mouse_allele_mod_id             :integer          not null
#  status_id                       :integer          not null
#  colony_name                     :string(255)
#  phenotyping_experiments_started :date
#  phenotyping_started             :boolean          default(FALSE), not null
#  phenotyping_complete            :boolean          default(FALSE), not null
#  is_active                       :boolean          default(TRUE), not null
#  report_to_public                :boolean          default(TRUE), not null
#  phenotype_attempt_id            :integer
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  ready_for_website               :date
#