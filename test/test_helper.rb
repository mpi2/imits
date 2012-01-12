unless ENV['COVERAGE'].to_s.empty?
  require 'simplecov'
  SimpleCov.start 'rails'
end

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'database_cleaner'
require 'shoulda'
require 'factory_girl_rails'
require 'open3'

unless ENV['COVERAGE'].to_s.empty?
  require 'simplecov-rcov'
  class SimpleCov::Formatter::MergedFormatter
    def format(result)
      SimpleCov::Formatter::HTMLFormatter.new.format(result)
      SimpleCov::Formatter::RcovFormatter.new.format(result)
    end
  end
  SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
end

class ActiveRecord::Base
  def <=>(other)
    self.id <=> other.id
  end
end

class ActiveSupport::TestCase
  self.use_transactional_fixtures = false

  def database_strategy; :transaction; end

  def setup
    DatabaseCleaner.strategy = self.database_strategy
    DatabaseCleaner.start
    load Rails.root + 'db/seeds.rb'
    Test::Person.destroy_all
  end

  def teardown
    DatabaseCleaner.clean
  end

  def create_common_test_objects
    Factory.create(:es_cell_EPD0127_4_E01)
    Factory.create(:es_cell_EPD0343_1_H06)
    Factory.create(:es_cell_EPD0029_1_G04)
  end

  def default_user
    @default_user ||= Factory.create :user, :email => 'test@example.com', :password => 'password'
  end

  def assert_should(matcher)
    assert_accepts matcher, subject
  end

  def assert_should_not(matcher)
    assert_rejects matcher, subject
  end

  def set_mi_attempt_genotype_confirmed(mi_attempt)
    mi_attempt.is_active = true

    if mi_attempt.production_centre_name == 'WTSI'
      mi_attempt.is_released_from_genotyping = true
    else
      if mi_attempt.number_of_het_offspring.to_i == 0
        mi_attempt.number_of_het_offspring = 5
      end
    end

    mi_attempt.save!
  end

  fixtures :all
end

require 'capybara/rails'
require 'capybara/dsl'

Capybara.default_driver = :rack_test

