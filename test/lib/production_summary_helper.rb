# encoding: utf-8

require 'test_helper'

class ProductionSummaryHelper

  TEST_CSV_FEED_UNIT = <<-"CSV"
"Consortium","Sub-Project","Priority","Production Centre","Gene","MGI Accession ID","Overall Status","MiPlan Status","MiAttempt Status","PhenotypeAttempt Status","IKMC Project ID","Mutation Sub-Type","Allele Symbol","Genetic Background","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date","Phenotype Attempt Registered Date","Rederivation Started Date","Rederivation Complete Date","Cre Excision Started Date","Cre Excision Complete Date","Phenotyping Started Date","Phenotyping Complete Date","Phenotype Attempt Aborted Date"
"BaSH",,"High","BCM","1700093J21Rik","MGI:1921546","Assigned - ES Cell QC In Progress","Assigned - ES Cell QC In Progress",,,,,,,"2011-10-10","2011-11-16",,,,,,,,,,,,
"BaSH",,"High","BCM","Akt1s1","MGI:1914855","Micro-injection in progress","Assigned","Micro-injection in progress",,28913,"conditional_ready","Akt1s1<sup>tm1a(EUCOMM)Wtsi</sup>","C57BL/6N","2011-10-10",,,"2011-09-27",,,,,,,,,,
"BaSH",,"High","BCM","Alg10b","MGI:2146159","Genotype confirmed","Assigned","Genotype confirmed",,"VG10825","deletion","Alg10b<sup>tm1(KOMP)Vlcg</sup>","C57BL/6N","2011-10-10",,,"2011-09-08","2012-01-07",,,,,,,,,
"BaSH",,"High","BCM","Acot6","MGI:1921287","Phenotyping Complete","Assigned","Genotype confirmed","Phenotyping Complete",31219,"conditional_ready","Acot6<sup>tm1a(KOMP)Wtsi</sup>","C57BL/6NTac/Den","2008-06-11",,,"2008-06-11","2008-12-29",,"2012-01-09",,,"2012-01-09",,"2012-01-09","2012-01-09",
  CSV

  TEST_CSV_FEED_INT = <<-"CSV"
