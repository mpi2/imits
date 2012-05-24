# encoding: utf-8

#Task #8382

#DATA: Create new MGP Legacy consortium, move all plans which are subproject "MGP Legacy" => new consortium

#There are about 1000 plans with subproject ="MGP Legacy" out of 2000 MGP genes. Please
#1) Create a new consortium = MGP Legacy
#2) Move all Consortium = MGP + subproject = MGP Legacy plans into the MGP Legacy consortium

DEBUG = false

plans = MiPlan.find(:all, :conditions => {
  :sub_project_id => MiPlan::SubProject.find_by_name!('MGP Legacy'),
  :consortium_id => Consortium.find_by_name!('MGP')
})

raise "Expected 1059 rows - found #{plans.size} rows" if plans.size != 1059

count = plans.size
puts "Found #{count} rows"

consortium = Consortium.find_by_name!('MGP Legacy')

MiPlan.audited_transaction do

  puts "Updating plans:"

  plans.each do |plan|
    puts "#{plan.id}"
    plan.consortium = consortium
    plan.save! if ! DEBUG
  end

  plans = MiPlan.find(:all, :conditions => {
    :sub_project_id => MiPlan::SubProject.find_by_name!('MGP Legacy'),
    :consortium_id => Consortium.find_by_name!('MGP Legacy')
  })

  raise "Expected #{count} rows - found #{plans.size} rows" if plans.size != count

end

puts "done!"

#select count(*) from mi_plans p, consortia c, mi_plan_sub_projects s where p.consortium_id = c.id and c.name = 'MGP' and p.sub_project_id = s.id and s.name = 'MGP Legacy';

#select count(*) from mi_plans p, consortia c, mi_plan_sub_projects s where p.consortium_id = c.id and c.name = 'MGP Legacy' and p.sub_project_id = s.id and s.name = 'MGP Legacy';
