require 'test_helper'

class ColonyTest < ActiveSupport::TestCase
  context 'Colony' do
    should validate_presence_of :name

    should belong_to :mi_attempt

    should have_db_column(:name).of_type(:string)
    should have_db_column(:mi_attempt_id).of_type(:integer)
    should have_db_column(:trace_file_file_name).of_type(:string)
    should have_db_column(:trace_file_content_type).of_type(:string)
    should have_db_column(:trace_file_file_size).of_type(:integer)
    should have_db_column(:trace_file_updated_at).of_type(:datetime)
    should have_db_column(:genotype_confirmed).of_type(:boolean)
  end
end
