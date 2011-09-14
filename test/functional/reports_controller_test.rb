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

      [:microinjection_list, :production_summary, :gene_summary, :planned_microinjection_list].each do |report|
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

      context 'the /planned_microinjection_summary_and_conflicts report' do
        should 'just work (tm)' do
          15.times { Factory.create :mi_plan, :consortium_id => Consortium.find_by_name!('DTCC').id }
          20.times { Factory.create :mi_attempt }

          get :planned_microinjection_summary_and_conflicts
          assert response.success?
          assert_nil assigns(:summary_by_status)

          get :planned_microinjection_summary_and_conflicts, 'commit' => 'Go'
          assert response.success?

          [
            :summary_by_status_and_priority,
            :declined_report
          ].each do |report|
            assert assigns(report), "@#{report} has not been assigned"
            assert assigns(report).is_a?( Ruport::Data::Grouping ), "@#{report} is not a Ruport::Data::Grouping object"
          end

          [
            :summary_by_status,
            :summary_by_priority,
            :conflict_report
          ].each do |report|
            assert assigns(report), "@#{report} has not been assigned"
            assert assigns(report).is_a?( Ruport::Data::Table ), "@#{report} is not a Ruport::Data::Table object"
          end
        end
      end
    end
  end
end
