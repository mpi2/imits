class Old::MiAttemptStatus < Old::ModelBase
  set_table_name 'emi_status_dict'
end


# == Schema Information
# Schema version: 20110421150000
#
# Table name: emi_status_dict
#
#  id          :decimal(, )     not null, primary key
#  name        :string(512)
#  description :string(4000)
#  order_by    :decimal(, )
#  active      :boolean(1)
#

