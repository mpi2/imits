# encoding: utf-8

class PlanIntention < ApplicationModel
  acts_as_audited
  acts_as_reportable

# INHERTITED CODE
  include PlanIntention::StatusManagement
  include ApplicationModel::HasStatuses
  include ApplicationModel::BelongsToMiPlan

  extend AccessAssociationByAttribute



# ASSOCIATIONS
  belongs_to :intention
  belongs_to :plan
  belongs_to :status
  belongs_to :sub_project

  has_many :status_stamps, :order => "#{PlanIntention::StatusStamp.table_name}.created_at ASC", dependent: :destroy

  has_one :allele_intention, dependent: :destroy

  accepts_nested_attributes_for :status_stamps

  access_association_by_attribute :sub_project, :name
  access_association_by_attribute :intention, :name
  access_association_by_attribute :status, :name

# FILTERS
  before_validation :update_conflict_flag
  before_validation :change_status

  after_save :manage_status_stamps
  after_save :update_other_intentions_conflict_flags
# VALIDATION
  validates_uniqueness_of :intention_id, :scope => [:plan_id, :sub_project_id]

  validates :intention_id, :presence => true
  validates :plan, :presence => true
  validates :status, :presence => true

  # validate if Plan Intention can be witdrawn
  validate do |pi|
    return if withdrawn == false
    return if intention.blank?
    # call the corresponding validation for this intention type
    puts "#{intention.name.gsub(' ', '').underscore}_validate"
    pi.send("#{intention.name.gsub(' ', '').underscore}_validate")
  end


  def es_cell_qc_validate
    return if plan.blank?
    if !plan.es_cell_qcs.blank? && plan.es_cell_qcs.any?{|es_qc| ['ES Cell QC In Progress' , 'ES Cell QC Complete'].include?(es_qc.status.name)}
      self.errors.add :base, 'Intention to QC ES Cell cannot be set to withdrawn when there is an active ES Cell QC attempt'
    end
  end
  private :es_cell_qc_validate

  def es_cell_micro_injection_validate
    return if plan.blank?
    if !plan.es_cell_mi_attempts.blank? && plan.es_cell_mi_attempts.any?{|mi| mi.is_active}
      self.errors.add :base, 'Intention to Micro Inject ES Cell cannot be set to withdrawn when there are active Mi attempts'
    end
  end
  private :es_cell_micro_injection_validate

  def crispr_micro_injection_validate
    return if plan.blank?
    if !plan.crispr_mi_attempts.blank? && plan.crispr_mi_attempts.any?{|mi| mi.is_active}
      self.errors.add :base, 'Intention to Micro Inject CRISPRs cannot be set to withdrawn when there are active Mi attempts'
    end
  end
  private :crispr_micro_injection_validate

  def allele_modification_validate
    return if plan.blank?
    if !plan.mouse_allele_mods.blank? && plan.mouse_allele_mods.any?{|mam| mam.is_active}
      self.errors.add :base, 'Intention to Excise allele cannot be set to withdrawn when there are active Excision attempts'
    end
  end
  private :allele_modification_validate

  def phenotyping_validate
    return if plan.blank?
    if !plan.phenotyping_productions.blank? && plan.phenotyping_productions.any?{|pp| pp.is_active}
      self.errors.add :base, 'Intention to Phenotype cannot be set to withdrawn when there are active Phenotype attempts'
    end
  end
  private :phenotyping_validate
# FILTER METHODS

  def update_conflict_flag
#    if is_there_a_conflict? == true
#        self.conflict = true
#    else
#        self.conflict = false
#    end
  end
  private :update_conflict_flag

  def update_other_intentions_conflict_flags

#    find_conflicts.each do |pi|
#        pi_conflict = pi.is_there_a_conflict?
#        if pi_conflict == true && pi.conflict == false
#            update_column(conflict, true)
#        elsif pi_conflict == false && pi.conflict == true
#            update_column(conflict, false)
#        end
#    end
  end
  private :update_other_intentions_conflict_flags


# METHODS
  def is_there_a_conflict?
    # Cannot conflict with withdrawn intentions
    return true unless find_conflicts.blank?
    return false
  end
  private :is_there_a_conflict?

  def find_conflicts
