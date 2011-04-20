class Centre < ActiveRecord::Base
  validates :name, :presence => true
end
