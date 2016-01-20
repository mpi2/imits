# encoding: utf-8

class Intention < ApplicationModel
  acts_as_audited
  acts_as_reportable

  has_many :plan_intentions

end

# == Schema Information
#
# Table name: intentions
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  description :string(255)
#
