class Old::Pipeline < Old::ModelBase
  set_table_name 'pln_pipeline'
end

# == Schema Information
# Schema version: 20110721091844
#
# Table name: pln_pipeline
#
#  id           :integer(38)     not null, primary key
#  name         :string(4000)
#  description  :string(4000)
#  creator_id   :integer(38)
#  created_date :datetime
#  edited_by    :string(4000)
#  edit_date    :datetime
#  check_number :integer(38)
#

