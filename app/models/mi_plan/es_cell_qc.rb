
class MiPlan::EsCellQc < ActiveRecord::Base

  default_scope(order('id asc'))

  belongs_to :mi_plan

  attr_accessible :number_passing_qc, :number_starting_qc

end

# == Schema Information
#
# Table name: mi_plan_es_cell_qcs
#
#  id                 :integer         not null, primary key
#  number_starting_qc :integer
#  number_passing_qc  :integer
#  mi_plan_id         :integer
#  created_at         :datetime        not null
#  updated_at         :datetime        not null
#

