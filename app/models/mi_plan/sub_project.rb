# encoding: utf-8

class MiPlan::SubProject < ActiveRecord::Base
  
  has_many :mi_plans

  validates :name, :uniqueness => true

  #def self.[](name)
  #  return self.find_by_name!(name.to_s)
  #end
  
end

# == Schema Information
#
# Table name: mi_plan_sub_projects
#
#  id         :integer         not null, primary key
#  name       :string(255)     not null
#  created_at :datetime
#  updated_at :datetime
#

