# encoding: utf-8

class MiAttemptStatus < ActiveRecord::Base
  acts_as_reportable

  validates :description, :presence => true, :uniqueness => true

  has_many :mi_attempts

  def self.micro_injection_in_progress
    @@in_progress ||= self.find_by_description!('Micro-injection in progress').freeze
  end

  def self.genotype_confirmed
    @@good ||= self.find_by_description!('Genotype confirmed').freeze
  end

  def self.micro_injection_aborted
    @@aborted ||= self.find_by_description!('Micro-injection aborted').freeze
  end
end

# == Schema Information
# Schema version: 20110922103626
#
# Table name: mi_attempt_statuses
#
#  id          :integer         not null, primary key
#  description :string(50)      not null
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_mi_attempt_statuses_on_description  (description) UNIQUE
#

