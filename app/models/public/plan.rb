class Public::Plan < ::Plan

  include ::Public::Serializable
  include ::Public::PlanIntentionsAttributes

  FULL_ACCESS_ATTRIBUTES = %w{
    marker_symbol
    consortium_name
    production_centre_name
    default_sub_project_name
    priority_name
    es_cell_qc_intent
    es_cell_mi_attempt_intent
    nuclease_mi_attempt_intent
    mouse_allele_modification_intent
    phenotyping_intent
    number_of_es_cells_received
    es_cells_received_on
    es_cells_received_from_name
    number_of_es_cells_starting_qc
    number_of_es_cells_passing_qc
    es_qc_comment_name
    completion_note
    completion_comment
    plan_intentions_attributes
}

  READABLE_ATTRIBUTES = %w{
    id
    mi_attempts_count
    mouse_allele_modification_count
    phenotyping_count
    conflicts
    conflict_summary
  } + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*WRITABLE_ATTRIBUTES)

  accepts_nested_attributes_for :plan_intentions

  after_save :update_intentions
  after_save :update_es_cell_delivery_and_qc


  ## VALIDATION
  # validate attributes, which are used in logic that update other tables
  validate do |plan|
    if !plan.default_sub_project_name.blank? && SubProject.find_by_name(plan.default_sub_project_name).blank?
      plan.errors.add :base, "#{plan.default_sub_project_name} is an invalid Sub Project"
    end

    if !plan.priority_name.blank? && EsCellQc::Priority.find_by_name(plan.priority_name).blank?
      plan.errors.add :base, "#{plan.priority_name} is an invalid Prioity"
    end

    if !plan.es_cells_received_from_name.blank? && TargRep::CentrePipeline.find_by_name(plan.es_cells_received_from_name).blank?
      plan.errors.add :base, "#{plan.es_cells_received_from_name} is an invalid ES Cell Distribution Centre"
    end

    if !plan.es_qc_comment_name.blank? && EsCellQc::Comment.find_by_name(plan.es_qc_comment_name).blank?
      plan.errors.add :base, "#{plan.es_qc_comment_name} is an invalid QC Comment"
    end

    if !plan.number_of_es_cells_received.blank?
      if plan.es_cells_received_on.blank?
        plan.errors.add(:es_cells_received_on, 'cannot be blank if \'number_of_es_cells_received\' has a value')
      end

      if plan.es_cells_received_from_name.blank?
        plan.errors.add(:es_cells_received_from, 'cannot be blank if \'number_of_es_cells_received\' has a value')
      end
    end

    if ! plan.number_of_es_cells_starting_qc.blank? && ! plan.number_of_es_cells_passing_qc.blank?
      if plan.number_of_es_cells_starting_qc < plan.number_of_es_cells_passing_qc
        plan.errors.add :number_of_es_cells_passing_qc, "passing qc exceeds starting qc"
      end
    end
  end

  #after_save methods
  def update_intentions
    begin
      if !@es_cell_qc_intent.nil? && @es_cell_qc_intent != (!qc_es_cell_intention.blank? && !qc_es_cell_intention.withdrawn? && qc_es_cell_intention.assigned?)
        self.class.update_intention_by_boolean(self, 'ES Cell QC', @es_cell_qc_intent)
      end
       if !@es_cell_mi_attempt_intent.nil? && @es_cell_mi_attempt_intent != (!micro_injected_es_cell_intention.blank? && !micro_injected_es_cell_intention.withdrawn? && micro_injected_es_cell_intention.assigned?)
         self.class.update_intention_by_boolean(self, 'ES Cell Micro Injection', @es_cell_mi_attempt_intent)
       end
       if !@nuclease_mi_attempt_intent.nil? && @nuclease_mi_attempt_intent != (!micro_injected_nuclease_intention.blank? && !micro_injected_nuclease_intention.withdrawn? && micro_injected_nuclease_intention.assigned?)
         self.class.update_intention_by_boolean(self, 'CRISPR Micro Injection', @nuclease_mi_attempt_intent)
       end
       if !@mouse_allele_modification_intent.nil? && @mouse_allele_modification_intent != (!modify_mice_allele_intention.blank? && !modify_mice_allele_intention.withdrawn? && modify_mice_allele_intention.assigned?)
         self.class.update_intention_by_boolean(self, 'Allele Modification', @mouse_allele_modification_intent)
       end
       if !@phenotyping_intent.nil? && @phenotyping_intent != (!phenotype_mice_intention.blank? && !phenotype_mice_intention.withdrawn? && phenotype_mice_intention.assigned?)
         self.class.update_intention_by_boolean(self, 'Phenotyping', @phenotyping_intent)
       end
    rescue
      puts 'Could not update Plan\'s intentions'
    end
  end

  def update_es_cell_delivery_and_qc
    return true if [self.number_of_es_cells_received,
                   self.priority_name,
                   self.es_cells_received_from_name,
                   self.es_cells_received_on,
                   self.number_of_es_cells_starting_qc,
                   self.number_of_es_cells_passing_qc,
                   self.es_qc_comment_name].all?{|attr| attr.blank?}

    es_cell_qc_to_update = self.es_cell_qc
    es_cell_qc_to_update = EsCellQc.new(:plan_id => self.id) if es_cell_qc_to_update.blank?

    return false if es_cell_qc_to_update.blank?

    es_cell_qc_to_update.priority_name = self.priority_name
    es_cell_qc_to_update.number_of_es_cells_received = self.number_of_es_cells_received
    es_cell_qc_to_update.es_cells_received_from_name = self.es_cells_received_from_name 
    es_cell_qc_to_update.es_cells_received_on = self.es_cells_received_on 
    es_cell_qc_to_update.number_of_es_cells_starting_qc = self.number_of_es_cells_starting_qc
    es_cell_qc_to_update.number_of_es_cells_passing_qc = self.number_of_es_cells_passing_qc
    es_cell_qc_to_update.comment_name = self.es_qc_comment_name

    return false unless es_cell_qc_to_update.valid?
    return es_cell_qc_to_update.save
  end

  def self.update_intention_by_boolean(plan, intention_name, value)
    pi = PlanIntention.joins(:intention).where("intentions.name = '#{intention_name}' AND plan_id = #{plan.id}")
    pi = PlanIntention.find(pi.first.id) unless pi.blank?
    intention = Intention.find_by_name(intention_name)
    raise 'Invalid Intention' if intention.blank?
    if value == true
      if pi.blank?
        pi = PlanIntention.new({:plan_id => plan.id, :intention_id => intention.id})
        pi.sub_project_name = plan.default_sub_project_name unless plan.default_sub_project_name.blank?
      end
      pi.assign = true
      pi.withdrawn = false
    else
      return true if pi.blank?
      pi.withdrawn = true
    end
    return false unless pi.valid?
    return pi.save
  end

