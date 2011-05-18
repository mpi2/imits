require 'test_helper'

class Kermits2::MigrationTest < ActiveSupport::TestCase

  context 'Kermits2::Migration' do
    should 'work from the script' do
      flunk
    end

    should 'migrate across centres' do
      Centre.destroy_all
      Kermits2::Migration.run

      centre_names = Centre.all.collect(&:name)
      assert_include centre_names, 'ICS'
      assert_include centre_names, 'WTSI'
      assert_include centre_names, 'Monterotondo'
    end

  end
end
