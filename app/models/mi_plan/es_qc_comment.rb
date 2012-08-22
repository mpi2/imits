# encoding: utf-8

class MiPlan::EsQcComment < ActiveRecord::Base
  acts_as_reportable

  has_many :mi_plans

  validates :name, :uniqueness => true, :presence => true

  def self.all_names
    [''] + self.all.map(&:name)
  end
end

# == Schema Information
#
# Table name: mi_plan_es_qc_comments
#
#  id         :integer         not null, primary key
#  name       :string(255)     not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_mi_plan_es_qc_comments_on_name  (name) UNIQUE
#