"Consortium","Sub-Project","Priority","Production Centre","Gene","MGI Accession ID","Overall Status","MiPlan Status","MiAttempt Status","PhenotypeAttempt Status","IKMC Project ID","Mutation Sub-Type","Allele Symbol","Genetic Background","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date","Phenotype Attempt Registered Date","Rederivation Started Date","Rederivation Complete Date","Cre Excision Started Date","Cre Excision Complete Date","Phenotyping Started Date","Phenotyping Complete Date","Phenotype Attempt Aborted Date"
"BaSH",,"High","BCM","1700093J21Rik","MGI:1921546","Assigned - ES Cell QC In Progress","Assigned - ES Cell QC In Progress",,,,,,,"2011-10-10","2011-11-16",,,,,,,,,,,,
"BaSH",,"High","BCM","Akt1s1","MGI:1914855","Micro-injection in progress","Assigned","Micro-injection in progress",,28913,"conditional_ready","Akt1s1<sup>tm1a(EUCOMM)Wtsi</sup>","C57BL/6N","2011-10-10",,,"2011-09-27",,,,,,,,,,
"BaSH",,"High","BCM","Alg10b","MGI:2146159","Genotype confirmed","Assigned","Genotype confirmed",,"VG10825","deletion","Alg10b<sup>tm1(KOMP)Vlcg</sup>","C57BL/6N","2011-10-10",,,"2011-09-08","2012-01-07",,,,,,,,,
"BaSH",,"High","BCM","Acot6","MGI:1921287","Phenotyping Complete","Assigned","Genotype confirmed","Phenotyping Complete",31219,"conditional_ready","Acot6<sup>tm1a(KOMP)Wtsi</sup>","C57BL/6NTac/Den","2008-06-11",,,"2008-06-11","2008-12-29",,"2012-01-09",,,"2012-01-09",,"2012-01-09","2012-01-09",
"DTCC-Legacy",,"High","UCD","0610007L01Rik","MGI:1918917","Genotype confirmed","Assigned","Genotype confirmed",,"VG13171","deletion","0610007L01Rik<sup>tm1(KOMP)Vlcg</sup>",,"2010-04-01",,,"2010-04-01","2010-04-01"
"DTCC-Legacy",,"High","UCD","1300002K09Rik","MGI:1921402","Genotype confirmed","Assigned","Genotype confirmed",,29982,"conditional_ready","1300002K09Rik<sup>tm1a(KOMP)Wtsi</sup>",,"2009-07-01",,,"2009-08-25","2010-07-20"
"DTCC-Legacy",,"High","UCD","1700003F12Rik","MGI:1922730","Genotype confirmed","Assigned","Genotype confirmed",,"VG10243","deletion","1700003F12Rik<sup>tm1(KOMP)Vlcg</sup>",,"2011-10-19",,,"2011-06-09","2011-10-19"
"DTCC-Legacy",,"High","UCD","1700011F03Rik","MGI:1921471","Genotype confirmed","Assigned","Genotype confirmed",,"VG11827","deletion","1700011F03Rik<sup>tm1(KOMP)Vlcg</sup>",,"2010-03-05",,,"2010-03-05","2010-03-05"
"DTCC-Legacy",,"High","UCD","1810027O10Rik","MGI:1916436","Genotype confirmed","Assigned","Genotype confirmed",,"VG11870","deletion","1810027O10Rik<sup>tm1(KOMP)Vlcg</sup>",,"2010-03-30",,,"2010-03-30","2010-03-30"
  CSV

    EXPECTEDS_FEED_UNIT_1 = {
      'Consortium' => "BaSH",
      'All Projects' => "<a title='Click to see list of All Projects' href='?consortium=BaSH&type=All+Projects'>4</a>",
      'Project started' => "<a title='Click to see list of Project started' href='?consortium=BaSH&type=Project+started'>3</a>",
      'Microinjection in progress' => "<a title='Click to see list of Microinjection in progress' href='?consortium=BaSH&type=Microinjection+in+progress'>2</a>",
      'Genotype Confirmed Mice' => "<a title='Click to see list of Genotype Confirmed Mice' href='?consortium=BaSH&type=Genotype+Confirmed+Mice'>1</a>",
      'Phenotype data available' => "<a title='Click to see list of Phenotype data available' href='?consortium=BaSH&type=Phenotype+data+available'>1</a>"
    }    
    EXPECTEDS_FEED_UNIT_2 = {
      'Consortium' => "BaSH",
      'All Projects' => "4",
      'Project started' => "3",
      'Microinjection in progress' => "2",
      'Genotype Confirmed Mice' => "1",
      'Phenotype data available' => "1"
    }
  EXPECTEDS_FEED_UNIT_3 =
    [
        { :consortium => 'BaSH', :type => 'All Projects', :result => 4},
        { :consortium => 'BaSH', :type => 'Project started', :result => 3 },
        { :consortium => 'BaSH', :type => 'Microinjection in progress', :result => 2 },
        { :consortium => 'BaSH', :type => 'Genotype Confirmed Mice', :result => 1 },
        { :consortium => 'BaSH', :type => 'Phenotype data available', :result => 1 }
    ]          
  EXPECTEDS_SUMMARY_BY_CONSORTIUM = {
    'All' => 7,
    'ES QC started' => 1,
    'ES QC confirmed' => 1,
    'ES QC failed' => 1,
    'MI in progress' => 2,
    'MI Aborted' => 1,
    'Genotype Confirmed Mice' => 1,
    'Pipeline efficiency (%)' => 33
  }
  EXPECTEDS_KOMP2 = {
    'All' => 7,
    'ES QC started' => 1,
    'ES QC confirmed' => 1,
    'ES QC failed' => 1,
    'Production Centre' => 'BCM',
    'MI in progress' => 2,
    'MI Aborted' => 1,
    'Genotype Confirmed Mice' => 1,
    'Pipeline efficiency (%)' => 33,
    'Registered for Phenotyping' => 0
  }

  CSV_LINES = {
  'HEADING' => '"Consortium","Sub-Project","Priority","Production Centre","Gene","MGI Accession ID","Overall Status","MiPlan Status","MiAttempt Status","PhenotypeAttempt Status","IKMC Project ID","Mutation Sub-Type","Allele Symbol","Genetic Background","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date","Phenotype Attempt Registered Date","Rederivation Started Date","Rederivation Complete Date","Cre Excision Started Date","Cre Excision Complete Date","Phenotyping Started Date","Phenotyping Complete Date","Phenotype Attempt Aborted Date"',
  'ES_QC_STARTED'  => '"BaSH",,"High","BCM","1700093J21Rik","MGI:1921546","Assigned - ES Cell QC In Progress","Assigned - ES Cell QC In Progress",,,,,,,"2011-10-10","2011-11-16",,,,,,,,,,,,',
  'ES_QC_CONFIRMED'  => '"BaSH",,"High","BCM","Adsl","MGI:103202","Assigned - ES Cell QC Complete","Assigned - ES Cell QC Complete",,,,,,,"2011-10-10","2011-11-04","2011-11-25"',
  'ES_QC_FAILED' => '"BaSH",,"High","BCM","Clvs2","MGI:2443223","Aborted - ES Cell QC Failed","Aborted - ES Cell QC Failed",,,,,,,"2011-10-10"',
  'MI_IN_PROGRESS' => '"BaSH",,"High","BCM","Akt1s1","MGI:1914855","Micro-injection in progress","Assigned","Micro-injection in progress",,28913,"conditional_ready","Akt1s1<sup>tm1a(EUCOMM)Wtsi</sup>","C57BL/6N","2011-10-10",,,"2011-09-27",,,,,,,,,,',
  'MI_ABORTED' => '"BaSH",,"High","BCM","Apc2","MGI:1346052","Micro-injection aborted","Assigned","Micro-injection aborted",,26234,"conditional_ready","Apc2<sup>tm1a(KOMP)Wtsi</sup>",,"2011-12-01",,,"2011-09-05",,"2011-12-02"',
  'GENOTYPE_CONFIRMED_MICE' => '"BaSH",,"High","BCM","Alg10b","MGI:2146159","Genotype confirmed","Assigned","Genotype confirmed",,"VG10825","deletion","Alg10b<sup>tm1(KOMP)Vlcg</sup>","C57BL/6N","2011-10-10",,,"2011-09-08","2012-01-07",,,,,,,,,',
  'LANGUISHING' => '"BaSH",,"High","BCM","Akt1s1","MGI:1914855","Micro-injection in progress","Assigned","Micro-injection in progress",,28913,"conditional_ready","Akt1s1<sup>tm1a(EUCOMM)Wtsi</sup>","C57BL/6N","2011-10-10",,,"2009-09-27"'
  }  
  SUMMARY_BY_CONSORTIUM_CSV = [
      CSV_LINES['HEADING'],
      CSV_LINES['ES_QC_STARTED'],
      CSV_LINES['ES_QC_CONFIRMED'],
      CSV_LINES['ES_QC_FAILED'],
      CSV_LINES['MI_IN_PROGRESS'],
      CSV_LINES['MI_ABORTED'],
      CSV_LINES['GENOTYPE_CONFIRMED_MICE'],
      CSV_LINES['LANGUISHING']
    ].join("\n")
  
  def self.get_expecteds(type)
    return EXPECTEDS_FEED_UNIT_1 if type == 'feed_unit_1'
    return EXPECTEDS_FEED_UNIT_2 if type == 'feed_unit_2'
    return EXPECTEDS_FEED_UNIT_3 if type == 'feed_unit_3'
    return EXPECTEDS_SUMMARY_BY_CONSORTIUM if type == 'komp2 brief'
    return EXPECTEDS_SUMMARY_BY_CONSORTIUM if type == 'summary by consortium'
    return EXPECTEDS_SUMMARY_BY_CONSORTIUM if type == 'summary by consortium priority'
    return EXPECTEDS_KOMP2 if type == 'komp2'
    return nil
  end

  def self.get_csv(type)
    return TEST_CSV_FEED_UNIT if type == 'feed unit'
    return TEST_CSV_FEED_INT if type == 'feed int'
    return SUMMARY_BY_CONSORTIUM_CSV if type == 'summary by consortium'
    return SUMMARY_BY_CONSORTIUM_CSV if type == 'summary by consortium priority'
    return SUMMARY_BY_CONSORTIUM_CSV if type == 'summary mgp'
    return SUMMARY_BY_CONSORTIUM_CSV if type == 'komp2 brief'
    return SUMMARY_BY_CONSORTIUM_CSV if type == 'komp2'
    return nil
  end

  def self.de_tag_table(table)
    report = Table(:data => table.data,
      :column_names => table.column_names,
      :transforms => lambda {|r|
        table.column_names.each do |name|
          r[name] = r[name].to_s.gsub(/<\/?[^>]*>/, "")
        end
      }
    )
    return report
  end
  
end
