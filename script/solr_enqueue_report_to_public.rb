#!/usr/bin/env ruby

require 'pp'

ENQUEUE = true
RUN_QUEUE = true

puts "#### solr url:"
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
