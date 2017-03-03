#!/usr/bin/env ruby

ApplicationModel.audited_transaction do

  puts 'Non public Jax records'
  a = MiAttempt.joins(:mi_plan => :consortium).where(:consortia => {:name => 'JAX'}, :mi_attempts => {:report_to_public => 'f'})
  puts a.count
  puts 'Public Jax records'
  a = MiAttempt.joins(:mi_plan => :consortium).where(:consortia => {:name => 'JAX'}, :mi_attempts => {:report_to_public => 't'})
  puts a.count
  puts 'Total Jax records'

  a = MiAttempt.joins(:mi_plan => :consortium).where(:consortia => {:name => 'JAX'})
  puts a.count
  a.each {|rec| MiAttempt.find(rec.id).update_attributes!(:report_to_public => 't', :audit_comment => "jax_make_public.rb")}

  puts 'No. non public Jax records after update'
  a = MiAttempt.joins(:mi_plan => :consortium).where(:consortia => {:name => 'JAX'}, :mi_attempts => {:report_to_public => 'f'})
  puts a.count
  puts 'No. public Jax records after update'
  a = MiAttempt.joins(:mi_plan => :consortium).where(:consortia => {:name => 'JAX'}, :mi_attempts => {:report_to_public => 't'})
  puts a.count

  #raise ActiveRecord::Rollback
end