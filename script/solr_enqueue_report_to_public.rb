#!/usr/bin/env ruby

require 'pp'

ENQUEUE = true
RUN_QUEUE = true
root_url = SolrUpdate::IndexProxy::Allele.get_uri.to_s + '/search?q=type:mi_attempt+id:'

#           'http://ikmc.vm.bytemark.co.uk:8984/solr/allele/search?q=type:mi_attempt+id:'
#            http://ikmc.vm.bytemark.co.uk:8984/solr/allele

puts "#### ENQUEUE: #{ENQUEUE} - RUN_QUEUE: #{RUN_QUEUE}"

puts "#### solr url: #{SolrUpdate::IndexProxy::Allele.get_uri.to_s}"

#exit

ApplicationModel.transaction do
  puts "#### enqueueing mi_attempts..."
  enqueuer = SolrUpdate::Enqueuer.new
  counter = 0
  puts "mi_attempt.id,marker_symbol,report_to_public,url,status"
  MiAttempt.all.each do |i|
    next if i.report_to_public
    #pp i
    #pp i.mi_plan.gene
    #break
    #puts "#### mi_attempt.id = #{i.id} - marker_symbol = #{i.mi_plan.gene.marker_symbol} - report_to_public = #{i.report_to_public}"
    #puts "#{i.id},#{i.mi_plan.gene.marker_symbol},#{i.report_to_public},=HYPERLINK(\"#{ROOT_URL}#{i.id}\"; \"link\"),#{i.status.name}"
    puts "#{i.id},#{i.mi_plan.gene.marker_symbol},#{i.report_to_public},=HYPERLINK(\"#{root_url}#{i.id}\"; \"link\"),#{i.status.name}"
    enqueuer.mi_attempt_updated(i) if ENQUEUE
    counter += 1
    #break
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
    raise "Unexpected phenotype_attempt found!"
  end

  puts "#### running phenotype_attempts (#{counter})..."
  SolrUpdate::Queue.run(:limit => nil) if RUN_QUEUE
end
