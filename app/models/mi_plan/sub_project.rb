# encoding: utf-8

class MiPlan::SubProject < ActiveRecord::Base
  acts_as_reportable

  has_many :mi_plans

  validates :name, :uniqueness => {:case_sensitive => false}

  def has_mi_plan?
    if MiPlan.find_all_by_sub_project_id(self.id).count > 0
      return true
    else
      return false
    end
  end

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

