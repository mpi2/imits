require 'test_helper'

class ReportsControllerTest < ActionController::TestCase
  context 'ReportsController' do

    should 'require authentication' do
      get :index
      assert !response.success?
      assert_redirected_to new_user_session_path
    end

    context 'when authorised' do
      setup do
        create_common_test_objects
        5.times { Factory.create :mi_plan, :consortium_id => Consortium.find_by_name!('DTCC').id }
        10.times { Factory.create :mi_attempt2 }

        sign_in default_user
      end

      [:mi_attempts_list, :mi_attempts_monthly_production, :mi_attempts_by_gene].each do |report|
        context "the /#{report} report" do
          should 'be blank without parameters' do
            get report
            assert response.success?
            assert_nil assigns(:report)
          end

          should 'generate a full report with parameters' do
            get report, 'commit' => 'true'
            assert response.success?
            assert assigns(:report), "/#{report} has not assigned @report"
            assert assigns(:report).is_a?( Ruport::Data::Table ) || assigns(:report).is_a?( Ruport::Data::Grouping )
          end
        end
      end

      [:planned_microinjection_list].each do |report|
        context "the /#{report} report" do
          should 'be blank without parameters' do
            get report
            assert response.success?
            assert_nil assigns(:report)
          end

          should 'generate a full report with parameters' do
            get report, 'commit' => 'true'
            assert response.success?
          end
        end
      end
  end
end
