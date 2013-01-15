class Consortium < ActiveRecord::Base
  acts_as_reportable

  validates :name, :presence => true, :uniqueness => true

  has_many :users
  has_many :mi_plans
  has_many :production_goals

  def self.[](name)
    return self.find_by_name!(name.to_s)
  end

  def self.komp2
    return [
      Consortium['BaSH'],
      Consortium['DTCC'],
      Consortium['JAX']
    ]
  end

  def self.impc
    return [
      Consortium['Helmholtz GMC'],
      Consortium['MGP'],
      Consortium['MRC'],
      Consortium['NorCOMM2'],
      Consortium['Phenomin'],
      Consortium['MARC']
    ]
  end

  def self.legacy
    return [
      Consortium['DTCC-Legacy'],
      Consortium['EUCOMM-EUMODIC'],
      Consortium['MGP Legacy'],
      Consortium['UCD-KOMP'],
    ]
  end

  def consortia_group_and_order
    if self.class.komp2.include?(self)
      return ['KOMP2', 1]
    elsif self.class.impc.include?(self)
      return ['IMPC', 2]
    elsif self.class.legacy.include?(self)
      return ['Legacy', 3]
    else
      return ['Other', 4]
    end
  end
end

# == Schema Information
#
# Table name: consortia
#
#  id           :integer         not null, primary key
#  name         :string(255)     not null
#  funding      :string(255)
#  participants :text
#  contact      :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#
# Indexes
#
#  index_consortia_on_name  (name) UNIQUE
#

