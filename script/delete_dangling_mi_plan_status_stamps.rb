#!/usr/bin/env ruby

stamps = MiPlan::StatusStamp.find_by_sql(<<SQL)
select ss.* from mi_plan_status_stamps as ss
left outer join mi_plans on mi_plans.id = ss.mi_plan_id
where mi_plans.id IS NULL;
SQL

stamps.each {|s| raise "Still has MiPlan!" if s.mi_plan != nil}

MiPlan::StatusStamp.transaction do
  stamps.each(&:destroy)
end
