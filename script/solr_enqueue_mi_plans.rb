#!/usr/bin/env ruby

require 'pp'

#@enqueuer = SolrUpdate::Enqueuer.new
#
##puts "#### allele:"
##pp TargRep::Allele.all.first
##@enqueuer.allele_updated(TargRep::Allele.all.first)
#
#puts "\n\n#### plan:"
#pp MiPlan.all.first
#
#@enqueuer.mi_plan_updated(MiPlan.all.first)
#
#SolrUpdate::Queue.run
#
#exit

LIMIT = 500

#SolrUpdate::Queue::Item.where('gene_id is not null').destroy_all

puts "MiPlan Count: #{MiPlan.all.size}"

@enqueuer = SolrUpdate::Enqueuer.new

counter = 0
hash = {}
#MiPlan.all.each do |plan|
#MiPlan.find(:all, :order => :id).each do |plan|

#plan = MiPlan.find 1
plan = MiPlan.find 528

  pp plan
  pp plan.status
  #pp plan.mi_attempts

  plan.mi_attempts.each do |mi|
    pp mi
    pp mi.status_stamps
  end

  @enqueuer.mi_plan_updated(plan)

  # pp plan.gene

  hash[plan.gene_id] ||= 1
  hash[plan.gene_id] += 1

  counter += 1
 # break if counter >= LIMIT

#end

SolrUpdate::Queue.run(:limit => hash.keys.size)

puts "Processed Genes: #{hash.keys.size}"
puts "Processed Plans: #{counter}"
