# encoding: utf-8

class Public::PhenotypingProduction < ::PhenotypingProduction

  extend ::AccessAssociationByAttribute
  include ::Public::Serializable
  include ::ApplicationModel::BelongsToMiPlan::Public

  FULL_ACCESS_ATTRIBUTES = %w{
    mi_plan_id
    consortium_name
    phenotyping_centre_name
    outsourced_by_plan_id
    production_colony_name
    mouse_allele_symbol
    colony_name
    rederivation_started
    rederivation_complete
    colony_background_strain_name
    phenotyping_experiments_started
    phenotyping_started
    phenotyping_complete
    report_to_public
    is_active
    ready_for_website
    cohort_production_centre_name
    _destroy
}

  READABLE_ATTRIBUTES = %w{
    id

    marker_symbol
    mgi_accession_id
    parent_colony_background_strain_name

    phenotype_attempt_id
    production_centre_name
    production_consortium_name
    status_name
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
      'production_consortium_name'  => 'parent_colony_mouse_allele_mod_mi_plan_consortium_name_or_parent_colony_mi_attempt_mi_plan_consortium_name',
      'production_centre_name'      => 'parent_colony_mouse_allele_mod_mi_plan_production_centre_name_or_parent_colony_mi_attempt_mi_plan_production_centre_name',
      'phenotyping_consortium_name' => 'mi_plan_consortium_name',
      'phenotyping_centre_name'     => 'mi_plan_production_centre_name'
    }

  end

  def production_colony_name
    parent_colony_name
  end

  def production_colony_name=(arg)
    parent_colony_name = arg
  end

  def status_name; status.try(:name); end

end

# == Schema Information
#
# Table name: phenotyping_productions
#
#  id                              :integer          not null, primary key
#  mi_plan_id                      :integer          not null
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
#  parent_colony_id                :integer
#  colony_background_strain_id     :integer
#  rederivation_started            :boolean          default(FALSE), not null
#  rederivation_complete           :boolean          default(FALSE), not null
#  cohort_production_centre_id     :integer
#  accredited_to_id                :integer
#
