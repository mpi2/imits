require 'test_helper'

class ReportsControllerTest < ActionController::TestCase
  context 'The reports controller' do
    should 'require authentication' do
      get :index
      assert_false response.success?
      assert_redirected_to new_user_session_path
    end
    
    context 'when authorised' do
      setup do
        create_common_test_objects
        sign_in default_user
      end
      
      [:microinjection_list, :production_summary, :gene_summary].each do |report|
        context "the /#{report} report" do
          should 'be blank without parameters' do
            get report
            assert response.success?
            assert_nil assigns(:report)
          end

          should 'generate a full report with parameters' do
            get report, 'commit' => 'Go'
            assert response.success?
            assert assigns(:report)
            assert assigns(:report).is_a?( Ruport::Data::Table ) || assigns(:report).is_a?( Ruport::Data::Grouping )
          end
        end
      end
    end
  end
end
