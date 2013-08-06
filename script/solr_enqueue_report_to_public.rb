#!/usr/bin/env ruby

require 'pp'

#LIMIT = -1
#
##SolrUpdate::Queue::Item.where('gene_id is not null').destroy_all
#
#size = SolrUpdate::Queue::Item.where('gene_id is not null').size
#
#raise "#### queue contains #{size} gene records!" if size > 0
#
#puts "MiPlan Count: #{MiPlan.all.size}"
#
#@enqueuer = SolrUpdate::Enqueuer.new
#
#counter = 0
#hash = {}
#
#MiPlan.find(:all, :order => :id).each do |plan|
#
##puts "Plan id: #{plan.id} - Gene: #{plan.gene.marker_symbol}"
#
#@enqueuer.mi_plan_updated(plan)
#
#hash[plan.gene_id] ||= 1
#hash[plan.gene_id] += 1
#
#counter += 1
#break if LIMIT > 0 && counter >= LIMIT
#
#end
#
#puts "run queue..."
#
#SolrUpdate::Queue.run(:limit => hash.keys.size)
#
#puts "Processed Genes: #{hash.keys.size}"
#puts "Processed Plans: #{counter}"

ENQUEUE = true
RUN_QUEUE = true

pp SolrUpdate::IndexProxy::Allele.get_uri

ApplicationModel.transaction do
  puts "#### enqueueing mi_attempts..."
  enqueuer = SolrUpdate::Enqueuer.new
  counter = 0
  MiAttempt.all.each do |i|
    next if i.report_to_public
    enqueuer.mi_attempt_updated(i) if ENQUEUE
    counter += 1
  end

  puts "#### running mi_attempts (#{counter})..."
  SolrUpdate::Queue.run(:limit => nil) if RUN_QUEUE
end

pp SolrUpdate::IndexProxy::Allele.get_uri

ApplicationModel.transaction do
  puts "#### enqueueing phenotype_attempts..."
  enqueuer = SolrUpdate::Enqueuer.new
  counter = 0
  PhenotypeAttempt.all.each do |p|
    next if p.report_to_public
    enqueuer.phenotype_attempt_updated(p) if ENQUEUE
    counter += 1
  end

  puts "#### running phenotype_attempts (#{counter})..."
  SolrUpdate::Queue.run(:limit => nil) if RUN_QUEUE
end
