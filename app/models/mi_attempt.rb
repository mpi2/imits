class MiAttempt < ActiveRecord::Base
  belongs_to :clone
  validates :clone, :presence => true

  belongs_to :centre
  belongs_to :distribution_centre, :class_name => 'Centre'
end
