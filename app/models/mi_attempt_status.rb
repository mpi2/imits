class MiAttemptStatus < ActiveRecord::Base
  validates :description, :presence => true, :uniqueness => true

  has_many :mi_attempts

  def self.micro_injection_in_progress
    @@in_progress ||= self.find_by_description!('Micro-injection in progress').freeze
  end

  def self.genotype_confirmed
    @@good ||= self.find_by_description!('Genotype confirmed').freeze
  end
end

# == Schema Information
#
# Table name: mi_attempt_statuses
#
#  id          :integer         not null, primary key
#  description :text            not null
#  created_at  :datetime
#  updated_at  :datetime
#

