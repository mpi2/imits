class DepositedMaterial < ActiveRecord::Base
  default_scope :order => :name

  validates :name, :uniqueness => true
end

# == Schema Information
# Schema version: 20110527121721
#
# Table name: deposited_materials
#
#  id         :integer         not null, primary key
#  name       :text            not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_deposited_materials_on_name  (name) UNIQUE
#

