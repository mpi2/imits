class EsCellQc::Status < ActiveRecord::Base
  acts_as_reportable

  include StatusInterface
  
  validates :name, :presence => true, :uniqueness => true
end

# == Schema Information
#
# Table name: es_cell_qc_statuses
#
#  id          :integer          not null, primary key
#  name        :string(50)       not null
#  description :string(255)
#  order_by    :integer
#
# Indexes
#
#  index_es_cell_qc_statuses_on_name  (name) UNIQUE
#
