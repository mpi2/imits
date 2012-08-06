# encoding: utf-8

class PhenotypeAttempt < ApplicationModel
  acts_as_audited
  acts_as_reportable

  include PhenotypeAttempt::StatusManagement

  belongs_to :mi_attempt
  belongs_to :mi_plan
  belongs_to :status
  belongs_to :deleter_strain
  has_many :status_stamps, :order => "#{PhenotypeAttempt::StatusStamp.table_name}.created_at ASC"

  has_many :distribution_centres, :class_name => 'PhenotypeAttempt::DistributionCentre'
  has_many :centres, :through => :distribution_centres
  has_many :deposited_materials, :through => :distribution_centres

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
  before_save :record_if_status_was_changed
  before_save :generate_colony_name_if_blank
  before_save :ensure_plan_is_valid
  before_save :create_initial_distribution_centre
  after_save :create_status_stamp_if_status_was_changed

  def create_initial_distribution_centre
    if self.distribution_centres.empty? && self.status.name == "Cre Excision Complete"
      initial_deposited_material = DepositedMaterial.find_by_name!('Frozen embryos')
      initial_centre = Centre.find_by_name(self.production_centre.name)
      initial_distribution_centre = PhenotypeAttempt::DistributionCentre.new
      initial_distribution_centre.centre = initial_centre
      initial_distribution_centre.deposited_material = initial_deposited_material
      self.distribution_centres.push(initial_distribution_centre)
    end
  end
  def set_mi_plan
    self.mi_plan ||= mi_attempt.try(:mi_plan)
  end

  def record_if_status_was_changed
    if self.changed.include? 'status_id'
      @new_status = self.status
    else
      @new_status = nil
    end
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

  def create_status_stamp_if_status_was_changed
    if @new_status
      status_stamps.create!(:status => @new_status)
    end
  end

  # END Callbacks

  def pretty_print_distribution_centres
    @formatted_tags_array = Array.new
    self.distribution_centres.each do |this_distribution_centre|
      output_array = Array.new
      centre = this_distribution_centre.centre.name || ''
      deposited_material = this_distribution_centre.deposited_material.name || ''
      if this_distribution_centre.is_distributed_by_emma
        emma_status = 'EMMA'
        output_array.push(emma_status, centre)
      else
        output_array.push(centre)
      end
      output_string = "["
      output_string << output_array.join('::')
      output_string << "]"
      @formatted_tags_array.push(output_string)
    end
    @pretty_print_distribution_centres = @formatted_tags_array.join(', ')
    return @pretty_print_distribution_centres
  end

  def mouse_allele_symbol_superscript
    if mouse_allele_type.nil? or self.mi_attempt.es_cell.allele_symbol_superscript_template.nil?
      return nil
    else
      return self.mi_attempt.es_cell.allele_symbol_superscript_template.sub(
        EsCell::TEMPLATE_CHARACTER, mouse_allele_type)
    end
  end

  def mouse_allele_symbol
    if mouse_allele_symbol_superscript
      return "#{self.mi_attempt.es_cell.marker_symbol}<sup>#{mouse_allele_symbol_superscript}</sup>"
    else
      return nil
    end
  end

  def allele_symbol
    if mouse_allele_type
      return mouse_allele_symbol
    elsif self.mi_attempt
      return self.mi_attempt.allele_symbol
    end
  end

  delegate :gene, :to => :mi_attempt
  delegate :marker_symbol, :to => :mi_plan
  delegate :consortium, :production_centre, :to => :mi_plan

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
#
# Indexes
#
#  index_phenotype_attempts_on_colony_name  (colony_name) UNIQUE
#

