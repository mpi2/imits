class ReagentName < ActiveRecord::Base
  acts_as_reportable

  has_many :reagents, :class_name => 'Reagent'

  validates :name, :uniqueness => true, :presence => true
end

# == Schema Information
#
# Table name: reagent_names
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  description :text
#
