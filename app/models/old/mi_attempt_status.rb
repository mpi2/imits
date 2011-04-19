class Old::MiAttemptStatus < Old::ModelBase
  set_table_name 'emi_status_dict'
end

# == Schema Information
# Schema version: 20110311153640
#
# Table name: emi_status_dict
#
#  id          :integer         not null, primary key
#  name        :string(512)
#  description :string(4000)
#  order_by    :decimal(, )
#  active      :boolean
#

