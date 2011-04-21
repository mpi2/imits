class MiAttemptStatus < ActiveRecord::Base
  validates :description, :presence => true, :uniqueness => true

  def self.in_progress
    @@in_progress ||= self.find_by_description!('In progress').freeze
  end

  def self.good
    @@good ||= self.find_by_description!('Good').freeze
  end
end
