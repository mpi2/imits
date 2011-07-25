class Old::MiAttemptStatus < Old::ModelBase
  set_table_name 'emi_status_dict'
end

# == Schema Information
# Schema version: 20110725165610
#
# Table name: emi_status_dict
#
#  id          :decimal(, )     not null, primary key
#  name        :string(512)
#  description :string(4000)
#  order_by    :decimal(, )
#  active      :boolean(1)
#
# Indexes
#
#  emi_status_dict_uk1  (name) UNIQUE
#

