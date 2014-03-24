#!/usr/bin/env ruby

require 'pp'
require 'color'

STDOUT.sync = true

class AllelesTest
  def initialize
    @count = 0
    @failures = [7817,
      7960,
      7961,
      11175,
      11176,
      11673,
      13865,
      13866,
      14405,
      14406,
      16605,
      16606,
      17674,
      20797,
      20798,
      20799,
      20800,
      20801,
      20802,
      20803,
      20804,
      20805,
      20806,
      20807,
      20808,
      20809,
      20810,
      20811,
      20812,
      20813,
      20814,
      20815,
      20816,
      20818,
      20819,
      20820,
      20821,
      20822,
      20823,
      20824,
      20825,
      20826,
      20827,
      20828,
      20829,
      20830,
      20831,
      20832,
      20833,
      20834,
      20835,
      20836,
      20837,
      20838,
      20839,
      20840,
      20841,
      20842,
      20843,
      20844,
      20845,
      20846,
      20847,
      20848,
      20849,
      20850,
      20851,
      20852,
      20853,
      20854,
      20855,
      20856,
      20857,
      20858,
      20859,
      20860,
      20861,
      20862,
      20863,
      20864,
      20866,
      20867,
      20868,
      20869,
      20870,
      20871,
      20872,
      20873,
      20874,
      20875,
      20876,
      20877,
      20878,
      20879,
      20880,
      20882,
      20883,
      20884,
      20885,
      20887,
      20888,
      20889,
      20890,
      20892,
      20893,
      20894,
      20895,
      20896,
      20897,
      20898,
      20899,
      20900,
      20901,
      20902,
      20903,
      20904,
      20905,
      20906,
      20907,
      20908,
      20909,
      20910,
      20911,
      20912,
      20912,
      20913,
      20914,
      20916,
      20917,
      20918,
      20919,
      20920,
      20921,
      20922,
      20923,
      20924,
      20925,
      20926,
      20927,
      20928,
      20929,
      20930,
      20931,
      20932,
      20933,
      23792,
      23793,
      24132,
      24421,
      24558,
      24564,
      24572,
      24628,
      24629,
      24630,
      24631,
      24636,
      24637,
      24638,
      24639,
      24896,
      24986,
      25847,
      25848,
      25849,
      25851,
      25852,
      25852,
      25853,
      25854,
      25855,
      25856,
      25858,
      25859,
      25860,
      25861,
      25862,
      25863,
      25865,
      25866,
      25867,
      25908,
      26096,
      26155,
      26156,
      26157,
      26158,
      27356,
      27357,
      27358,
      27359,
      27360,
      27361,
      27362,
      27363,
      27364,
      27365,
      27366,
      27367,
      27368,
      27369,
      27370,
      27371,
      27372,
      27373,
      27374,
      27375,
      27376,
      27377,
      27378,
      27379,
      27380,
      27381,
      27382,
      27383,
      27384,
      27385,
      27386,
      27387,
      27388,
      27389,
      27390,
      27391,
      27392,
      27393,
      27394,
      27395,
      27396,
      27397,
      27398,
      27399,
      27400,
      27401,
      27402,
      27403,
      27404,
      27405,
      27406,
      27407,
      27408,
      27409,
      27410,
      27411,
      27412,
      27413,
      27414,
      27415,
      27416,
      27417,
      27418,
      27419,
      27420,
      27421,
      27422,
      27423,
      27424,
      27425,
      27426,
      27427,
      27428,
      27429,
      27430,
      27431,
      27432,
      27433,
      27434,
      27435,
      27436,
      27437,
      27438,
      27439,
      27440,
      27441,
      27442,
      27443,
      27444,
      27445,
      27446,
      27447,
      27448,
      27449,
      27450,
      27451,
      27452,
      27453,
      27454,
      27455,
      27456,
      27457,
      27458,
      27459,
      27460,
      27461,
      27462,
      27463,
      27464,
      27465,
      27466,
      27467,
      27468,
      27469,
      27470,
      27471,
      27472,
      27473,
      27474,
      27475,
      27476,
      27477,
      27478,
      27479,
      27480,
      27481,
      27482,
      27483,
      27484,
      27485,
      27486,
      27487,
      27488,
      27489,
      27490,
      27491,
      27492,
      27493,
      27494,
      27495,
      27496,
      27497,
      27498,
      27499,
      27500,
      27501,
      27502,
      27503,
      27504,
      27505,
      27506,
      27507,
      27508,
      27509,
      27510,
      27511,
      27512,
      27513,
      27514,
      27515,
      27516,
      27517,
      27518,
      27519,
      27520,
      27521,
      27522,
      27523,
      27524,
      27525,
      27526,
      27527,
      27528,
      27529,
      27530,
      27531,
      27532,
      27533,
      27534,
      27535,
      27536,
      27537,
      27538,
      27539,
      27540,
      27541,
      27542,
      27543,
      27544,
      27545,
      27546,
      27547,
      27548,
      27549,
      27550,
      27551,
      27552,
      27553,
      27554,
      27555,
      27556,
      27557,
      27558,
      27559,
      27560,
      27561,
      27562,
      27563,
      27564,
      27565,
      27566,
      27567,
      27568,
      27569,
      27570,
      27571,
      27572,
      27573,
      27574,
      27575,
      27576,
      27577,
      27578,
      27579,
      27580,
      27581,
      27582,
      27583,
      27584,
      27585,
      27586,
      27587,
      27588,
      27589,
      27590,
      27591,
      27592,
      27593,
      27594,
      27595,
      27596,
      27597,
      27598,
      27599,
      27600,
      27601,
      27602,
      27603,
      27604,
      27605,
      27606,
      27607,
      27608,
      27609,
      27610,
      27611,
      27612,
      27613,
      27614,
      27615,
      27616,
      27617,
      27618,
      27619,
      27620,
      27621,
      27622,
      27623,
      27624,
      27625,
      27626,
      27627,
      27628,
      27629,
      27630,
      27631,
      27632,
      27633,
      27634,
      27635,
      27636,
      27637,
      27638,
      27639,
      27640,
      27641,
      27642,
      27643,
      27644,
      27645,
      27646,
      27647,
      27648,
      27649,
      27650,
      27651,
      27652,
      27653,
      27654,
      27655,
      27656,
      27657,
      27658,
      27659,
      27660,
      27661,
      27662,
      27663,
      27664,
      27665,
      27666,
      27667,
      27668,
      27669,
      27670,
      27671,
      27672,
      27673,
      27674,
      27675,
      27676,
      27677,
      27678,
      27679,
      27680,
      27681,
      27682,
      27683,
      27684,
      27685,
      27686,
      27687,
      27688,
      27689,
      27690,
      27691,
      27692,
      27693,
      27694,
      27695,
      27696,
      27697,
      27698,
      27699,
      27700,
      27701,
      27702,
      27703,
      27704,
      27705,
      27706,
      27707,
      27708,
      27709,
      27710,
      27711,
      27712,
      27713,
      27714,
      27715,
      27716,
      27717,
      27718,
      27719,
      27720,
      27721,
      27722,
      27723,
      27724,
      27725,
      27726,
      27727,
      27728,
      27729,
      27730,
      27731,
      27732,
      27733,
      27734,
      27735,
      27736,
      27737,
      27738,
      27739,
      27740,
      27741,
      27742,
      27743,
      27744,
      27745,
      27746,
      27747,
      27748,
      27749,
      27750,
      27751,
      27752,
      27753,
      27754,
      27755,
      27756,
      27757,
      27758,
      27759,
      27760,
      27761,
      27762,
      27763,
      27764,
      27765,
      27766,
      27767,
      27768,
      27769,
      27770,
      27771,
      27772,
      27773,
      27774,
      27775,
      27776,
      27777,
      27778,
      27779,
      27780,
      27781,
      27782,
      27783,
      27784,
      27785,
      27786,
      27787,
      27788,
      27789,
      27790,
      27791,
      27792,
      27793,
      27794,
      27795,
      27796,
      27797,
      27798,
      27799,
      27800,
      27801,
      27802,
      27803,
      27804,
      27805,
      27806,
      27807,
      27808,
      27809,
      27810,
      27811,
      27812,
      27813,
      27814,
      27815,
      27816,
      27817,
      27818,
      27819,
      27820,
      27821,
      27822,
      27823,
      27824,
      27825,
      27826,
      27827,
      27828,
      27829,
      27830,
      27831,
      27832,
      27833,
      27834,
      27835,
      27836,
      27837,
      27838,
      27839,
      27840,
      27841,
      27842,
      27843,
      27844,
      27845,
      27846,
      27847,
      27848,
      27849,
      27850,
      27851,
      27852,
      27853,
      27854,
      27855,
      27856,
      27857,
      27858,
      27859,
      27860,
      27861,
      27862,
      27863,
      27864,
      27865,
      27866,
      27867,
      27868,
      27869,
      27870,
      27871,
      27872,
      27873,
      27874,
      27875,
      27876,
      27877,
      27878,
      27879,
      27880,
      27881,
      27882,
      27883,
      27884,
      27885,
      27886,
      27887,
      27888,
      27889,
      27890,
      27891,
      27892,
      27893,
      27894,
      27895,
      27896,
      27897,
      27898,
      27899,
      27900,
      27901,
      27902,
      27903,
      27904,
      27905,
      27906,
      27907,
      27908,
      27909,
      27910,
      27911,
      27912,
      27913,
      27914,
      27915,
      27916,
      27917,
      27918,
      27919,
      27920,
      27921,
      27922,
      27923,
      27924,
      27925,
      27926,
      27927,
      28429,
      28771,
      28772,
      28773,
      28782,
      28783,
      28787,
      28813,
      28814,
      28815,
      28816,
      28858,
      28859,
      28860,
      28861,
      28862,
      29100,
      29103,
      29112,
      29114,
      30981,
      31008,
      31042,
      31053,
      31097,
      31103,
      31107,
      31132,
      31133,
      31135,
      31136,
      31137,
      31138,
      31139,
      31140,
      31143,
      31145,
      31213,
      33197,
      33440,
      35072,
      35087,
      35183,
      36150,
      36151,
      36152,
      36153,
      36154,
      36155,
      36156,
      36157,
      36158,
      36159,
      36160,
      36161,
      36162,
      36163,
      36164,
      36165,
      36166,
      36167,
      36168,
      36169,
      36170,
      36171,
      36172,
      36173,
      36174,
      36175,
      36176,
      36481,
      36482,
      36483,
      36484,
      36485,
      36486,
      36487,
      36488,
      36489,
      36490,
      36491,
      36492,
      36493,
      36494,
      36507,
      36513,
      36552,
      36553,
      36554,
      36584,
      37427,
      40668,
      42125,
      42701,
      42702,
      42703,
      42704,
      42705,
      42706,
      42707,
      42708,
      42709,
      42710,
      42711,
      42712,
      42713,
      42714,
      42715,
      42716,
      42717,
      42718,
      42719,
      42720,
      42721,
      42722,
      42723,
      42724,
      42725,
      42733,
      42734,
      42735,
      42736,
      42737,
      42786,
      42914,
      43067,
      43070,
      43071,
      43988,
      44024,
      44028,
      44035,
      44036,
      44037,
      44038,
    44039]

    @failed_count = 0
    @batch_size = 1000

    @enabler = {
      'test_solr_alleles' => true
    }
  end

  def log message
    puts "#### #{message}"
  end

  def compare old, new, silent = true
    splits = %W{order_from_names order_from_urls project_ids project_statuses project_pipelines vector_project_ids vector_project_statuses}
    failed = false

    splits.each do |split|
      old.delete(split) if ! old[split] || old[split].empty?
      new.delete(split) if ! new[split] || new[split].empty?
    end

    if old.keys.size != new.keys.size
      puts "#### #{old['id']}: key count error (#{old.keys.size}/#{new.keys.size})".red
      diff = old.keys - new.keys
      diff = new.keys - old.keys if ! diff || diff.empty?
      pp diff if ! silent
      failed = true
    end

    splits.each do |split|
      old[split] = old[split].to_a.sort.uniq
      new[split] = new[split].to_a.sort.uniq

      next if old[split].empty? && new[split].empty?

      if old[split].size != new[split].size
        puts "#### #{old['id']}: split key count error (#{old[split].size}/#{new[split].size})".red if ! silent
        failed = true
        next
      end

      for i in 0..old[split].size
        if old[split][i].to_s != new[split][i].to_s
          puts "#### #{old['id']}: '#{split}': compare error (#{old[split][i]}/#{new[split][i]})".red if ! silent
          failed = true
        end
      end
    end

    old.keys.each do |key|
      next if splits.include? key
      if old[key].to_s != new[key].to_s
        puts "#### #{old['id']}: '#{key}': compare error 2 (#{old[key].to_s}/#{new[key].to_s})".red if ! silent
        failed = true
      end
    end

    difference = (old.size > new.size) ? old.to_a - new.to_a : new.to_a - old.to_a

    if ! silent && difference && ! difference.empty?
      puts "#### difference:"
      pp difference
      #pp old
      #pp new
      #  exit
    end

    failed
  end

  def test_solr_alleles
    @count = 0
    @failed_count = 0
    count = 0
    @ids = []

    hash = {}

    log 'start building hash...'

    #alleles = ActiveRecord::Base.connection.execute("select * from solr_alleles where id = 235")
    alleles = ActiveRecord::Base.connection.execute("select * from solr_alleles")

    splits = %W{order_from_names order_from_urls project_ids project_statuses project_pipelines vector_project_ids vector_project_statuses}
    ints = %W{id allele_id}

    log 'start loop...'

    alleles.each do |allele|
      splits.each do |split|
        allele[split] = allele[split].to_s.split(';')
      end

      ints.each do |i|
        allele[i] = allele[i].to_i
      end

      hash[allele['id']] ||= []
      hash[allele['id']].push allele.clone
      count += 1
      @ids.push allele['id']

      #if allele['id'] == 235
      #  puts "#### found!".green
      #end
    end

    log "end loop (#{count})..."

    log 'start main loop...'

    #TargRep::TargetedAllele.find_each(:batch_size => @batch_size) do |allele|
    #TargRep::TargetedAllele.find(:id => @ids) do |allele|
    # alleles.each do |allele|

    #  allele_old = TargRep::TargetedAllele.find_by_id allele['id']

    #pp @failures
    #exit

    #TargRep::TargetedAllele.find_each(:batch_size => @batch_size) do |allele|
    TargRep::TargetedAllele.where(:id => @failures) do |allele|
       log 'start create_for_allele...'
      docs = SolrUpdate::DocFactory.create_for_allele(allele)

      #if ! allele_old
      #  puts "#### #{allele['id']}: cannot find in db!".red
      #  @failed_count += 1
      #  next
      #end

      #docs = SolrUpdate::DocFactory.create_for_allele(allele_old)

      if ! docs || docs.empty?
        log 'no doc!'
        #puts "#### #{allele['id']}: cannot find in docs!".red
        #@failed_count += 1
        next
      end

      #@count += docs.size

      docs.each do |doc|
        old = doc

        @count += 1

        #if ! hash.has_key? old['id'].to_i
        #  puts "#### #{old['id']}: cannot find in hash!".red
        #  @failed_count += 1
        #  next
        #end

        ok = false

        hash[old['id']].each do |new|
          ok = ! compare(old, new)
          break if ok
        end

        if ! ok
          @failed_count += 1
          puts "#### #{old['id']}: failed!".red
          #if hash[old['id']].size == 1
          #  compare old, hash[old['id']].first, false
          #end
          #@failures.push old['id']
        end
      end

      #break if @count >= 10000
    end

    log 'end main loop...'

    puts "#### count error: (#{@count}/#{count})".red if count != @count
  end

  def test_solr_alleles_counts
    @count_new = 0
    @count_old = 0

    alleles = ActiveRecord::Base.connection.execute("select * from solr_alleles")

    alleles.each do |allele|
      @count_new += 1
    end

    TargRep::TargetedAllele.find_each(:batch_size => @batch_size) do |allele|
      docs = SolrUpdate::DocFactory.create_for_allele(allele)
      next if ! docs
      @count_old += docs.size
    end

    puts "#### count error: (#{@count_old}/#{@count_new})".red if @count_old != @count_new
  end

  def run
    puts "#### starting alleles...".blue

    if @enabler['test_solr_alleles']
      test_solr_alleles

      puts "#### done test_solr_alleles: (#{@failed_count}/#{@count})".red if @failed_count > 0
      puts "#### done test_solr_alleles: (#{@count})".green if @failed_count == 0

      #pp @failures if @failures && ! @failures.empty?
    end
  end
end

#AllelesTest.new.run if File.basename($0) !~ /rake/