## Attribute methods
  def default_sub_project_name
    # return value set by user
    return @default_sub_project_name unless @default_sub_project_name.blank?

    #return subproject allocated to other intentions for this gene/plan
    sub_projects = plan_intentions.map{|pi| pi.sub_project_name}.select{|spn| !spn.blank?}
    return sub_projects.first unless sub_projects.blank?

    #return 'MGPinterest' if consortia is 'MGP'
    return SubProject.find_by_name!('MGPinterest') if self.consortium.name == 'MGP'

    #return nil if no default found
    return nil
  end
  
  def default_sub_project_name=(arg)
    return nil if arg.blank?
    @default_sub_project_name = arg 
  end

  def es_cell_qc_intent
    return @es_cell_qc_intent unless @es_cell_qc_intent.nil?
    if !qc_es_cell_intention.blank? && !qc_es_cell_intention.withdrawn? && qc_es_cell_intention.assigned?
      return true 
    end
    false
  end

  def es_cell_qc_intent=(arg)
    @es_cell_qc_intent = arg
  end

  def es_cell_mi_attempt_intent
    return @es_cell_mi_attempt_intent unless @es_cell_mi_attempt_intent.nil?
    if !micro_injected_es_cell_intention.blank? && !micro_injected_es_cell_intention.withdrawn? && micro_injected_es_cell_intention.assigned?
      return true 
    end
    false
  end

  def es_cell_mi_attempt_intent=(arg)
    @es_cell_mi_attempt_intent = arg
  end

  def nuclease_mi_attempt_intent
    return @nuclease_mi_attempt_intent unless @nuclease_mi_attempt_intent.nil?
    if !micro_injected_nuclease_intention.blank? && !micro_injected_nuclease_intention.withdrawn? && micro_injected_nuclease_intention.assigned?
      return true 
    end
    false
  end

  def nuclease_mi_attempt_intent=(arg)
    @nuclease_mi_attempt_intent = arg
  end

  def mouse_allele_modification_intent
    return @mouse_allele_modification_intent unless @mouse_allele_modification_intent.nil?
    if !modify_mice_allele_intention.blank? && !modify_mice_allele_intention.withdrawn? && modify_mice_allele_intention.assigned?
      return true 
    end
    false
  end

  def mouse_allele_modification_intent=(arg)
    @mouse_allele_modification_intent = arg
  end

  def phenotyping_intent
    return @phenotyping_intent unless @phenotyping_intent.nil?
    if !phenotype_mice_intention.blank? && !phenotype_mice_intention.withdrawn? && phenotype_mice_intention.assigned?
      return true 
    end
    false
  end

  def phenotyping_intent=(arg)
    @phenotyping_intent = arg
  end

  def bespoke_allele
    get_allele_intention('bespoke_allele')
  end

  def recovery_allele
    get_allele_intention('recovery_allele')
  end

  def conditional_allele
    get_allele_intention('conditional_allele')
  end

  def non_conditional_allele
    get_allele_intention('non_conditional_allele')
  end

  def cre_knock_in_allele
    get_allele_intention('cre_knock_in_allele')
  end

  def cre_bac_allele
    get_allele_intention('cre_bac_allele')
  end

  def deletion_allele
    get_allele_intention('deletion_allele')
  end

  def point_mutation_allele
    get_allele_intention('point_mutation_allele')
  end

  def conditional_point_mutation_allele
    get_allele_intention('conditional_point_mutation_allele')
  end

  def conditional_tm1c_allele
    get_allele_intention('conditional_tm1c_allele')
  end

  def get_allele_intention(attr)
    return nil if qc_es_cell_intention.blank? && micro_injected_es_cell_intention.blank?

    if !instance_variable_get("@#{attr}").nil?
        return instance_variable_get("@#{attr}")
    end
    return es_cell_qc.send("#{attr}") unless es_cell_qc.blank?
    #default to false
    return false
  end
  private :get_allele_intention


  def number_of_es_cells_received 
    return @number_of_es_cells_received unless @number_of_es_cells_received.nil?
    if !es_cell_qcs.blank?
      return es_cell_qcs.first.number_of_es_cells_received
    end
    nil
  end

  def number_of_es_cells_received=(arg)
    @number_of_es_cells_received = arg
  end

  def priority_name
    return @priority_name unless @priority_name.blank?
    return nil if es_cell_qc.blank?
    es_cell_qc.priority_name
  end

  def priority_name=(arg)
    @priority_name = arg unless arg.blank?
  end

  def es_cells_received_from_name 
    return @es_cells_received_from_name unless @es_cells_received_from_name.nil?
    if !es_cell_qcs.blank?
      return es_cell_qcs.first.es_cells_received_from_name
    end
    nil
  end

  def es_cells_received_from_name=(arg)
    @es_cells_received_from_name = arg
  end

  def es_cells_received_on 
    return @es_cells_received_on unless @es_cells_received_on.nil?
    if !es_cell_qcs.blank?
      return es_cell_qcs.first.es_cells_received_on
    end
    nil
  end

  def es_cells_received_on=(arg)
    @es_cells_received_on = arg
  end

  def number_of_es_cells_starting_qc
    return @number_of_es_cells_starting_qc unless @number_of_es_cells_starting_qc.nil?
    if !es_cell_qcs.blank?
      return es_cell_qcs.first.number_of_es_cells_starting_qc
    end
    nil
  end

  def number_of_es_cells_starting_qc=(arg)
    @number_of_es_cells_starting_qc = arg
  end

  def number_of_es_cells_passing_qc
    return @number_of_es_cells_passing_qc unless @number_of_es_cells_passing_qc.nil?
    if !es_cell_qcs.blank?
      return es_cell_qcs.first.number_of_es_cells_passing_qc
    end
    nil
  end

  def number_of_es_cells_passing_qc=(arg)
    @number_of_es_cells_passing_qc = arg
  end

  def es_qc_comment_name
    return @es_qc_comment_name unless @es_qc_comment_name.nil?
    if !es_cell_qcs.blank?
      return es_cell_qcs.first.comment_name
    end
    nil
  end

  def es_qc_comment_name=(arg)
    @es_qc_comment_name = arg
  end

  def completion_note
    return @completion_note unless @completion_note.nil?
    if !es_cell_qcs.blank?
      return es_cell_qcs.first.completion_note
    end
    nil
  end

  def completion_note=(arg)
    @completion_note = arg
  end

  def completion_comment
    return @completion_comment unless @completion_comment.nil?
    if !es_cell_qcs.blank?
      return es_cell_qcs.first.completion_comment
    end
    nil
  end

  def completion_comment=(arg)
    @completion_comment = arg
  end

  def mi_attempts_count
    1
  end

  def mouse_allele_modification_count
    1
  end
  
  def phenotyping_count
    1
  end

  def conflicts
    if plan_intentions.any?{|pi| pi.conflict == true}
      'Yes'
    else
      'No'
    end
  end

  def conflict_summary
    if conflicts == 'Yes'
      mesg_str = ''
      mesg_str << 'Mouse Production Conflict</br>' if micro_injected_es_cell_intention.try(:conflict) || micro_injected_nuclease_intention.try(:conflict)
      mesg_str << 'Allele Modification Conflict</br>' if modify_mice_allele_intention.try(:conflict)
      mesg_str << 'Phenotyping Conflict</br>' if phenotype_mice_intention.try(:conflict)
      return mesg_str
    end
    return ''  
  end

  def self.get_completion_note_enum
    ["Handoff complete", "Allele not needed", "Effort concluded"]
  end

  def self.translations
    return {
      'marker_symbol' => 'gene_marker_symbol',
      'es_cell_qc_intent' => 'qcesci_not_withdrawn_assign',
      'es_cell_mi_attempt_intent' => 'miesci_not_withdrawn_assign',
      'nuclease_mi_attempt_intent' => 'mini_not_withdrawn_assign',
      'mouse_allele_modification_intent' => 'mmai_not_withdrawn_assign',
      'phenotyping_intent' => 'pmi_not_withdrawn_assign',
      'conflicts' => 'qc_es_cell_intention_conflict_or_micro_injected_es_cell_intention_conflict_or_micro_injected_nuclease_intention_conflict_or_modify_mice_allele_intention_conflict_or_phenotype_mice_intention_conflict'
    }
  end
end

# == Schema Information
#
# Table name: plans
#
#  id                   :integer          not null, primary key
#  gene_id              :integer          not null
#  consortium_id        :integer
#  production_centre_id :integer
#
