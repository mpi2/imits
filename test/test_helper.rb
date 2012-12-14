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
require 'test/unit'
require 'shoulda'
require 'mocha'

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
  include SolrUpdate::TestHelp

  self.use_transactional_fixtures = false

  def database_strategy; :transaction; end

  def setup
    DatabaseCleaner.strategy = self.database_strategy
    DatabaseCleaner.start
    Test::Person.destroy_all
  end

  def teardown
    DatabaseCleaner.clean
  end

  def create_common_test_objects
    Factory.create(:es_cell_EPD0127_4_E01, :allele => Factory.create(:allele_with_gene_trafd1))
    Factory.create(:es_cell_EPD0343_1_H06, :allele => Factory.create(:allele_with_gene_myolc))
    Factory.create(:es_cell_EPD0029_1_G04, :allele => Factory.create(:allele_with_gene_gatc))
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
    mi_attempt.total_male_chimeras = 1

    if mi_attempt.production_centre.try(:name) == 'WTSI'
      mi_attempt.is_released_from_genotyping = true
    else
      if mi_attempt.number_of_het_offspring.to_i == 0
        mi_attempt.number_of_het_offspring = 5
      end
    end

    mi_attempt.save!
  end

  def unset_mi_attempt_genotype_confirmed(mi_attempt)
    raise 'MiAttempt must be in state Genotype confirmed' unless mi_attempt.has_status? :gtc.status
    if mi_attempt.production_centre.try(:name) == 'WTSI'
      mi_attempt.update_attributes!(:is_released_from_genotyping => false)
    else
      mi_attempt.update_attributes!(
        :number_of_het_offspring => 0,
        :number_of_chimeras_with_glt_from_genotyping => 0
      )
    end
  end

  def replace_status_stamps(obj, stamps)
    status_class = (obj.class.name + '::' + obj.class.reflections[:status].class_name).constantize

    stamps.each do |status_name, time|
      status_object = status_class.find_by_name(status_name)
      if ! status_object
        status_object = status_class.find_by_code(status_name)
        if ! status_object
          raise "#{status_name} status not found"
        end
      end
      raise "Status lookup failed for '#{status_name}'" unless status_object

      status_stamp = obj.status_stamps.find_by_status_id(status_object.id)
      raise "Cannot find status stamp for '#{status_name}'" unless status_stamp

      status_stamp.update_attributes!(:created_at => time)
    end
    obj.status_stamps.reload
  end

  def cbx1; @cbx1 ||= Factory.create(:gene_cbx1); end

  def bash_wtsi_cbx1_plan(more = {})
    @bash_wtsi_cbx1_plan ||= TestDummy.mi_plan('BaSH', 'WTSI', {:gene => cbx1}.merge(more))
  end

  fixtures :all

end

require 'capybara/rails'
require 'capybara/dsl'

Capybara.default_driver = :rack_test
Capybara.default_wait_time = 10

if ! ENV['CHROMIUM'].blank?
  require 'selenium-webdriver'

  if ENV['CHROME_DRIVER_PATH']
    Selenium::WebDriver::Chrome.driver_path = ENV['CHROME_DRIVER_PATH']
  end

  Selenium::WebDriver::Chrome.path = ENV['CHROME_PATH'] || "/usr/bin/chromium-browser"

  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(app, :browser => :chrome, :switches => ['--disable-translate', '--disable-smooth-scrolling', '--window-size=3000,1000', '--window-position=0,0'])
  end
end

class Kermits2::IntegrationTest < ActionDispatch::IntegrationTest
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
    visit '/users/logout'
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

class Kermits2::JsIntegrationTest < Kermits2::IntegrationTest
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

  def choose_es_cell_from_list(marker_symbol = 'Auto-generated Symbol', es_cell_name = 'EPD_1')
    assert page.has_css?('[name=marker_symbol-search-box]')
    fill_in 'marker_symbol-search-box', :with => marker_symbol
    find(:xpath, '//button/span[text()="Search"]').click
    wait_until_grid_loaded
    assert page.has_css?('.x-grid-row')
    find(:xpath, '//td/div[text()="' + es_cell_name + '"]').click
    assert page.find('.x-window', :visible => false)
  end

  def make_form_element_usable(element_name)
    page.execute_script("Ext.get(Ext.select('input[name=\"#{element_name}\"]').first().id).dom.readOnly = false;")
  end

  def screenshot(filename = nil)
    filename ||= "#{Rails.root}/tmp/capybara_screenshot_#{Time.now.strftime('%F-%T')}.png"
    page.driver.render filename
    Launchy.open(filename)
  end

  def wait_until_grid_loaded
    assert page.has_css?('.x-grid', :visible => true)
    wait_until_no_mask
  end

  def wait_until_no_mask
    tries = 0
    begin
      tries += 1
      assert page.has_no_css?('.x-mask', :visible => true)
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      if tries == 3
        raise
      else
        retry
      end
    end
  end

  def choose_date_from_datepicker_for_input(input_name)
    page.find("div[data-name-of-replaced=\"#{input_name}\"] div.x-form-date-trigger").click
    page.find('.x-datepicker .x-datepicker-date', :visible => true).click
  end
end

class ActionController::TestCase
  include Devise::TestHelpers

  def parse_xml_from_response
    return Nokogiri::XML(response.body)
  end
end

class Kermits2::ExternalScriptTestCase < ActiveSupport::TestCase
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

    assert_blank error_output, "Script has output to STDERR:\n#{error_output}"
    assert_equal 0, exit_status, "Script exited with error code #{exit_status}"
    return output
  end
end

class Test::Person < ApplicationModel

  class Status < ApplicationModel
    include StatusInterface

    self.connection.create_table :test_person_statuses, :temporary => true do |t|
      t.string :name, :null => false
      t.string :code, :null => false
    end
    set_table_name :test_person_statuses

    has_many :test_people, :dependent => :destroy

    ALIVE = self.create!(:name => 'Alive', :code => 'alive')
    DEAD = self.create!(:name => 'Dead', :code => 'dead')
    BURIED = self.create!(:name => 'Buried', :code => 'buried')
  end

  class StatusStamp < ApplicationModel
    self.connection.create_table :test_person_status_stamps, :temporary => true do |t|
      t.integer :status_id, :null => false
      t.integer :person_id, :null => false
    end
    set_table_name :test_person_status_stamps

    belongs_to :status
  end

  include HasStatuses

  acts_as_audited

  self.connection.create_table :test_people, :temporary => true do |t|
    t.string :name
    t.integer :status_id
  end
  self.connection.add_foreign_key :test_people, :test_person_statuses, :column => :status_id
  set_table_name :test_people

  has_many :status_stamps
  belongs_to :status

  validates :name, :uniqueness => true
end
