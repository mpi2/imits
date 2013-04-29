#!/usr/bin/env ruby

require 'pp'

LIMIT = 5000

#SolrUpdate::Queue::Item.where('gene_id is not null').destroy_all

puts "MiPlan Count: #{MiPlan.all.size}"

@enqueuer = SolrUpdate::Enqueuer.new

counter = 0
hash = {}
MiPlan.find(:all, :order => :id).each do |plan|
  #MiPlan.find(:all, :order => :id, :conditions => { :id => 528 }).each do |plan|

  #plan = MiPlan.find 1
  #plan = MiPlan.find 528

  #pp plan
  #pp plan.status
  ##pp plan.mi_attempts

  #plan.mi_attempts.each do |mi|
  #  pp mi
  #  pp mi.status_stamps
  #end

  @enqueuer.mi_plan_updated(plan)

  # pp plan.gene

  hash[plan.gene_id] ||= 1
  hash[plan.gene_id] += 1

  counter += 1
  break if counter > 0 && counter >= LIMIT

end

puts "run queue..."
SolrUpdate::Queue.run(:limit => hash.keys.size)
#SolrUpdate::Queue.run #:limit => 300
#SolrUpdate::Queue.run #:limit => 300
#SolrUpdate::Queue.run #:limit => 300
#SolrUpdate::Queue.run #:limit => 300

puts "Processed Genes: #{hash.keys.size}"
puts "Processed Plans: #{counter}"
