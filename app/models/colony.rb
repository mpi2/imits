class Colony < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  belongs_to :mi_attempt

  validates :name, :presence => true, :uniqueness => true

  validate do |colony|
    if !mi_attempt.blank? and !mi_attempt.es_cell.blank?
      if Colony.where("mi_attempt_id = #{colony.mi_attempt_id} #{if !colony.id.blank?; "and id = #{colony.id}"; end}").count == 1
        colony.errors.add :base, 'Multiple Colonies are not allowed for Mi Attempts micro-injected with an ES Cell clone'
      end
    end
  end

  before_save :set_genotype_confirmed

  def set_genotype_confirmed
    if !mi_attempt_id.blank? && !mi_attempt.status.blank?
      if !mi_attempt.es_cell.blank? && mi_attempt.status.code == 'gtc'
        self.genotype_confirmed = true
      end
    end
  end
  protected :set_genotype_confirmed

  def self.readable_name
    return 'colony'
  end
end

# == Schema Information
#
# Table name: colonies
#
#  id                 :integer          not null, primary key
#  name               :string(255)      not null
#  mi_attempt_id      :integer
#  genotype_confirmed :boolean          default(FALSE)
#
# Indexes
#
#  colony_name_index  (name) UNIQUE
#
