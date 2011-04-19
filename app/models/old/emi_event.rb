# encoding: utf-8

class Old::EmiEvent < Old::ModelBase
  set_table_name 'emi_event'

  belongs_to :clone
  belongs_to :distribution_centre, :class_name => 'Old::Centre', :foreign_key => :distribution_centre_id
end

# == Schema Information
# Schema version: 20110311153640
#
# Table name: emi_event
#
#  id                     :integer         not null, primary key
#  centre_id              :integer         not null
#  clone_id               :integer         not null
#  is_interested_only     :boolean
#  proposed_mi_date       :datetime
#  creator_id             :integer
#  created_date           :datetime
#  edit_date              :datetime
#  edited_by              :string(128)
#  comments               :string(4000)
#  is_failed              :boolean
#  distribution_centre_id :integer
#

