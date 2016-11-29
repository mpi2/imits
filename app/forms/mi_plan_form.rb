# encoding: utf-8
class MiPlanForm
  include AcceptNestedAttributes

  WRITABLE_ATTRIBUTES = %w{
    marker_symbol
    consortium_name
    production_centre_name
    sub_project_name
    priority_name
    mutagenesis_via_crispr_cas9
    phenotype_only
    withdrawn
    is_active
    number_of_es_cells_starting_qc
    number_of_es_cells_passing_qc
    number_of_es_cells_received
    es_cells_received_on
    es_cells_received_from_id
    es_cells_received_from_name
    is_bespoke_allele
    is_conditional_allele
    is_deletion_allele
    is_cre_knock_in_allele
    is_cre_bac_allele
    conditional_tm1c
    recovery
    point_mutation
    conditional_point_mutation
    es_qc_comment_name
    comment
    ignore_available_mice
    completion_note
    completion_comment
    report_to_public
  }

  WRITABLE_ATTRIBUTES.each do |attr|
    define_method(attr) do
        if @params.has_key?(attr)
          return @params[attr]
        else
          @form_model.send(attr)
      end
    end
  end

  def initialize(mi_plan, params)
  	raise 'Please provide model and params' if mi_plan.blank? || params.blank?
  	@form_model = mi_plan
    
    # Store Form Objects populated from attributes params designed to update attributes in associated models

    # params received
  	@params = params

 #   process_attributes_params
  end

### FORM VALIDATION
#  validates :marker_symbol, :presence => true
#  validates :consortium_name, :presence => true
#  validates :production_centre_name, :presence => {:on => :update, :if => proc {|p| p.changed.include?('production_centre_id')}}
#  validates :priority_name, :presence => true
#
#  validate do |plan|
#    if !plan.new_record? and plan.changes.has_key? 'consortium_id'
#      if plan.mi_attempts.size > 0
#        plan.errors.add(:consortium_name, 'cannot be changed (has micro-injection attempts)')
#      end
#      if plan.phenotype_attempts.size > 0
#        plan.errors.add(:consortium_name, 'cannot be changed (has phenotype attempts)')
#      end
#    end
#  end
#
#  validate do |plan|
#    if !plan.new_record? and plan.changes.has_key? 'gene_id'
#      plan.errors.add(:marker_symbol, 'cannot be changed')
#    end
#
#    if plan.changes.has_key? 'production_centre_id' and ! plan.mi_attempts.empty?
#      plan.errors.add(:production_centre_name, 'cannot be changed - gene has been micro-injected on behalf of production centre already')
#    end
#  end

#  access_association_by_attribute :es_cells_received_from, :name
#  access_association_by_attribute :consortium, :name
#  access_association_by_attribute :production_centre, :name
#  access_association_by_attribute :sub_project, :name
#  access_association_by_attribute :priority, :name
#  access_association_by_attribute :es_qc_comment, :name
#  access_association_by_attribute :gene, :marker_symbol, :full_alias => :marker_symbol

#  def update_es_cell_received
#    if number_of_es_cells_received.blank? && number_of_es_cells_starting_qc.to_i > 0
#      return if centre_pipeline.blank?
#      return if es_cell_qc_in_progress_date.blank?
#      self.number_of_es_cells_received = number_of_es_cells_starting_qc
#      self.es_cells_received_on = es_cell_qc_in_progress_date
#      self.es_cells_received_from_name = centre_pipeline
#    end
#  end


#  def check_completion_note
#    self.completion_note = '' if self.completion_note.blank?
#
#    if ! MiPlan.get_completion_note_enum.include?(self.completion_note)
#      legal_values = MiPlan.get_completion_note_enum.map { |k| "'#{k}'" }.join(', ')
#      self.errors.add :completion_note, "recognised values are #{legal_values}"
#    end
#  end

#  def set_default_number_of_es_cells_starting_qc
#    if number_of_es_cells_starting_qc.nil?
#      self.number_of_es_cells_starting_qc = number_of_es_cells_passing_qc
#    end
#  end

end
