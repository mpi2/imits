# encoding: utf-8

class MiAttempt::Status < ActiveRecord::Base
  acts_as_reportable

  validates :name, :presence => true, :uniqueness => true

  has_many :status_stamps
  has_many :mi_attempts, :through => :status_stamps

  def self.micro_injection_in_progress
    @@in_progress ||= self.find_by_name!('Micro-injection in progress').freeze
  end

  def self.genotype_confirmed
    @@good ||= self.find_by_name!('Genotype confirmed').freeze
  end

  def self.micro_injection_aborted
    @@aborted ||= self.find_by_name!('Micro-injection aborted').freeze
  end

  def self.chimeras_obtained
    @@chimeras_obtained ||= self.find_by_name!('Chimeras obtained').freeze
  end
end

# == Schema Information
#
# Table name: mi_attempt_statuses
#
#  id         :integer         not null, primary key
#  name       :string(50)      not null
#  created_at :datetime
#  updated_at :datetime
#  order_by   :integer
#  code       :string(10)      not null
#
# Indexes
#
#  index_mi_attempt_statuses_on_name  (name) UNIQUE
#

