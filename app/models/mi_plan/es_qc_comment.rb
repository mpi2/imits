# encoding: utf-8

class MiPlan::EsQcComment < ActiveRecord::Base
  acts_as_reportable

  has_many :mi_plans

  validates :name, :uniqueness => true
end

# == Schema Information
#
# Table name: mi_plan_es_qc_comments
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

