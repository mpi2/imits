# encoding: utf-8

class MouseAlleleMod < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include MouseAlleleMod::StatusManagement
  include ApplicationModel::HasStatuses
  include ApplicationModel::BelongsToMiPlan

  belongs_to :parent_colony, :class_name => 'Colony'
  belongs_to :allele
  belongs_to :real_allele
  belongs_to :mi_plan
  belongs_to :status
  belongs_to :deleter_strain

  has_one    :colony, dependent: :destroy

  has_many   :status_stamps, :order => "#{MouseAlleleMod::StatusStamp.table_name}.created_at ASC", dependent: :destroy

  access_association_by_attribute :deleter_strain, :name
  access_association_by_attribute :status, :name


  ColonyQc::QC_FIELDS.each do |qc_field|

    define_method("#{qc_field}_result=") do |arg|
      instance_variable_set("@#{qc_field}_result",arg)
    end

    define_method("#{qc_field}_result") do
      if !instance_variable_get("@#{qc_field}_result").blank?
        return instance_variable_get("@#{qc_field}_result")
      elsif !colony.blank? and !colony.try(:colony_qc).try(qc_field.to_sym).blank?
        return colony.colony_qc.send(qc_field)
      else
        return 'na'
      end
    end
  end

  accepts_nested_attributes_for :status_stamps
  accepts_nested_attributes_for :colony, :update_only =>true

  protected :status=

  before_validation :remove_spaces_from_colony_name
  before_validation :set_blank_qc_fields_to_na
  before_validation :allow_override_of_plan
  before_validation :change_status
  before_validation :manage_colony_and_qc_data

  before_save :deal_with_unassigned_or_inactive_plans # this method are in belongs_to_mi_plan
  before_save :generate_colony_name_if_blank
  before_save :set_phenotype_attempt_id
  before_save :assign_credit

  after_save :manage_status_stamps


## BEFORE VALIDATION METHODS

  def remove_spaces_from_colony_name
    if ! self.colony_name.nil?
      self.colony_name = self.colony_name.to_s.strip || self.colony_name
      self.colony_name = self.colony_name.to_s.gsub(/\s+/, ' ')
    end
  end

  def generate_colony_name_if_blank
    return unless self.colony_name.blank?
    i = 0
    begin
      i += 1
      j = i > 0 ? "-#{i}" : ""
      new_colony_name = "#{self.parent_colony.name}#{j}"
    end until self.class.find_by_colony_name(new_colony_name).blank?
    self.colony_name = new_colony_name
  end

#  validates :colony, :presence => true
  validates :parent_colony, :presence => true
  validates :status, :presence => true

  #mi_plan validatation
  validate do |pp|
    if pp.mi_plan.nil?
      pp.errors.add(:consortium_name, 'must be set')
      pp.errors.add(:centre_name, 'must be set')
      return
    end

    if mi_plan != parent_colony.mi_plan &&  mi_plan.phenotype_only == false
      pp.errors[:mi_plan] << 'must be either the same as the mouse production plan OR phenotype_only'
    end
  end

  #genotype confirmed colony
  validate do |pp|
    if parent_colony && parent_colony.genotype_confirmed == false
      pp.errors.add(:production_colony_name, "Must be 'Genotype confirmed'")
    end
  end

## BEFORE SAVE METHODS

  def set_phenotype_attempt_id
    return unless phenotype_attempt_id.blank?
    paid = PhenotypeAttemptId.new
    paid.save
    self.phenotype_attempt_id = paid.id
  end


## METHODS
  def gene
    if mi_plan.try(:gene)
      return mi_plan.gene
    elsif parent_colony.try(:gene)
      return parent_colony.gene
    else
      return nil
    end
  end

  def colony_name
    if !@colony_name.blank?
      @colony_name
    elsif !colony.blank?
      colony.name
    else
      nil
    end
  end

  def colony_name=(arg)
    @colony_name = arg
  end

  def parent_colony_name
    return parent_colony.name unless parent_colony.blank?
    return nil
  end

  def parent_colony_name=(arg)
    return nil if arg.blank?

    if !arg.respond_to?(:to_str)
      errors.add(:parent_colony_name, "value is invalid")
      return
    end

    parent_colony_model = Colony.where("name = '#{arg}' AND mi_attempt_id IS NOT NULL")

    if parent_colony_model.count == 0
      errors.add(:parent_colony_name, "#{arg} does not exist")
      return
    end

    raise "Multiple Colonies found with the name equal to #{arg}" if parent_colony_model.length > 1

    self.parent_colony = Colony.find(parent_colony_model.first.id)
    return arg
  end


  def deleter_strain_excision_type
    return nil if deleter_strain_id.blank?
    return deleter_strain.excision_type
  end

  def colony_background_strain_name=(arg)
    @colony_background_strain_name = arg
  end

  def colony_background_strain_name
    return @colony_background_strain_name unless @colony_background_strain_name.blank?
    colony.try(:background_strain_name)
  end

  def colony_background_strain_mgi_name
    colony.try(:background_strain).try(:mgi_strain_name)
  end

  def colony_background_strain_mgi_accession
    colony.try(:background_strain).try(:mgi_strain_accession_id)
  end