class ActionDispatch::IntegrationTest < ActiveSupport::TestCase
  include Capybara::DSL

  def database_strategy; :deletion; end

  def teardown
    Capybara.reset_sessions!
    super
  end

  def login(arg = nil)
    if arg.kind_of? User
      email = arg.email
    elsif arg.nil?
      email = default_user.email
    end
    visit '/users/login'
    fill_in 'Email', :with => email
    fill_in 'Password', :with => 'password'
    click_button 'Login'
    assert_not_match(%r{^http://[^/]+/users/login$}, current_url)
  end

  def assert_login_page
    assert_match(%r{^http://[^/]+/users/login$}, current_url)
  end

  def assert_current_link(text)
    assert page.has_css? "#navigation li.current a", :text => text
  end
end

class Kermits2::JsIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    super
    Capybara.current_driver = :selenium
  end

  def teardown
    Capybara.use_default_driver
    super
  end

  def selector_for_table_cell(table_row)
    ".x-grid-body tbody tr:nth-child(#{table_row+1}) .x-grid-cell-inner"
  end

  def choose_es_cell_from_list(marker_symbol = 'Cbx1', es_cell_name = 'EPD0027_2_A01')
    fill_in 'marker_symbol-search-box', :with => marker_symbol
    find(:xpath, '//button/span[text()="Search"]').click
    sleep 5
    find(:xpath, '//td/div[text()="' + es_cell_name + '"]').click
  end
  
  def make_form_element_usable(element_name)
    page.execute_script("Ext.get(Ext.select('input[name=\"#{element_name}\"]').first().id).dom.readOnly = false;")
  end

  def screenshot(filename = nil)
    filename ||= "#{Rails.root}/tmp/capybara_screenshot_#{Time.now.strftime('%F-%T')}.png"
    page.driver.render filename
    Launchy.open(filename)
  end
end

class ActionController::TestCase
  include Devise::TestHelpers

  def parse_xml_from_response
    return Nokogiri::XML(response.body)
  end

  def parse_json_from_response
    return JSON.parse(response.body)
  end
end

class Kermits2::StrainsTestCase < ActiveSupport::TestCase
  def self.strain_tests_for(strains_class)
    table_name = strains_class.name.demodulize.tableize

    context strains_class.name do
      should have_db_column(:id).with_options(:null => false)
      should have_db_index(:id).unique(true)
      should belong_to :strain

      should 'be populated with correct data' do
        names = strains_class.joins(:strain).order(:id).map {|i| i.strain.name}
        assert_equal names.sort, File.read(Rails.root + "config/strains/#{table_name}.txt").split("\n").sort
      end

      should 'delegate #name to Strain' do
        sid = strains_class.find(:first)
        assert_equal sid.name, sid.strain.name
      end

      context '::find_by_name' do
        should 'find the row with given strain name' do
          strains_object = strains_class.first
          strain_name = Strain.find(strains_object.id).name
          assert_equal strains_object, strains_class.find_by_name(strain_name)
        end

        should 'return nil if said strain does not exist' do
          assert_nil strains_class.find_by_name('Nonexistent')
        end

        should 'return nil if said strain is not of the right type' do
          Strain.create!(:name => 'Not of any type')
          assert_nil strains_class.find_by_name('Not of any type')
        end
      end

      context '::find_by_name!' do
        should 'find the row with given strain name' do
          strains_object = strains_class.first
          strain_name = Strain.find(strains_object.id).name
          assert_equal strains_object, strains_class.find_by_name!(strain_name)
        end

        should 'raise if said name does not exist' do
          assert_raise(ActiveRecord::RecordNotFound) do
            strains_class.find_by_name!('Nonexistent')
          end
        end
      end

    end

  end

end

class ExternalScriptTestCase < ActiveSupport::TestCase
  def database_strategy; :deletion; end

  def run_script(commands)
    error_output = nil
    exit_status = nil
    output = nil
    Open3.popen3("cd #{Rails.root}; #{commands}") do |scriptin, scriptout, scripterr, wait_thr|
      error_output = scripterr.read
      exit_status = wait_thr.value.exitstatus
      output = scriptout.read
    end

    sleep 3

    assert_blank error_output, "Script has output to STDERR:\n#{error_output}"
    assert_equal 0, exit_status, "Script exited with error code #{exit_status}"
    return output
  end
end

class Test::Person < ActiveRecord::Base
  self.connection.create_table :test_people, :force => true do |t|
    t.string :name
  end
  set_table_name :test_people

  validates :name, :uniqueness => true
end

class ProductionSummaryBase < 
    #Kermits2::JsIntegrationTest
  ActionDispatch::IntegrationTest
end

class ProductionSummaryHelper

  DEBUG = false

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

  HEADING = '"Consortium","Sub-Project","Priority","Production Centre","Gene","MGI Accession ID","Overall Status","MiPlan Status","MiAttempt Status","PhenotypeAttempt Status","IKMC Project ID","Mutation Sub-Type","Allele Symbol","Genetic Background","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date","Phenotype Attempt Registered Date","Rederivation Started Date","Rederivation Complete Date","Cre Excision Started Date","Cre Excision Complete Date","Phenotyping Started Date","Phenotyping Complete Date","Phenotype Attempt Aborted Date"'
  ES_QC_STARTED  = '"BaSH",,"High","BCM","1700093J21Rik","MGI:1921546","Assigned - ES Cell QC In Progress","Assigned - ES Cell QC In Progress",,,,,,,"2011-10-10","2011-11-16",,,,,,,,,,,,'
  ES_QC_CONFIRMED  = '"BaSH",,"High","BCM","Adsl","MGI:103202","Assigned - ES Cell QC Complete","Assigned - ES Cell QC Complete",,,,,,,"2011-10-10","2011-11-04","2011-11-25"'
  ES_QC_FAILED = '"BaSH",,"High","BCM","Clvs2","MGI:2443223","Aborted - ES Cell QC Failed","Aborted - ES Cell QC Failed",,,,,,,"2011-10-10"'
  MI_IN_PROGRESS = '"BaSH",,"High","BCM","Akt1s1","MGI:1914855","Micro-injection in progress","Assigned","Micro-injection in progress",,28913,"conditional_ready","Akt1s1<sup>tm1a(EUCOMM)Wtsi</sup>","C57BL/6N","2011-10-10",,,"2011-09-27",,,,,,,,,,'
  MI_ABORTED = '"BaSH",,"High","BCM","Apc2","MGI:1346052","Micro-injection aborted","Assigned","Micro-injection aborted",,26234,"conditional_ready","Apc2<sup>tm1a(KOMP)Wtsi</sup>",,"2011-12-01",,,"2011-09-05",,"2011-12-02"'
  GENOTYPE_CONFIRMED_MICE = '"BaSH",,"High","BCM","Alg10b","MGI:2146159","Genotype confirmed","Assigned","Genotype confirmed",,"VG10825","deletion","Alg10b<sup>tm1(KOMP)Vlcg</sup>","C57BL/6N","2011-10-10",,,"2011-09-08","2012-01-07",,,,,,,,,'
  LANGUISHING = '"BaSH",,"High","BCM","Akt1s1","MGI:1914855","Micro-injection in progress","Assigned","Micro-injection in progress",,28913,"conditional_ready","Akt1s1<sup>tm1a(EUCOMM)Wtsi</sup>","C57BL/6N","2011-10-10",,,"2009-09-27"'
  
  SUMMARY_BY_CONSORTIUM_CSV = [
      HEADING,
      ES_QC_STARTED,
      ES_QC_CONFIRMED,
      ES_QC_FAILED,
      MI_IN_PROGRESS,
      MI_ABORTED,
      GENOTYPE_CONFIRMED_MICE,
      LANGUISHING
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
