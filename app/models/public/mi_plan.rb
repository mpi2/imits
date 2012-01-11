# encoding: utf-8

class Public::MiPlan < ::MiPlan
  extend AccessAssociationByAttribute

  Priority = ::MiPlan::Priority
  SubProject = ::MiPlan::SubProject
  Status = ::MiPlan::Status

  FULL_ACCESS_ATTRIBUTES = [
    'marker_symbol',
    'consortium_name',
    'production_centre_name',
    'priority_name',
    'number_of_es_cells_starting_qc',
    'number_of_es_cells_passing_qc',
    'withdrawn',
    'sub_project_name'
  ]

  READABLE_ATTRIBUTES = [
    'id',
    'status_name'
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

  validate do |plan|
    if !plan.new_record? and plan.changes.has_key? 'consortium_id'
      plan.errors.add(:consortium_name, 'cannot be changed')
    end

    if !plan.new_record? and plan.changes.has_key? 'gene_id'
      plan.errors.add(:marker_symbol, 'cannot be changed')
    end

    if plan.changes.has_key? 'production_centre_id' and ! plan.mi_attempts.empty?
      plan.errors.add(:production_centre_name, 'cannot be changed - gene has been micro-injected on behalf of production centre already')
    end
  end

  def as_json(options = {})
    options ||= {}
    options.symbolize_keys!

    options[:methods] = READABLE_ATTRIBUTES
    options[:only] = options[:methods]
    return super(options)
  end

end
