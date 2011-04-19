class Old::Centre < Old::ModelBase
  set_table_name 'per_centre'
end

# == Schema Information
# Schema version: 20110311153640
#
# Table name: per_centre
#
#  id           :integer         not null, primary key
#  name         :string(128)
#  creator_id   :integer
#  edit_date    :datetime
#  edited_by    :string(128)
#  check_number :integer
#  created_date :datetime
#

