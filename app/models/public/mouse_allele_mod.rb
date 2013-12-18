# encoding: utf-8

class Public::MouseAlleleMod < ::MouseAlleleMod

  extend ::AccessAssociationByAttribute
  include ::Public::Serializable
#  include ::Public::DistributionCentresAttributes
  include ::ApplicationModel::BelongsToMiPlan::Public

  FULL_ACCESS_ATTRIBUTES = %w{
    mi_plan_id
    consortium_name
    production_centre_name
    mi_attempt_colony_name
    status_stamps_attributes
    colony_name
    rederivation_started
    rederivation_complete
    number_of_cre_matings_successful
    no_modification_required
    mouse_allele_type
    deleter_strain_name
    colony_background_strain_name
    cre_excision_required
    tat_cre
    report_to_public
    is_active
}

  READABLE_ATTRIBUTES = %w{
    id
    status_name
    status_dates
    marker_symbol
    mouse_allele_symbol_superscript
    mouse_allele_symbol
    allele_symbol
    mi_attempt_colony_background_strain_name
    mi_attempt_colony_background_mgi_strain_accession_id
    mi_attempt_colony_background_mgi_strain_name
    colony_background_strain_mgi_accession
    colony_background_strain_mgi_name
    mgi_accession_id
  } + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*WRITABLE_ATTRIBUTES)

#  accepts_nested_attributes_for :distribution_centres, :allow_destroy => true

  access_association_by_attribute :mi_attempt, :colony_name
  access_association_by_attribute :deleter_strain, :name

  validates :mi_attempt_colony_name, :presence => true

  validate do |me|
    if me.changed.include?('mi_attempt_id') and ! me.new_record?
      me.errors.add :mi_attempt_colony_name, 'cannot be changed'
    end
  end

  validate do |me|
    if me.changes.has_key?('colony_name') and (! me.changes[:colony_name][0].nil?) and me.status.order_by >= PhenotypeAttempt::Status.find_by_code('pds').order_by #Phenotype Started
      me.errors.add(:phenotype_attempt, "colony_name can not be changed once phenotyping has started")
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
# Table name: mouse_allele_mods
#
#  id                               :integer         not null, primary key
#  mi_plan_id                       :integer         not null
#  mi_attempt_id                    :integer         not null
#  status_id                        :integer         not null
#  rederivation_started             :boolean         default(FALSE), not null
#  rederivation_complete            :boolean         default(FALSE), not null
#  number_of_cre_matings_started    :integer         default(0), not null
#  number_of_cre_matings_successful :integer         default(0), not null
#  no_modification_required         :boolean         default(FALSE)
#  cre_excision                     :boolean         default(TRUE), not null
#  tat_cre                          :boolean         default(FALSE)
#  mouse_allele_type                :string(3)
#  allele_category                  :string(255)
#  deleter_strain_id                :integer
#  colony_background_strain_id      :integer
#  colony_name                      :string(125)     not null
#  is_active                        :boolean         default(TRUE), not null
#  report_to_public                 :boolean         default(TRUE), not null
#  phenotype_attempt_id             :integer
#  created_at                       :datetime        not null
#  updated_at                       :datetime        not null
#

