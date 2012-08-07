#!/usr/bin/env ruby

ApplicationModel.audited_transaction do
  res = ApplicationModel.connection.execute('select mi_plan_statuses.name, count(mi_plans.id) from mi_plans join mi_plan_statuses on mi_plan_statuses.id = mi_plans.status_id group by mi_plan_statuses.name')
  puts 'BEFORE:'
  res.each {|i| puts i['name'] + ' => ' + i['count'] }

  inactives = MiPlan.search(:status_name_eq => 'Inactive').result
  inactives.each { |i| i = i.class.find(i); i.is_active = false; i.save! }

  res = ApplicationModel.connection.execute('select mi_plan_statuses.name, count(mi_plans.id) from mi_plans join mi_plan_statuses on mi_plan_statuses.id = mi_plans.status_id group by mi_plan_statuses.name')
  puts 'AFTER:'
  res.each {|i| puts i['name'] + ' => ' + i['count'] }

  # raise 'ROLLBACK'
end
