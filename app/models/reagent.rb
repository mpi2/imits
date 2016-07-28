class Reagent < ActiveRecord::Base
  acts_as_reportable

  attr_accessible :mi_attempt_id, :reagent_name, :concentration

  extend AccessAssociationByAttribute
  
  belongs_to :mi_attempt
  belongs_to :reagent, :class_name => 'ReagentName'

  access_association_by_attribute :reagent, :name

  validates :reagent, :presence => true
end

# == Schema Information
#
# Table name: reagents
#
#  id            :integer          not null, primary key
#  mi_attempt_id :integer          not null
#  reagent_id    :integer          not null
#  concentration :float
#
