# encoding: utf-8

class Public::MiPlan < ::MiPlan
  extend AccessAssociationByAttribute
  include Public::Serializable

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
    'is_bespoke_allele'
  ]

  READABLE_ATTRIBUTES = [
    'id',
    'status_name',
    'status_dates',
    'mgi_accession_id',
    'mi_attempts_count'
  ] + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*FULL_ACCESS_ATTRIBUTES)

  access_association_by_attribute :sub_project, :name
  access_association_by_attribute :gene, :marker_symbol, :full_alias => :marker_symbol
  access_association_by_attribute :consortium, :name
  access_association_by_attribute :production_centre, :name
  access_association_by_attribute :priority, :name
  access_association_by_attribute :status, :name

  validates :marker_symbol, :presence => true
  validates :consortium_name, :presence => true
  validates :production_centre_name, :presence => {:on => :update, :if => proc {|p| p.changed.include?('production_centre_id')}}
  validates :priority_name, :presence => true
  validates :number_of_es_cells_starting_qc, :presence => {
    :on => :update,
    :if => proc {|p| p.changed.include?('number_of_es_cells_starting_qc')},
    :message => 'cannot be unset after being set'
  }
  validate :number_of_es_cells_passing_qc do |mi_plan|
    next if mi_plan.new_record?

    changes = mi_plan.changes['number_of_es_cells_passing_qc']
    if changes and changes[0] != nil
      if mi_plan.number_of_es_cells_passing_qc.blank?
        mi_plan.errors.add(:number_of_es_cells_passing_qc, 'cannot be unset after being set')
      elsif mi_plan.number_of_es_cells_passing_qc == 0
        mi_plan.errors.add(:number_of_es_cells_passing_qc, 'cannot be set to 0 after being set')
      end
    end
  end

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
        plan.errors.add(:consortium_name, 'cannot be changed (has Micro Injection Attempts)')
      end
    end
  end

  def self.translations
    return {
      'marker_symbol' => 'gene_marker_symbol',
      'mgi_accession_id' => 'gene_mgi_accession_id'
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
end

# == Schema Information
#
# Table name: mi_plans
#
#  id                             :integer         not null, primary key
#  gene_id                        :integer         not null
#  consortium_id                  :integer         not null
#  status_id                      :integer         not null
#  priority_id                    :integer         not null
#  production_centre_id           :integer
#  created_at                     :datetime
#  updated_at                     :datetime
#  number_of_es_cells_starting_qc :integer
#  number_of_es_cells_passing_qc  :integer
#  sub_project_id                 :integer         not null
#  is_active                      :boolean         default(TRUE), not null
#  is_bespoke_allele              :boolean         default(FALSE), not null
#
# Indexes
#
#  mi_plan_logical_key  (gene_id,consortium_id,production_centre_id,sub_project_id) UNIQUE
#
