source 'http://rubygems.org'
source 'http://www.i-dcc.org/rubygems'

gem 'rake'
gem 'rails', '~> 3.0.9'
gem 'hoptoad_notifier'
gem 'jammit'

gem 'pg'
gem 'foreigner'

gem 'devise'
gem 'biomart'
gem 'acts_as_audited', '~>2.0.0.rc7'
gem 'ransack', '0.7'

gem 'will_paginate', '~>3.0.pre2'
gem 'acts_as_reportable', :require => 'ruport/acts_as_reportable'

gem 'rmagick', :require => false
gem 'scruffy_Sanger','0.2.6.1', :require => 'scruffy'

gem 'unicorn'

## For TargRep
gem 'dynamic_form'
gem 'bio'

group :development, :test do
  gem 'launchy'
  gem 'awesome_print'
  gem 'annotate'
  gem 'letter_opener'

  gem 'test-unit', :require => nil
  gem 'shoulda', :require => nil
  gem 'mocha', :require => nil
  gem 'database_cleaner', :require => nil
  gem 'factory_girl_rails', :require => nil

  gem 'simplecov', '>= 0.4.0', :require => nil
  gem 'simplecov-rcov',        :require => nil
  gem 'parallel_tests'

  gem 'selenium-webdriver', '2.21', :require => nil
  gem 'chromedriver-helper', :require => nil
  gem 'capybara', :require => nil

  gem 'thin', :require => nil
end

group :migration do
  gem "sequel"
  gem "mysql2"
end