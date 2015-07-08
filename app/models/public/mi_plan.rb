# encoding: utf-8

class Public::MiPlan < ::MiPlan
  extend ::AccessAssociationByAttribute
  include ::Public::Serializable

  FULL_ACCESS_ATTRIBUTES = [
    'marker_symbol',
    'consortium_name',
    'production_centre_name',
    'priority_name',
    'number_of_es_cells_starting_qc',
    'number_of_es_cells_passing_qc',
    'withdrawn',
    'sub_project_name',
    'is_active',
    'is_bespoke_allele',
    'es_qc_comment_name',
    'is_conditional_allele',
    'is_deletion_allele',
    'is_cre_knock_in_allele',
    'is_cre_bac_allele',
    'comment',
    'phenotype_only',
    'conditional_tm1c',
    'ignore_available_mice',
    'completion_note',
    'recovery',
    'status_stamps_attributes',
    'number_of_es_cells_received',
    'es_cells_received_on',
    'es_cells_received_from_id',
    'es_cells_received_from_name',
    'point_mutation',
    'conditional_point_mutation',
    'allele_symbol_superscript',
    'report_to_public',
    'completion_comment',
    'mutagenesis_via_crispr_cas9'
  ]

  READABLE_ATTRIBUTES = [
    'id',
    'status_name',
    'status_dates',
    'mgi_accession_id',
    'mi_attempts_count',
    'phenotype_attempts_count'
  ] + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*WRITABLE_ATTRIBUTES)

  access_association_by_attribute :sub_project, :name
  access_association_by_attribute :gene, :marker_symbol, :full_alias => :marker_symbol
  access_association_by_attribute :consortium, :name
  access_association_by_attribute :production_centre, :name
  access_association_by_attribute :priority, :name
  access_association_by_attribute :es_qc_comment, :name

  validates :marker_symbol, :presence => true
  validates :consortium_name, :presence => true
  validates :production_centre_name, :presence => {:on => :update, :if => proc {|p| p.changed.include?('production_centre_id')}}
  validates :priority_name, :presence => true
  validates :number_of_es_cells_starting_qc, :presence => {
    :on => :update,
    :if => proc {|p| p.changed.include?('number_of_es_cells_starting_qc')},
    :message => 'cannot be unset after being set'
  }

  validate do |plan|
    if !plan.new_record? and plan.changes.has_key? 'gene_id'
      plan.errors.add(:marker_symbol, 'cannot be changed')
    end

    if plan.changes.has_key? 'production_centre_id' and ! plan.mi_attempts.empty?
      plan.errors.add(:production_centre_name, 'cannot be changed - gene has been micro-injected on behalf of production centre already')
    end
  end

  validate do |plan|
    if !plan.new_record? and plan.changes.has_key? 'consortium_id'
      if plan.mi_attempts.size > 0
        plan.errors.add(:consortium_name, 'cannot be changed (has micro-injection attempts)')
      end
      if plan.phenotype_attempts.size > 0
        plan.errors.add(:consortium_name, 'cannot be changed (has phenotype attempts)')
      end
    end
  end

  validate do |plan|
    if plan.mi_attempts.size > 0
      if plan.changes.has_key? 'phenotype_only' and plan.phenotype_only
        plan.errors.add(:phenotype_only, 'cannot be set (has micro-injection_attempts)')
      elsif plan.phenotype_only
        plan.errors.add(:phenotype_only, 'This MiPlan is phenotype only. You cannot add MiAttempts.')
      end
    end
  end

  validate do |plan|
    if plan.changes.has_key?('mutagenesis_via_crispr_cas9')
      if plan.mutagenesis_via_crispr_cas9 && plan.number_of_es_cells_starting_qc > 0
        plan.errors.add(:base, 'This is an ES Cell plan. Please create a new plan to indicate use of the mutagenesis via CRISPR CAS9 strategy to target this gene.')
      elsif plan.mi_attempts.size > 0
        if plan.mutagenesis_via_crispr_cas9 && plan.mi_attempts.any? {|mi| !mi.es_cell_id.blank?}
          plan.errors.add(:mutagenesis_via_crispr_cas9, 'cannot be changed. ES Cell Micro-injections exist. Please create a new plan to indicate use of the mutagenesis via CRISPR CAS9 strategy to target this gene.')
        elsif ! plan.mutagenesis_via_crispr_cas9 && plan.mi_attempts.any? {|mi| mi.es_cell_id.blank?}
         plan.errors.add(:mutagenesis_via_crispr_cas9, 'cannot be changed. CRISPR Micro-injections exist. Please create a new plan to indicate use of the ES Cell strategy to target this gene.')
        end
      end
    end
  end

  def self.translations
    return {
      'marker_symbol' => 'gene_marker_symbol',
      'mgi_accession_id' => 'gene_mgi_accession_id',
      'es_cell_name' => 'gene_allele_es_cells_name'
    }
  end

  def status_dates
    retval = reportable_statuses_with_latest_dates
    retval.each do |status_name, date|
      retval[status_name] = date.to_s
    end
    return retval
  end

  def mgi_accession_id; gene.mgi_accession_id; end

  def mi_attempts_count
    mi_attempts.size
  end

  def status_name
    return status.name
  end

  def phenotype_attempts_count
    phenotype_attempts.size
  end
end

# == Schema Information
#
# Table name: mi_plans
#
#  id                             :integer          not null, primary key
#  gene_id                        :integer          not null
#  consortium_id                  :integer          not null
#  status_id                      :integer          not null
#  priority_id                    :integer
#  production_centre_id           :integer
#  created_at                     :datetime
#  updated_at                     :datetime
#  number_of_es_cells_starting_qc :integer
#  number_of_es_cells_passing_qc  :integer
#  sub_project_id                 :integer          not null
#  is_active                      :boolean          default(TRUE), not null
#  is_bespoke_allele              :boolean          default(FALSE), not null
#  is_conditional_allele          :boolean          default(FALSE), not null
#  is_deletion_allele             :boolean          default(FALSE), not null
#  is_cre_knock_in_allele         :boolean          default(FALSE), not null
#  is_cre_bac_allele              :boolean          default(FALSE), not null
#  comment                        :text
#  withdrawn                      :boolean          default(FALSE), not null
#  es_qc_comment_id               :integer
#  phenotype_only                 :boolean          default(FALSE)
#  completion_note                :string(100)
#  recovery                       :boolean
#  conditional_tm1c               :boolean          default(FALSE), not null
#  ignore_available_mice          :boolean          default(FALSE), not null
#  number_of_es_cells_received    :integer
#  es_cells_received_on           :date
#  es_cells_received_from_id      :integer
#  point_mutation                 :boolean          default(FALSE), not null
#  conditional_point_mutation     :boolean          default(FALSE), not null
#  allele_symbol_superscript      :text
#  report_to_public               :boolean          default(TRUE), not null
#  completion_comment             :text
#  mutagenesis_via_crispr_cas9    :boolean          default(FALSE)
#
# Indexes
#
#  mi_plan_logical_key  (gene_id,consortium_id,production_centre_id,sub_project_id,is_bespoke_allele,is_conditional_allele,is_deletion_allele,is_cre_knock_in_allele,is_cre_bac_allele,conditional_tm1c,phenotype_only,mutagenesis_via_crispr_cas9) UNIQUE
#
