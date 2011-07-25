# encoding: utf-8

class Old::EmiEvent < Old::ModelBase
  set_table_name 'emi_event'

  belongs_to :clone
  belongs_to :distribution_centre, :class_name => 'Old::Centre', :foreign_key => :distribution_centre_id
  belongs_to :production_centre, :class_name => 'Old::Centre', :foreign_key => :centre_id
  has_many :mi_attempts, :foreign_key => :event_id
end

# == Schema Information
# Schema version: 20110725165610
#
# Table name: emi_event
#
#  id                     :integer(38)     not null, primary key
#  centre_id              :integer(38)     not null
#  clone_id               :integer(38)     not null
#  is_interested_only     :boolean(1)
#  proposed_mi_date       :datetime
#  creator_id             :decimal(, )
#  created_date           :datetime
#  edit_date              :datetime
#  edited_by              :string(128)
#  comments               :string(4000)
#  is_failed              :boolean(1)
#  distribution_centre_id :decimal(, )
#  is_public              :boolean(1)      default(TRUE), not null
#
# Indexes
#
#  emi_event_uk1  (centre_id,clone_id) UNIQUE
#

