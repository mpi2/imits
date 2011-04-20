class MiAttemptStatus < ActiveRecord::Base
  validates :description, :presence => true
end
