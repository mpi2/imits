# encoding: utf-8

class PhenotypeAttempt < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include PhenotypeAttempt::StatusManagement
  include ApplicationModel::HasStatuses

  belongs_to :mi_attempt
  belongs_to :mi_plan
  belongs_to :status
  belongs_to :deleter_strain
  belongs_to :colony_background_strain, :class_name => 'Strain'
  has_many :status_stamps, :order => "#{PhenotypeAttempt::StatusStamp.table_name}.created_at ASC"

  has_many :distribution_centres, :class_name => 'PhenotypeAttempt::DistributionCentre'

  access_association_by_attribute :colony_background_strain, :name

  protected :status=

  validates :mouse_allele_type, :inclusion => { :in => MOUSE_ALLELE_OPTIONS.keys }
  validates :colony_name, :uniqueness => {:case_sensitive => false}

  validate :mi_attempt do |me|
    if me.mi_attempt and me.mi_attempt.status != MiAttempt::Status.genotype_confirmed
      me.errors.add(:mi_attempt, "Status must be 'Genotype confirmed' (is currently '#{me.mi_attempt.status.name}')")
    end
  end

  validate :mi_plan do |me|
    if me.mi_attempt and me.mi_plan and me.mi_attempt.gene != me.mi_plan.gene
      me.errors.add(:mi_plan, 'must have same gene as mi_attempt')
    end
  end

  # BEGIN Callbacks
  before_validation :change_status
  before_validation :set_mi_plan

  before_save :generate_colony_name_if_blank
  before_save :ensure_plan_is_valid

  after_save :manage_status_stamps
  after_save :create_initial_distribution_centre

  def set_mi_plan
    self.mi_plan ||= mi_attempt.try(:mi_plan)
  end

  def generate_colony_name_if_blank
    return unless self.colony_name.blank?

    i = 0
    begin
      i += 1
      self.colony_name = "#{self.mi_attempt.colony_name}-#{i}"
    end until self.class.find_by_colony_name(self.colony_name).blank?
  end

  def ensure_plan_is_valid
    if ! mi_plan.assigned?
      mi_plan.force_assignment = true
      mi_plan.save!
    end
    if self.is_active?
      self.mi_plan.is_active = true
      self.mi_plan.save!
    end
  end

  def create_initial_distribution_centre
    if distribution_centres.empty? and has_status? :cec
      dc = self.distribution_centres.new
      dc.centre = self.production_centre
      dc.deposited_material = DepositedMaterial.find_by_name!('Frozen embryos')
      dc.save!
      distribution_centres.reload
    end
  end

  # END Callbacks

  def distribution_centres_formatted_display
    output_string = ''
    self.distribution_centres.each do |distribution_centre|
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

  def mouse_allele_symbol_superscript
    if mouse_allele_type.nil? or self.mi_attempt.es_cell.allele_symbol_superscript_template.nil?
      return nil
    else
      return self.es_cell.allele_symbol_superscript_template.sub(
        TargRep::EsCell::TEMPLATE_CHARACTER, mouse_allele_type)
    end
  end

  def mouse_allele_symbol
    if mouse_allele_symbol_superscript
      return "#{self.gene.marker_symbol}<sup>#{mouse_allele_symbol_superscript}</sup>"
    else
      return nil
    end
  end

  def allele_symbol
    if has_status?(:cec)
      return mouse_allele_symbol
    else
      return self.mi_attempt.allele_symbol
    end
  end

  delegate :gene, :consortium, :production_centre, :to => :mi_plan, :allow_nil => true
  delegate :marker_symbol, :to => :gene, :allow_nil => true
  delegate :es_cell, :allele_id, :to => :mi_attempt, :allow_nil => true

  def reportable_statuses_with_latest_dates
    retval = {}
    status_stamps.each do |status_stamp|
      status_stamp_date = status_stamp.created_at.utc.to_date
      if !retval[status_stamp.status.name] or
                status_stamp_date > retval[status_stamp.status.name]
        retval[status_stamp.status.name] = status_stamp_date
      end
    end
    return retval
  end

  def earliest_relevant_status_stamp
    self.status_stamps.find_by_status_id(self.status_id)
  end

  def self.readable_name
    'phenotype attempt'
  end

end

# == Schema Information
#
# Table name: phenotype_attempts
#
#  id                               :integer         not null, primary key
#  mi_attempt_id                    :integer         not null
#  status_id                        :integer         not null
#  is_active                        :boolean         default(TRUE), not null
#  rederivation_started             :boolean         default(FALSE), not null
#  rederivation_complete            :boolean         default(FALSE), not null
#  number_of_cre_matings_started    :integer         default(0), not null
#  number_of_cre_matings_successful :integer         default(0), not null
#  phenotyping_started              :boolean         default(FALSE), not null
#  phenotyping_complete             :boolean         default(FALSE), not null
#  created_at                       :datetime
#  updated_at                       :datetime
#  mi_plan_id                       :integer         not null
#  colony_name                      :string(125)     not null
#  mouse_allele_type                :string(2)
#  deleter_strain_id                :integer
#  colony_background_strain_id      :integer
#
# Indexes
#
#  index_phenotype_attempts_on_colony_name  (colony_name) UNIQUE
#

