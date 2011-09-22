# encoding: utf-8

class MiPlanStatus < ActiveRecord::Base
  acts_as_reportable

  validates :name, :presence => true, :uniqueness => true

  def self.[](name)
    return self.find_by_name!(name.to_s)
  end
end

# == Schema Information
# Schema version: 20110922000000
#
# Table name: mi_plan_statuses
#
#  id          :integer         not null, primary key
#  name        :string(50)      not null
#  description :string(255)
#  order_by    :integer
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_mi_plan_statuses_on_name  (name) UNIQUE
#