#      return [] if self.intention.blank? || self.marker_symbol.blank?
#      return @intentions_for_same_gene ||= PlanIntention.joins(:intention, plan: :gene).where("genes.marker_symbol = #{self.marker_symbol} #{"AND plan_intentions.id != #{self.id}" unless self.id.blank?} AND intentions.name IN (#{Intention.conflict_mapping(self.intention.name)}) AND plan_intentions.withdrawn = false")
  end
  private :find_conflicts

  def conflict_message
    return nil unless is_there_a_conflict?
    pis = find_conflicts
 
    return self.conflict_message(pis)
  end

  def conflict?
   return true if conflict
   return false
  end

  def assigned?
   return true if assign
   return false
  end

  def withdrawn?
   return true if withdrawn
   return false
  end

  def glt_mi_attempt?
    
  end

  def mi_attempt_in_progress?
      
  end

  def priority_name
    return nil if intention.blank? || intention.name.blank? || intention.name != 'ES Cell Micro Injection'
    return @priority_name unless @priority_name.nil?
    return allele_intention.priority_name unless allele_intention.blank?
    return nil 
  end

  def bespoke_allele
    return nil if intention.blank? || intention.name.blank? || intention.name != 'ES Cell Micro Injection'
    return @bespoke_allele unless @bespoke_allele.nil?
    return allele_intention.bespoke_allele unless allele_intention.blank?
    return nil 
  end
  
  def recovery_allele
    return nil if intention.blank? || intention.name.blank? || !['ES Cell Micro Injection', 'CRISPR Micro Injection'].include?(intention.name)
    return @recovery_allele unless @recovery_allele.nil?
    return allele_intention.recovery_allele unless allele_intention.blank?
    return nil 
  end
  
  def cre_bac_allele
    return nil if intention.blank? || intention.name.blank? || intention.name != 'ES Cell Micro Injection'
    return @cre_bac_allele unless @cre_bac_allele.nil?
    return allele_intention.cre_bac_allele unless allele_intention.blank?
    return nil 
  end

  def conditional_allele
    return nil if intention.blank? || intention.name.blank? || intention.name != 'ES Cell Micro Injection'
    return @conditional_allele unless @conditional_allele.nil?
    return allele_intention.conditional_allele unless allele_intention.blank?
    return nil 
  end
  
  def non_conditional_allele
    return nil if intention.blank? || intention.name.blank? || intention.name != 'ES Cell Micro Injection'
    return @non_conditional_allele unless @non_conditional_allele.nil?
    return allele_intention.non_conditional_allele unless allele_intention.blank?
    return nil 
  end
  
  def cre_knock_in_allele
    return nil if intention.blank? || intention.name.blank? || intention.name != 'ES Cell Micro Injection'
    return @cre_knock_in_allele unless @cre_knock_in_allele.nil?
    return allele_intention.cre_knock_in_allele unless allele_intention.blank?
    return nil 
  end
  
  def deletion_allele
    return nil if intention.blank? || intention.name.blank? || !['ES Cell Micro Injection', 'CRISPR Micro Injection'].include?(intention.name)
    return @deletion_allele unless @deletion_allele.nil?
    return allele_intention.deletion_allele unless allele_intention.blank?
    return nil 
  end
  
  def point_mutation
    return nil if intention.blank? || intention.name.blank? || !['ES Cell Micro Injection', 'CRISPR Micro Injection'].include?(intention.name)
    return @point_mutation unless @point_mutation.nil?
    return allele_intention.point_mutation unless allele_intention.blank?
    return nil 
  end
  

# CLASS METHODS

  def self.conflict_message(pis)
    # Creates conflict messages for model instances and hashes generated by reports
    return nil if pis.blank?
    
    conflict_message_groups = {'GLT' => [], 'MIs' => [], 'Assigned' => [], 'Registered' => []}
    pis = find_conflicts

    pis.each do |pi|
      if pi.class.name == 'PlanIntention'
        if pi.glt_mi_attempt?
          conflict_message_groups['GLT'] << pi.production_centre_name
        elsif pi.mi_attempt_in_progress?
          conflict_message_groups['MIs'] << pi.production_centre_name  
        elsif pi.assigned?
          conflict_message_groups['Assigned'] << pi.production_centre_name
        else
          conflict_message_groups['Registered'] << pi.production_centre_name
        end
    
      else 
        if pi['glt_mi_attempt?'] == true
          conflict_message_groups['GLT'] << pi['production_centre_name']
        elsif pi['mi_attempt_in_progress?'] == true
          conflict_message_groups['MIs'] << pi['production_centre_name']
        elsif pi['assigned?'] == true
          conflict_message_groups['Assigned'] << pi['production_centre_name']
        else
          conflict_message_groups['Registered'] << pi['production_centre_name']
        end
      end
    end

    conflict_message = []
    conflict_message <<  "#{conflict_message_groups['GLT'].to_sentence} have produced a GLT mouse for this Gene"           if !conflict_message_groups['GLT'].blank && conflict_message_groups['GLT'].length > 1
    conflict_message <<  "#{conflict_message_groups['GLT'].to_sentence} has produced a GLT mouse for this Gene"            if !conflict_message_groups['GLT'].blank && conflict_message_groups['GLT'].length == 1
    conflict_message <<  "#{conflict_message_groups['MIs'].to_sentence} have active MI Attempts in Progress for this Gene" if !conflict_message_groups['MIs'].blank && conflict_message_groups['MIs'].length > 1
    conflict_message <<  "#{conflict_message_groups['MIs'].to_sentence} has active MI Attempts in Progress for this Gene"  if !conflict_message_groups['MIs'].blank && conflict_message_groups['MIs'].length == 1
    conflict_message <<  "#{conflict_message_groups['Assigned'].to_sentence} have Assigned this Gene to their Gene List"   if !conflict_message_groups['Assigned'].blank && conflict_message_groups['Assigned'].length > 1
    conflict_message <<  "#{conflict_message_groups['Assigned'].to_sentence} has Assigned this Gene to their Gene List"    if !conflict_message_groups['Assigned'].blank && conflict_message_groups['Assigned'].length == 1
    conflict_message <<  "#{conflict_message_groups['Registered'].to_sentence} have Registered Interest in this Gene"      if !conflict_message_groups['Registered'].blank && conflict_message_groups['Registered'].length > 1
    conflict_message <<  "#{conflict_message_groups['Registered'].to_sentence} has Registered Interest in this Gene"       if !conflict_message_groups['Registered'].blank && conflict_message_groups['Registered'].length == 1

    return conflict_message.join("\n")
  end
end

# == Schema Information
#
# Table name: plan_intentions
#
#  id                    :integer          not null, primary key
#  plan_id               :integer          not null
#  sub_project_id        :integer
#  status_id             :integer          not null
#  intention_id          :integer          not null
#  assign                :boolean          default(FALSE), not null
#  conflict              :boolean          default(FALSE), not null
#  withdrawn             :boolean          default(FALSE), not null
#  comment               :text
#  completion_comment    :text
#  ignore_available_mice :boolean          default(FALSE), not null
#  report_to_public      :boolean          default(TRUE), not null
#
