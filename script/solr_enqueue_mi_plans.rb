#!/usr/bin/env ruby

require 'pp'

LIMIT = -1

#SolrUpdate::Queue::Item.where('gene_id is not null').destroy_all

raise "#### queue already contains records!" if SolrUpdate::Queue::Item.where('gene_id is not null').size > 0

puts "MiPlan Count: #{MiPlan.all.size}"

@enqueuer = SolrUpdate::Enqueuer.new

counter = 0
hash = {}

MiPlan.find(:all, :order => :id).each do |plan|

  #puts "Plan id: #{plan.id} - Gene: #{plan.gene.marker_symbol}"

  @enqueuer.mi_plan_updated(plan)

  hash[plan.gene_id] ||= 1
  hash[plan.gene_id] += 1

  counter += 1
  break if LIMIT > 0 && counter >= LIMIT

end

puts "run queue..."

SolrUpdate::Queue.run(:limit => hash.keys.size)

puts "Processed Genes: #{hash.keys.size}"
puts "Processed Plans: #{counter}"
