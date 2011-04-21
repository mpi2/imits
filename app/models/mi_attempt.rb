class MiAttempt < ActiveRecord::Base
  belongs_to :clone
  validates :clone, :presence => true

  belongs_to :mi_attempt_status
  validates :mi_attempt_status, :presence => true

  belongs_to :centre
  belongs_to :distribution_centre, :class_name => 'Centre'

  belongs_to :blast_strain, :class_name => 'Strain'
  belongs_to :colony_background_strain, :class_name => 'Strain'
  belongs_to :test_cross_strain, :class_name => 'Strain'

  after_initialize :defaults

  def emma_status
    if is_suitable_for_emma?
      if is_emma_sticky? then return :suitable_sticky else return :suitable end
    else
      if is_emma_sticky? then return :unsuitable_sticky else return :unsuitable end
    end
  end

  class EmmaStatusError < RuntimeError; end

  def emma_status=(status)
    case status.to_sym
    when :suitable then
      self.is_suitable_for_emma = true
      self.is_emma_sticky = false

    when :unsuitable then
      self.is_suitable_for_emma = false
      self.is_emma_sticky = false

    when :suitable_sticky then
      self.is_suitable_for_emma = true
      self.is_emma_sticky = true

    when :unsuitable_sticky then
      self.is_suitable_for_emma = false
      self.is_emma_sticky = true

    else
      raise EmmaStatusError, "Invalid status '#{status.inspect}'"
    end
  end

  protected

  def defaults
    self.mi_attempt_status = MiAttemptStatus.in_progress
  end

end
