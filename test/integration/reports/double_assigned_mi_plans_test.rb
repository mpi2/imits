# encoding: utf-8

require 'test_helper'

class DoubleAssignedMiPlansTest < Kermits2::JsIntegrationTest #ActionDispatch::IntegrationTest
  
  #
  
    VERBOSE = true
    
  context 'The reports pages' do

    should 'require the user to be logged in' do
      visit '/reports'
      assert_login_page
    end

    context 'once logged in' do
      setup do
        create_common_test_objects
        visit '/users/logout'
        login
      end
    
      should 'allow users to visit the reports "home" page' do
        visit '/reports'
        assert_match reports_path, current_url
      end
    
      should 'allow users to visit the double-assignment matrix page' do
        visit '/reports/double_assigned_mi_plans_matrix'
        assert_match '/reports/double_assigned_mi_plans_matrix', current_url
      end
    
      should 'allow users to visit the double-assignment list page' do
        visit '/reports/double_assigned_mi_plans_list'
        assert_match '/reports/double_assigned_mi_plans_list', current_url
      end

      should 'allow users to visit the double-assignment matrix page by clicking' do
        visit '/reports'
        click_link 'Double-Assigned MI Plans Matrix'
        assert_match '/reports/double_assigned_mi_plans_matrix', current_url
      end
    
      should 'allow users to visit the double-assignment list page by clicking' do
        visit '/reports'
        click_link 'Double-Assigned MI Plans List'
        assert_match '/reports/double_assigned_mi_plans_list', current_url
      end  
    
    
      should 'allow users to visit the double-assignment list page & see entries' do

        gene_cbx1 = Factory.create :gene_cbx1
        
        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']
        
        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('JAX'),
          :production_centre => Centre.find_by_name('JAX'),
          :number_of_es_cells_starting_qc => 5
        
        puts Gene.all.inspect if VERBOSE

        visit '/reports/double_assigned_mi_plans_list'
        assert_match '/reports/double_assigned_mi_plans_list', current_url
                
        assert_match 'DOUBLE-ASSIGNMENTS FOR consortium: BaSH', page.body
        assert_match 'DOUBLE-ASSIGNMENTS FOR consortium: JAX', page.body

        assert_match(/<th>Marker Symbol<\/th>\s+<th>Consortium<\/th>\s+<th>Plan Status<\/th>\s+<th>MI Status<\/th>\s+<th>Centre<\/th>\s+<th>MI Date<\/th>/, page.body)

        assert_match(/<td>Cbx1<\/td>\s+<td>BaSH<\/td>\s+<td>Assigned<\/td>\s+<td> <\/td>\s+<td>WTSI<\/td>\s+<td> <\/td>/, page.body)

        assert_match(/<td>Cbx1<\/td>\s+<td>JAX<\/td>\s+<td>Assigned - ES Cell QC In Progress<\/td>\s+<td> <\/td>\s+<td>JAX<\/td>\s+<td> <\/td>/, page.body)

        assert_match(/<td>Cbx1<\/td>\s+<td>BaSH<\/td>\s+<td>Assigned<\/td>\s+<td> <\/td>\s+<td>WTSI<\/td>\s+<td> <\/td>/, page.body)

        assert_match(/<td>Cbx1<\/td>\s+<td>JAX<\/td>\s+<td>Assigned - ES Cell QC In Progress<\/td>\s+<td> <\/td>\s+<td>JAX<\/td>\s+<td> <\/td>/, page.body)

        puts page.body.to_s if VERBOSE
                
      end
    
      should 'allow users to visit the double-assignment matrix page & see entries' do

        gene_cbx1 = Factory.create :gene_cbx1
        
        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']
        
        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('JAX'),
          :production_centre => Centre.find_by_name('JAX'),
          :number_of_es_cells_starting_qc => 5
        
        puts Gene.all.inspect if VERBOSE

        visit '/reports/double_assigned_mi_plans_matrix'
        assert_match '/reports/double_assigned_mi_plans_matrix', current_url
                
        puts page.body.to_s if VERBOSE

        assert_match(/<th><\/th>\s+<th>KOMP2 - BaSH<\/th>\s+<th>KOMP2 - DTCC<\/th>\s+<th>KOMP - JAX<\/th>\s+<th>EUCOMM \/ EUMODIC - Helmholtz GMC<\/th>\s+<th>Infrafrontier\/BMBF - MARC<\/th>\s+<th>KOMP2 - MGP<\/th>\s+<th>China - Monterotondo<\/th>\s+<th>Wellcome Trust - MRC<\/th>\s+<th>KOMP \/ Wellcome Trust - NorCOMM2<\/th>\s+<th>European Union - Phenomin<\/th>\s+<th>MRC - RIKEN BRC<\/th>\s+<th>Genome Canada - DTCC-KOMP<\/th>\s+<th>Phenomin - EUCOMM-EUMODIC<\/th>\s+<th>Japanese government - MGP-KOMP<\/th>/, page.body)

        assert_match(/<td>KOMP2 - BaSH<\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td>1<\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>/, page.body)

        #assert_match(/<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>1<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>/, page.body)

        columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
        assert columns && columns.size > 0, "Could not get columns"

        #columns.each do |column|
        #  next if column == 'KOMP2 - BaSH'
        #  regex = "<td>#{columns}<\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>".to_regexp
        #  assert_match(regex, page.body)
        #end
        
       # puts "Sleeping..."
       # sleep(20.seconds)
       
       #TODO: assert page.has_content?
       
       #TODO: row_headers = all('.row-header').map { |i| i.text }

      end
    
      should 'allow users to visit the double-assignment matrix page & download CSV' 
    
      should 'allow users to visit the double-assignment list page & download CSV' 
    
    #  should 'allow users to get reports of all MIs in the system' do
    #    visit '/reports'
    #    click_link 'All Micro-Injection Attempts'
    #
    #    assert_match '/reports/mi_attempts_list', current_url
    #    assert page.has_css?('form')
    #    assert page.has_css?('form select#grouping')
    #
    #    select 'WTSI', :from => 'production_centre_id[]'
    #    click_button 'Generate Report'
    #
    #    assert_match '/reports/mi_attempts_list', current_url
    #    assert_match 'production_centre_id', current_url
    #    assert page.has_css?('.report table')
    #
    #    choose 'format_csv'
    #    click_button 'Generate Report'
    #  end
    #
    #  should 'allow users to get production summary reports' do
    #    visit '/reports'
    #    click_link 'Month-by-Month Summary'
    #
    #    assert_match '/reports/mi_attempts_monthly_production', current_url
    #    assert page.has_css?('form')
    #    assert_false page.has_css?('form select#grouping')
    #
    #    select 'WTSI', :from => 'production_centre_id[]'
    #    click_button 'Generate Report'
    #
    #    assert_match '/reports/mi_attempts_monthly_production', current_url
    #    assert_match 'production_centre_id', current_url
    #    assert page.has_css?('.report table')
    #
    #    choose 'format_csv'
    #    click_button 'Generate Report'
    #  end
    #
    #  should 'allow users to get gene summary reports' do
    #    visit '/reports'
    #    click_link 'Gene Summary'
    #
    #    assert_match '/reports/mi_attempts_by_gene', current_url
    #    assert page.has_css?('form')
    #    assert_false page.has_css?('form select#grouping')
    #
    #    select 'WTSI', :from => 'production_centre_id[]'
    #    click_button 'Generate Report'
    #
    #    assert_match '/reports/mi_attempts_by_gene', current_url
    #    assert_match 'production_centre_id', current_url
    #    assert page.has_css?('.report table')
    #
    #    choose 'format_csv'
    #    click_button 'Generate Report'
    #  end
    #
    #  should 'allow users to get planned_microinjection_summary_and_conflicts reports' do
    #    15.times { Factory.create :mi_plan, :consortium_id => Consortium.find_by_name!('DTCC').id }
    #    20.times { Factory.create :mi_attempt }
    #
    #    visit '/reports'
    #    click_link 'Planned Micro-Injection Summary and Conflicts'
    #
    #    assert_match '/reports/planned_microinjection_summary_and_conflicts', current_url
    #    assert page.has_css?('form')
    #    assert_false page.has_css?('form select#grouping')
    #
    #    click_button 'Generate Report'
    #    assert_match '/reports/planned_microinjection_summary_and_conflicts', current_url
    #    assert page.has_css?('.report table')
    #
    #    select 'yes', :from => 'include_plans_with_active_attempts'
    #    click_button 'Generate Report'
    #    assert_match '/reports/planned_microinjection_summary_and_conflicts', current_url
    #    assert page.has_css?('.report table')
    #
    #    choose 'format_csv'
    #    click_button 'Generate Report'
    #  end
    #
    #  should 'allow users to get reports of all mi_plans in the system' do
    #    15.times { Factory.create :mi_plan, :consortium_id => Consortium.find_by_name!('DTCC').id }
    #    20.times { Factory.create :mi_attempt }
    #
    #    visit '/reports'
    #    click_link 'All Planned Micro-Injections'
    #
    #    assert_match '/reports/planned_microinjection_list', current_url
    #    assert page.has_css?('form')
    #    assert page.has_css?('form select#grouping')
    #
    #    click_button 'Generate Report'
    #    assert_match '/reports/planned_microinjection_list', current_url
    #    assert page.has_css?('.report table')
    #
    #    select 'yes', :from => 'include_plans_with_active_attempts'
    #    click_button 'Generate Report'
    #    assert_match '/reports/planned_microinjection_list', current_url
    #    assert page.has_css?('.report table')
    #
    #    choose 'format_csv'
    #    click_button 'Generate Report'
    #  end
    #
    #  should 'not blow up in the users face if they ask for silly data' do
    #    visit '/reports'
    #    click_link 'All Micro-Injection Attempts'
    #
    #    select 'JAX', :from => 'production_centre_id[]'
    #    select 'MARC', :from => 'consortium_id[]'
    #    click_button 'Generate Report'
    #
    #    assert_match '/reports/mi_attempts_list', current_url
    #    assert_match 'production_centre_id', current_url
    #    assert_match 'Sorry', page.body
    #
    #    visit '/reports'
    #    click_link 'Month-by-Month Summary'
    #
    #    select 'JAX', :from => 'production_centre_id[]'
    #    select 'MARC', :from => 'consortium_id[]'
    #    click_button 'Generate Report'
    #
    #    assert_match '/reports/mi_attempts_monthly_production', current_url
    #    assert_match 'production_centre_id', current_url
    #    assert_match 'Sorry', page.body
    #
    #    visit '/reports'
    #    click_link 'Gene Summary'
    #
    #    select 'JAX', :from => 'production_centre_id[]'
    #    select 'MARC', :from => 'consortium_id[]'
    #    click_button 'Generate Report'
    #
    #    assert_match '/reports/mi_attempts_by_gene', current_url
    #    assert_match 'production_centre_id', current_url
    #    assert_match 'Sorry', page.body
    #
    #    15.times { Factory.create :mi_plan, :consortium_id => Consortium.find_by_name!('DTCC').id }
    #    20.times { Factory.create :mi_attempt }
    #
    #    visit '/reports'
    #    click_link 'All Planned Micro-Injections'
    #
    #    select 'JAX', :from => 'production_centre_id[]'
    #    select 'MARC', :from => 'consortium_id[]'
    #    click_button 'Generate Report'
    #
    #    assert_match '/reports/planned_microinjection_list', current_url
    #    assert_match 'production_centre_id', current_url
    #    assert_match 'Sorry', page.body
    #  end
    
    end
    
  end
end
