class Colony < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  validates :name, :presence => true, :uniqueness => true

  belongs_to :mi_attempt

  def self.readable_name
    return 'colony'
  end
end

# == Schema Information
#
# Table name: colonies
#
#  id            :integer          not null, primary key
#  name          :string(20)       not null
#  mi_attempt_id :integer
#
# Indexes
#
#  colony_name_index  (name) UNIQUE
#
