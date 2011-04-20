class MiAttemptStatus < ActiveRecord::Base
  IN_PROGRESS = self.find_by_description!('In progress').freeze
  GOOD        = self.find_by_description!('Good').freeze

  validates :description, :presence => true, :uniqueness => true
end
