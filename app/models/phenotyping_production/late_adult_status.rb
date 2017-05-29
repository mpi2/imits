# encoding: utf-8

class PhenotypingProduction::LateAdultStatus < ActiveRecord::Base
  include StatusInterface

  def self.status_order
    status_sort_order = {}
    PhenotypingProduction::LateAdultStatus.all.each do |status|
      status_sort_order[status] = status[:order_by]
    end
    return status_sort_order
  end

end

# == Schema Information
#
# Table name: phenotyping_production_late_adult_statuses
#
#  id         :integer          not null, primary key
#  name       :string(50)       not null
#  order_by   :string(255)
#  integer    :string(255)
#  code       :string(10)
#  string     :string(10)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
