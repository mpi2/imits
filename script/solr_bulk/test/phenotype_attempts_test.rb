#!/usr/bin/env ruby

require 'pp'
require 'color'

@count = 0
@failed_count = 0

enabler = {
  'test_phenotype_attempt_allele_type' => true,
  'test_phenotype_attempt_allele_name' => true,
  'test_phenotype_attempt_order_from_names' => true,
  'test_phenotype_attempt_order_from_urls' => true,
  'test_phenotype_attempt_best_status_pa_cre' => true,
  'test_solr_phenotype_attempts' => true
}

def phenotype_attempt_allele_type phenotype_attempt
  allele_type = ''
  if phenotype_attempt.mouse_allele_symbol.nil?
    allele_type = phenotype_attempt.mi_attempt.allele_symbol
  else
    allele_type = phenotype_attempt.mouse_allele_symbol
  end

  allele_type = '' if allele_type.nil?

  target = allele_type[/\>(.+)?\(/, 1]
  target = target ? " (#{target})" : ''

  "Cre-excised deletion#{target}"
end

def test_phenotype_attempt_allele_type
  @count = 0
  @failed_count = 0

  PhenotypeAttempt.all.each do |phenotype_attempt|
    old = phenotype_attempt_allele_type phenotype_attempt

    # pp old

    rows = ActiveRecord::Base.connection.execute("select * from solr_get_pa_allele_type(#{phenotype_attempt.id})")

    #puts "select * from solr_mi_plan_status_stamp(#{mi_plan.id});"
    #puts "select mi_plan_status_stamps.id into result from mi_plans, mi_plan_status_stamps where mi_plan_id = #{mi_plan.id} and mi_plans.id = #{mi_plan.id} and mi_plan_status_stamps.id = mi_plans.status_id;"

    count = 0
    new = ''
    rows.each do |row|
      # pp row
      new = row['solr_get_pa_allele_type']
      #pp new
      count += 1
    end

    raise "#### invalid count detected!".red if count != 1

    if old != new
      puts "#### error: #{phenotype_attempt.id}: (#{old}/#{new})".red
      @failed_count += 1
    end

    @count += 1

    #break
  end
end

def test_phenotype_attempt_allele_name
  @count = 0
  @failed_count = 0

  PhenotypeAttempt.all.each do |phenotype_attempt|
    old = phenotype_attempt.allele_symbol

    # pp old

    rows = ActiveRecord::Base.connection.execute("select * from solr_get_pa_allele_name(#{phenotype_attempt.id})")

    count = 0
    new = ''
    rows.each do |row|
      # pp row
      new = row['solr_get_pa_allele_name']
      #pp new
      count += 1
    end

    raise "#### invalid count detected!".red if count != 1

    if old != new
      puts "#### error: #{phenotype_attempt.id}: (#{old}/#{new})".red
      @failed_count += 1
    end

    @count += 1

    #break
  end
end

def test_phenotype_attempt_order_from_names
  @count = 0
  @failed_count = 0

  PhenotypeAttempt.all.each do |phenotype_attempt|
    solr_doc = {}
    SolrUpdate::DocFactory.set_order_from_details(phenotype_attempt, solr_doc)
    old = solr_doc

    next if old.empty? || old['order_from_names'].empty?

    old = old['order_from_names']

    # pp old

    rows = ActiveRecord::Base.connection.execute("select * from solr_get_pa_order_from_names(#{phenotype_attempt.id})")

    count = 0
    new = ''
    rows.each do |row|
      # pp row
      new = row['solr_get_pa_order_from_names'].split ';'
      #pp new
      count += 1
    end

    raise "#### invalid count detected!".red if count != 1

    old = old.sort
    new = new.sort
    #new = new.sort.uniq

    #pp new
    #break

    if old.size != new.size
      puts "#### size error: #{phenotype_attempt.id}: (#{old}/#{new})".red
      @failed_count += 1
    else
      i = 0
      failed = false
      old.each do |name|
        if old[i] != new[i]
          puts "#### error: #{phenotype_attempt.id}: (#{old[i]}/#{new[i]})".red
          failed = true
        end
        i += 1
      end
      @failed_count += 1 if failed
    end

    @count += 1

    #break
  end
end

def test_phenotype_attempt_order_from_urls
  @count = 0
  @failed_count = 0

  PhenotypeAttempt.all.each do |phenotype_attempt|
    solr_doc = {}
    SolrUpdate::DocFactory.set_order_from_details(phenotype_attempt, solr_doc)
    old = solr_doc

    next if old.empty? || old['order_from_urls'].empty?

    old = old['order_from_urls']

    # pp old

    rows = ActiveRecord::Base.connection.execute("select * from solr_get_pa_get_order_from_urls(#{phenotype_attempt.id})")

    count = 0
    new = ''
    rows.each do |row|
      # pp row
      new = row['solr_get_pa_get_order_from_urls'].split ';'
      #pp new
      count += 1
    end

    raise "#### invalid count detected!".red if count != 1

    old = old.sort
    new = new.sort
    #new = new.sort.uniq

    #pp new
    #break

    if old.size != new.size
      puts "#### size error: #{phenotype_attempt.id}: (#{old}/#{new})".red
      @failed_count += 1
    else
      i = 0
      failed = false
      old.each do |name|
        if old[i] != new[i]
          puts "#### error: #{phenotype_attempt.id}: (#{old[i]}/#{new[i]})".red
          failed = true
        end
        i += 1
      end
      @failed_count += 1 if failed
    end

    @count += 1

    # break
  end
end

def test_phenotype_attempt_best_status_pa_cre cre_excision_required
  @count = 0
  @failed_count = 0

  PhenotypeAttempt.all.each do |phenotype_attempt|
    #old = phenotype_attempt_allele_type phenotype_attempt
    old = nil
    old = phenotype_attempt.status.name if cre_excision_required && phenotype_attempt.cre_excision_required
    old = phenotype_attempt.status.name if ! cre_excision_required && ! phenotype_attempt.cre_excision_required

    next if ! old

    # pp old

    rows = ActiveRecord::Base.connection.execute("select * from solr_get_best_status_pa_cre(#{phenotype_attempt.id}, #{cre_excision_required})")

    #puts "select * from solr_mi_plan_status_stamp(#{mi_plan.id});"
    #puts "select mi_plan_status_stamps.id into result from mi_plans, mi_plan_status_stamps where mi_plan_id = #{mi_plan.id} and mi_plans.id = #{mi_plan.id} and mi_plan_status_stamps.id = mi_plans.status_id;"

    count = 0
    new = ''
    rows.each do |row|
      # pp row
      new = row['solr_get_best_status_pa_cre']
      #pp new
      count += 1
    end

    raise "#### invalid count detected!".red if count != 1

    if old != new
      puts "#### error: #{phenotype_attempt.id}: (#{old}/#{new})".red
      @failed_count += 1
    end

    @count += 1

    #break
  end
end

def test_solr_phenotype_attempts
  @count = 0
  @failed_count = 0
  count = 0

  hash = {}

  attempts = ActiveRecord::Base.connection.execute("select * from solr_phenotype_attempts")

  attempts.each do |attempt|
    attempt['order_from_names'] = attempt['order_from_names'].to_s.split(';')
    attempt['order_from_urls'] = attempt['order_from_urls'].to_s.split(';')
    attempt['project_ids'] = attempt['project_ids'].to_s.split(';')
    hash[attempt['id'].to_i] = attempt.clone
    # pp attempts
    # break
    count += 1
  end

  #puts "#### count: #{count}".blue

  #pp hash.first

  # pp hash

  PhenotypeAttempt.order(:id).each do |pa|
    failed = false

    if pa.has_status? :cec and ! pa.has_status? :abt and pa.allele_id > 0 and pa.report_to_public
      docs = SolrUpdate::DocFactory.create_for_phenotype_attempt(pa)
      doc = docs.first
      next if ! doc

      #pp doc
      #pp hash[doc['id']]

      if ! hash.has_key?(doc['id'])
        puts "#### missing key: (#{doc['id']})".red
        failed = true
        #exit
      end

      if doc.keys.size != hash[doc['id']].keys.size
        puts "#### key count error: (#{doc.keys.size}/#{hash[doc['id']].keys.size})".red
        failed = true
      end

      splits = %W{order_from_names order_from_urls project_ids}

      old = doc
      new = hash[doc['id']]

      #pp old
      #pp new

      #pp new

      splits.each do |split|
        if old[split].size != new[split].size
          puts "#### #{doc['id']}: split count error: '#{split}' (#{old[split].size}/#{new[split].size})".red
          failed = true
        end

        old[split] = old[split].sort
        new[split] = new[split].sort
        i = 0
        old[split].each do |item|
          if item != new[split][i]
            puts "#### #{doc['id']}: split compare error: '#{split}' (#{item}/#{new[split][i]})".red
            failed = true
          end
          i += 1
        end
      end

      old.keys.each do |key|
        next if splits.include?(key)
        if old[key].to_s != new[key].to_s
          puts "#### #{doc['id']}: compare error: '#{key}' (#{old[key]}/#{new[key]})".red
          failed = true
        end
      end

      @count += 1
      @failed_count += 1 if failed

      #if failed
      #splits.each do |split|
      #  pp old['id']
      #  pp old[split]
      #  pp new['id']
      #  pp new[split]
      #end
      #end

      #break if @count >= 500
    end
  end

  puts "#### count error: (#{count}/#{@count})".red if count != @count
end

sql = 'CREATE temp table solr_get_pa_order_from_names_tmp ( phenotype_attempt_id int, name text ) ;'
sql += 'CREATE temp table solr_get_pa_get_order_from_urls_tmp ( phenotype_attempt_id int, url text ) ;'

ActiveRecord::Base.connection.execute(sql)

if enabler['test_phenotype_attempt_allele_type']
  test_phenotype_attempt_allele_type

  puts "#### done test_phenotype_attempt_allele_type: (#{@failed_count}/#{@count})".red if @failed_count > 0
  puts "#### done test_phenotype_attempt_allele_type: (#{@count})".green if @failed_count == 0
end

if enabler['test_phenotype_attempt_allele_name']
  test_phenotype_attempt_allele_name

  puts "#### done test_phenotype_attempt_allele_name: (#{@failed_count}/#{@count})".red if @failed_count > 0
  puts "#### done test_phenotype_attempt_allele_name: (#{@count})".green if @failed_count == 0
end

if enabler['test_phenotype_attempt_order_from_names']
  test_phenotype_attempt_order_from_names

  puts "#### done test_phenotype_attempt_order_from_names: (#{@failed_count}/#{@count})".red if @failed_count > 0
  puts "#### done test_phenotype_attempt_order_from_names: (#{@count})".green if @failed_count == 0
end

if enabler['test_phenotype_attempt_order_from_urls']
  test_phenotype_attempt_order_from_urls

  puts "#### done test_phenotype_attempt_order_from_urls: (#{@failed_count}/#{@count})".red if @failed_count > 0
  puts "#### done test_phenotype_attempt_order_from_urls: (#{@count})".green if @failed_count == 0
end

if enabler['test_phenotype_attempt_best_status_pa_cre']
  test_phenotype_attempt_best_status_pa_cre false
  puts "#### done test_phenotype_attempt_best_status_pa_cre: (#{@failed_count}/#{@count})".red if @failed_count > 0
  puts "#### done test_phenotype_attempt_best_status_pa_cre: (#{@count})".green if @failed_count == 0

  test_phenotype_attempt_best_status_pa_cre true
  puts "#### done test_phenotype_attempt_best_status_pa_cre: (#{@failed_count}/#{@count})".red if @failed_count > 0
  puts "#### done test_phenotype_attempt_best_status_pa_cre: (#{@count})".green if @failed_count == 0
end

if enabler['test_solr_phenotype_attempts']
  test_solr_phenotype_attempts

  puts "#### done test_solr_phenotype_attempts: (#{@failed_count}/#{@count})".red if @failed_count > 0
  puts "#### done test_solr_phenotype_attempts: (#{@count})".green if @failed_count == 0
end
