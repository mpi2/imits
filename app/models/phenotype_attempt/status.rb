# encoding: utf-8

class PhenotypeAttempt::Status < ActiveRecord::Base
  include StatusInterface

    def self.status_order
    status_sort_order = {}
    PhenotypeAttempt::Status.all.each do |status|
      status_sort_order[status] = status[:order_by]
    end
    return status_sort_order
  end

end

# == Schema Information
#
# Table name: phenotype_attempt_statuses
#
#  id         :integer          not null, primary key
#  name       :string(50)       not null
#  created_at :datetime
#  updated_at :datetime
#  order_by   :integer
#  code       :string(10)       not null
#
