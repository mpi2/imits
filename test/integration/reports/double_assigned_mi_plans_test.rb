# encoding: utf-8

require 'test_helper'

class DoubleAssignedMiPlansTest < ActionDispatch::IntegrationTest
  
  #Kermits2::JsIntegrationTest #
  
  VERBOSE = false
    
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

        #assert_match(/<th>Marker Symbol<\/th>\s+<th>Consortium<\/th>\s+<th>Plan Status<\/th>\s+<th>MI Status<\/th>\s+<th>Centre<\/th>\s+<th>MI Date<\/th>/, page.body)
        #assert_match(/<td>Cbx1<\/td>\s+<td>BaSH<\/td>\s+<td>Assigned<\/td>\s+<td> <\/td>\s+<td>WTSI<\/td>\s+<td> <\/td>/, page.body)
        #assert_match(/<td>Cbx1<\/td>\s+<td>JAX<\/td>\s+<td>Assigned - ES Cell QC In Progress<\/td>\s+<td> <\/td>\s+<td>JAX<\/td>\s+<td> <\/td>/, page.body)
        #assert_match(/<td>Cbx1<\/td>\s+<td>BaSH<\/td>\s+<td>Assigned<\/td>\s+<td> <\/td>\s+<td>WTSI<\/td>\s+<td> <\/td>/, page.body)
        #assert_match(/<td>Cbx1<\/td>\s+<td>JAX<\/td>\s+<td>Assigned - ES Cell QC In Progress<\/td>\s+<td> <\/td>\s+<td>JAX<\/td>\s+<td> <\/td>/, page.body)

       # sleep 10

        assert page.has_content? "Marker Symbol Consortium Plan Status MI Status Centre MI Date"
        assert page.has_content? "Cbx1 BaSH Assigned"
#        assert page.has_content? "Cbx1 BaSH Assigned WTSI"
#        assert page.has_content? "Cbx1 JAX Assigned - ES Cell QC In Progress JAX"
#        assert page.has_content? "Cbx1 JAX Assigned - ES Cell QC In Progress"




        puts page.body.to_s if VERBOSE
#        puts page.has_content.to_s if VERBOSE
        
#        sleep 20

        assert page.has_content? 'Download as CSV'
                
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

      #    assert_match(/<th><\/th>\s+<th>KOMP2 - BaSH<\/th>\s+<th>KOMP2 - DTCC<\/th>\s+<th>KOMP - JAX<\/th>\s+<th>EUCOMM \/ EUMODIC - Helmholtz GMC<\/th>\s+<th>Infrafrontier\/BMBF - MARC<\/th>\s+<th>KOMP2 - MGP<\/th>\s+<th>China - Monterotondo<\/th>\s+<th>Wellcome Trust - MRC<\/th>\s+<th>KOMP \/ Wellcome Trust - NorCOMM2<\/th>\s+<th>European Union - Phenomin<\/th>\s+<th>MRC - RIKEN BRC<\/th>\s+<th>Genome Canada - DTCC-KOMP<\/th>\s+<th>Phenomin - EUCOMM-EUMODIC<\/th>\s+<th>Japanese government - MGP-KOMP<\/th>/, page.body)
      #    assert_match(/<td>KOMP2 - BaSH<\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td>1<\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>/, page.body)

        #assert_match(/<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>1<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>\s+<td>&#160;<\/td>/, page.body)

        columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
        assert columns && columns.size > 0, "Could not get columns"

        #columns.each do |column|
        #  next if column == 'KOMP2 - BaSH'
        #  regex = "<td>#{columns}<\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>\s+<td> <\/td>".to_regexp
        #  assert_match(regex, page.body)
        #end
        
        size = all('tr').size
        puts "SIZE: #{size}" if VERBOSE
        
        assert_equal 15, all('tr').size
        
        puts all('tr').map { |i| i.to_s } if VERBOSE
       
        trs = all('tr')
        tds = trs[1].all('td')
        puts "SIZE 2: #{tds.size}" if VERBOSE
        
        puts "TDS: #{tds.inspect}" if VERBOSE
        puts "TD: #{tds[3].inspect}" if VERBOSE

        #puts "Sleeping..."
        #sleep(20)

        assert_equal "1", tds[3].text
   
        #assert page.has_content? 'KOMP2 - BaSH KOMP2 - DTCC KOMP - JAX EUCOMM / EUMODIC - Helmholtz GMC Infrafrontier/BMBF - MARC KOMP2 - MGP China - Monterotondo Wellcome Trust - MRC KOMP / Wellcome Trust - NorCOMM2 European Union - Phenomin MRC - RIKEN BRC Genome Canada - DTCC-KOMP Phenomin - EUCOMM-EUMODIC Japanese government - MGP-KOMP'
       
       #TODO: row_headers = all('.row-header').map { |i| i.text }

        assert page.has_content? 'Download as CSV'

      end
    
      #should 'allow users to visit the double-assignment matrix page & download CSV' 
      #
      #should 'allow users to visit the double-assignment list page & download CSV' 
    
    end
    
  end
end
