
require 'test_helper'

class NotificationsControllerTest < ActionController::TestCase

  context 'NotificationsController' do
    setup do
      Factory.create(:email_template_without_status)
      centre = Centre.find_by_name!('WTSI')
      remote_user = Factory.create :user, {:email => 'vvi@sanger.ac.uk', :password => 'password', :production_centre => centre}
      sign_in remote_user
    end

    context 'POST create' do

      should 'work without immediate' do

        ActionMailer::Base.deliveries = []

        gene = Factory.create(:gene_cbx1)
        contact = Factory.create(:contact)

        assert_difference('Notification.count') do
          post(:create, :gene => {:mgi_accession_id => gene.mgi_accession_id}, :contact =>{:email => contact.email }, :format => :json)

          assert response && response.body, "Invalid response from call!"

          body = response.body && response.body.length >= 2 ? JSON.parse(response.body) : nil

          assert body && body["success"] == true
        end

        assert Notification.all.size > 0, "Cannot find expected notification!"
        assert ActionMailer::Base.deliveries.size == 0, "Found unexpected ActionMailer delivery!"

        notification = Notification.last
        assert_equal notification.gene, gene
        assert_equal notification.contact, contact
      end

      should 'work with immediate' do

        gene = Factory.create(:gene_cbx1)
        contact = Factory.create(:contact)

        assert_difference('Notification.count') do
          post(:create, :gene => {:mgi_accession_id => gene.mgi_accession_id}, :contact =>{:email => contact.email, :immediate => true }, :format => :json)

          assert response && response.body, "Invalid response from call!"

          body = response.body && response.body.length >= 2 ? JSON.parse(response.body) : nil

          assert body && body["success"] == true
        end

        assert Notification.all.size > 0, "Cannot find expected notification!"
        assert ActionMailer::Base.deliveries.size > 0, "Cannot find expected ActionMailer delivery!"

        notification = Notification.last
        assert_equal notification.gene, gene
        assert_equal notification.contact, contact
        assert_equal ActionMailer::Base.deliveries.last.to.first, contact.email
      end

      should 'create a new contact without immediate' do

        ActionMailer::Base.deliveries = []

        gene = Factory.create(:gene_cbx1)

        assert_difference('Notification.count') do
          post(:create, :gene => {:mgi_accession_id => gene.mgi_accession_id}, :contact =>{:email => 'newuser@example.com'}, :format => :json)

          assert response && response.body, "Invalid response from call!"

          body = response.body && response.body.length >= 2 ? JSON.parse(response.body) : nil

          assert body && body["success"] == true
        end

      end

      should 'create a new contact with immediate' do

        gene = Factory.create(:gene_cbx1)

        assert_difference('Notification.count') do
          post(:create, :gene => {:mgi_accession_id => gene.mgi_accession_id}, :contact =>{:email => 'newuser@example.com', :immediate => true }, :format => :json)

          assert response && response.body, "Invalid response from call!"

          body = response.body && response.body.length >= 2 ? JSON.parse(response.body) : nil

          assert body && body["success"] == true
        end

      end
    end

    context 'DELETE delete' do
      should 'work' do

        gene = Factory.create(:gene_cbx1)
        contact = Factory.create(:contact)

        notification = Factory.create :notification, {:gene => gene, :contact => contact}
        assert_difference('Notification.count', -1) do
          delete(:destroy, :gene => {:mgi_accession_id => gene.mgi_accession_id}, :contact =>{:email => contact.email}, :format => :json)
        end
      end
    end

  end

end