## BEFORE VALIDATION FUNCTIONS
  def set_blank_qc_fields_to_na
    ColonyQc::QC_FIELDS.each do |qc_field|
      if self.send("#{qc_field}_result").blank?
        self.send("#{qc_field}_result=", 'na')
      end
    end
  end
  protected :set_blank_qc_fields_to_na

  def allow_override_of_plan
    return if self.consortium_name.blank? or self.production_centre_name.blank? or self.gene.blank?
    set_plan = MiPlan.find_or_create_plan(self, {:gene => self.gene, :consortium_name => self.consortium_name, :production_centre_name => self.production_centre_name, :phenotype_only => true}) do |pa|
      plan = pa.parent_colony.mi_plan
      if !plan.blank? and plan.consortium.try(:name) == self.consortium_name and plan.production_centre.try(:name) == self.production_centre_name
        plan = [plan]
      else
        plan = MiPlan.includes(:consortium, :production_centre, :gene).where("genes.marker_symbol = '#{self.gene.marker_symbol}' AND consortia.name = '#{self.consortium_name}' AND centres.name = '#{self.production_centre_name}' AND phenotype_only = true")
      end
    end

    self.mi_plan = set_plan
  end
  protected :allow_override_of_plan

  def manage_colony_and_qc_data

    colony_attr_hash = colony.try(:attributes) || {}
    if colony.blank? or (colony.try(:name) != colony_name)
      colony_attr_hash[:name] = colony_name
    end

    colony_attr_hash[:background_strain_name] = colony_background_strain_name
    colony_attr_hash[:allele_type] = mouse_allele_type

    colony_attr_hash[:distribution_centres_attributes] = self.distribution_centres_attributes unless self.distribution_centres_attributes.blank?

    if self.status.try(:code) == 'cec'
      colony_attr_hash[:genotype_confirmed] = true
    elsif self.status.try(:code) != 'cec'
      colony_attr_hash[:genotype_confirmed] = false
    end

    colony_attr_hash[:colony_qc_attributes] = {} if !colony_attr_hash.has_key?(:colony_qc_attributes)

    ColonyQc::QC_FIELDS.each do |qc_field|
      if colony.try(:colony_qc).blank? or self.send("#{qc_field}_result") != colony.colony_qc.send(qc_field)
        colony_attr_hash[:colony_qc_attributes]["#{qc_field}".to_sym] = self.send("#{qc_field}_result")
      end
    end

    self.colony_attributes = colony_attr_hash

  end
  protected :manage_colony_and_qc_data

  def mouse_allele_type
    return @mouse_allele_type unless @mouse_allele_type.nil?
    return colony.allele_type unless colony.blank?
    return nil
  end

  def mouse_allele_type=(arg)
    @mouse_allele_type = arg
  end

  def mouse_allele_symbol_superscript
    return nil unless colony
    return colony.allele_symbol_superscript
  end

  def mouse_allele_symbol
    return nil unless colony
    return colony.allele_symbol
  end


  def mi_attempt
    col = parent_colony

    while col.mi_attempt_id.blank? && !col.mouse_allele_mod_id.blank?
      col = col.mouse_allele_mod.parent_colony
    end

    return col.mi_attempt
  end

  def distribution_centres_formatted_display
    return [] if self.colony.blank? || self.colony.distribution_centres.blank?
    output_string = ''
    self.colony.distribution_centres.each do |distribution_centre|
      output_array = []
      if distribution_centre.is_distributed_by_emma
        output_array << 'EMMA'
      end
      output_array << distribution_centre.centre.name
      if !distribution_centre.deposited_material.name.nil?
        output_array << distribution_centre.deposited_material.name
      end
      output_string << "[#{output_array.join(', ')}] "
    end
    return output_string.strip()
  end

  def distribution_centres
    return colony.try(:distribution_centres)
    return []
  end

  def distribution_centres_attributes
    return @distribution_centres_attributes unless @distribution_centres_attributes.blank?
    return distribution_centres.map(&:as_json) unless distribution_centres.blank?
    return nil
  end

  def distribution_centres_attributes=(arg)
    @distribution_centres_attributes = arg
  end

  def reload
    @distribution_centres_attributes = []
    super
  end

## CLASS METHODS
  def self.readable_name
    'mouse allele modification'
  end
end

# == Schema Information
#
# Table name: mouse_allele_mods
#
#  id                               :integer          not null, primary key
#  mi_plan_id                       :integer          not null
#  status_id                        :integer          not null
#  rederivation_started             :boolean          default(FALSE), not null
#  rederivation_complete            :boolean          default(FALSE), not null
#  number_of_cre_matings_started    :integer          default(0), not null
#  number_of_cre_matings_successful :integer          default(0), not null
#  cre_excision                     :boolean          default(TRUE), not null
#  tat_cre                          :boolean          default(FALSE)
#  deleter_strain_id                :integer
#  is_active                        :boolean          default(TRUE), not null
#  report_to_public                 :boolean          default(TRUE), not null
#  phenotype_attempt_id             :integer
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  allele_id                        :integer
#  real_allele_id                   :integer
#  parent_colony_id                 :integer
#
