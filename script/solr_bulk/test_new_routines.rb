#!/usr/bin/env ruby

require 'pp'
require 'color'

@run_hash = {
  'relevant_plan' => true,
  'relevant_status' => true,
  'latest_relevant_mi_attempt' => true,
  'latest_relevant_phenotype_attempt' => true,
  'relevant_status_stamp' => true
}

@hash = {
  'relevant_plan' => [],
  'relevant_status' => [],
  'latest_relevant_mi_attempt' => [],
  'latest_relevant_phenotype_attempt' => [],
  'relevant_status_stamp' => []
}

def check_gene_relevant_plan(gene)
  old = gene.relevant_plan

  return true if ! old

  new = gene.relevant_plan_new

  if old.id.to_i != new.id.to_i
    puts "#### check_gene_relevant_plan: #{gene.id} not equal (old/new) (#{old.id}/#{new.id})".red
  end

  return old.id.to_i == new.id.to_i
end

def check_gene_relevant_status(gene)

  strftime = "%Y-%m-%d %H:%M"

  old = gene.relevant_status

  return true if ! old

  new = gene.relevant_status_new

  keys = %W{order_by date status stamp_type stamp_id mi_plan_id mi_attempt_id phenotype_attempt_id}
  ints = %W{order_by stamp_id mi_plan_id mi_attempt_id phenotype_attempt_id}
  dates = %W{date}
  strings = %W{status stamp_type}

  keys.each do |key|
    return false if ints.include?(key) && old[key].to_i != new[key].to_i
    return false if dates.include?(key) && old[key].to_s.length > 0 && Time.parse(old[key].to_s).strftime(strftime) != Time.parse(new[key].to_s).strftime(strftime)
    return false if strings.include?(key) && old[key].to_s != new[key].to_s
  end

  return true
end

def check_plan_latest_relevant_mi_attempt(plan)
  old = plan.latest_relevant_mi_attempt
  return true if ! old

  new = plan.latest_relevant_mi_attempt_new

  return old.id == new.id
end

def check_plan_latest_relevant_phenotype_attempt(plan)
  old = plan.latest_relevant_phenotype_attempt
  return true if ! old

  new = plan.latest_relevant_phenotype_attempt_new

  return old.id == new.id
end

def check_plan_relevant_status_stamp(plan)
  old = plan.relevant_status_stamp
  return true if ! old

  new = plan.relevant_status_stamp_new

  return old[:stamp_id].to_i == new[:stamp_id].to_i
end

counter = 0

if @run_hash['relevant_plan'] || @run_hash['relevant_status']

  Gene.all.each do |gene|
    counter += 1
    ok = true

    if @run_hash['relevant_plan']
      ok = check_gene_relevant_plan(gene)
      @hash['relevant_plan'].push gene.id if ! ok
    end

    if @run_hash['relevant_status']
      ok = check_gene_relevant_status(gene)
      @hash['relevant_status'].push gene.id if ! ok
    end
  end

  puts "#### check_gene_relevant_plan:".blue if @run_hash['relevant_plan']
  pp @hash['relevant_plan'] if @run_hash['relevant_plan']

  puts "#### check_gene_relevant_status:".blue if @run_hash['relevant_status']
  pp @hash['relevant_status'] if @run_hash['relevant_status']

end



if @run_hash['latest_relevant_mi_attempt'] || @run_hash['latest_relevant_phenotype_attempt'] || @run_hash['relevant_status_stamp']

  counter = 0

  MiPlan.all.each do |plan|
    counter += 1
    ok = true

    if @run_hash['latest_relevant_mi_attempt']
      ok = check_plan_latest_relevant_mi_attempt(plan)
      @hash['latest_relevant_mi_attempt'].push plan.id if ! ok
    end

    if @run_hash['latest_relevant_phenotype_attempt']
      ok = check_plan_latest_relevant_phenotype_attempt(plan)
      @hash['latest_relevant_phenotype_attempt'].push plan.id if ! ok
    end

    if @run_hash['relevant_status_stamp']
      ok = check_plan_relevant_status_stamp(plan)
      @hash['relevant_status_stamp'].push plan.id if ! ok
    end
  end

  puts "#### check_plan_latest_relevant_mi_attempt:".blue if @run_hash['latest_relevant_mi_attempt']
  pp @hash['latest_relevant_mi_attempt'] if @run_hash['latest_relevant_mi_attempt']

  puts "#### check_plan_latest_relevant_phenotype_attempt:".blue if @run_hash['latest_relevant_phenotype_attempt']
  pp @hash['latest_relevant_phenotype_attempt'] if @run_hash['latest_relevant_phenotype_attempt']

  puts "#### check_plan_relevant_status_stamp:".blue if @run_hash['relevant_status_stamp']
  pp @hash['relevant_status_stamp'] if @run_hash['relevant_status_stamp']

end


##### check_gene_relevant_plan:
#[]
##### check_gene_relevant_status:
#[]
##### check_plan_latest_relevant_mi_attempt:
#[1784,
# 7382,
# 3460,
# 7401,
# 7455,
# 8095,
# 12211,
# 7476,
# 7495,
# 7511,
# 7671,
# 4789,
# 12398,
# 4376,
# 3106,
# 536,
# 6206,
# 11076,
# 11433,
# 312,
# 11556,
# 14087,
# 14131,
# 14142,
# 14116,
# 14120,
# 12281,
# 14305,
# 14334,
# 14489,
# 8403,
# 14346,
# 5022,
# 14813,
# 14229,
# 14236,
# 14983,
# 15210,
# 525]
##### check_plan_latest_relevant_phenotype_attempt:
#[8773, 4376, 2540, 16525]
##### check_plan_relevant_status_stamp:
#[8773,
# 1784,
# 7382,
# 3460,
# 7401,
# 7455,
# 8095,
# 12211,
# 7476,
# 7495,
# 7511,
# 7671,
# 4789,
# 12398,
# 4376,
# 3106,
# 536,
# 6206,
# 11076,
# 11433,
# 312,
# 11556,
# 2540,
# 14087,
# 14131,
# 14142,
# 14116,
# 14120,
# 12281,
# 14305,
# 14334,
# 14489,
# 8403,
# 14346,
# 5022,
# 14813,
# 14229,
# 14236,
# 14983,
# 15210,
# 16525,
# 525]
#
#real	48m10.186s
#user	0m0.548s
#sys	0m0.136s
