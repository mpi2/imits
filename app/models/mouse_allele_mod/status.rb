# encoding: utf-8

class MouseAlleleMod::Status < ActiveRecord::Base
  include StatusInterface

    def self.status_order
    status_sort_order = {}
    MouseAlleleMod::Status.all.each do |status|
      status_sort_order[status] = status[:order_by]
    end
    return status_sort_order
  end

end

# == Schema Information
#
# Table name: mouse_allele_mod_statuses
#
#  id       :integer          not null, primary key
#  name     :string(50)       not null
#  order_by :integer          not null
#  code     :string(4)        not null
#
