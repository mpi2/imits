class MiAttempt < ActiveRecord::Base
  belongs_to :clone
  validates :clone, :presence => true
end
