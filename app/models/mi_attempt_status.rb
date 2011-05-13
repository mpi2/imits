class MiAttemptStatus < ActiveRecord::Base
  validates :description, :presence => true, :uniqueness => true

  has_many :mi_attempts

  def self.in_progress
    @@in_progress ||= self.find_by_description!('In progress').freeze
  end

  def self.good
    @@good ||= self.find_by_description!('Good').freeze
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

