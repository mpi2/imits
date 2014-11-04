require 'test_helper'
require 'pp'

class ApplicationModel::DistributionCentreTest < ActiveSupport::TestCase

    def create_mi_dist_centre( network_name, centre_name, start_date, end_date )
        midc = Factory.create(:mi_attempt_distribution_centre,
            :distribution_network   => network_name,
            :centre                 => Centre.find_by_name!(centre_name),
            :start_date             => start_date,
            :end_date               => end_date
        )
        return midc
    end

    def create_pa_dist_centre( network_name, centre_name, start_date, end_date )
        padc = Factory.create(:phenotype_attempt_distribution_centre,
            :distribution_network   => network_name,
            :centre                 => Centre.find_by_name!(centre_name),
            :start_date             => start_date,
            :end_date               => end_date
        )

        # this save and reload is currently required in order to create the mouse_allele_mod
        padc.phenotype_attempt.save!
        padc.reload

        return padc
    end

    context 'ApplicationModel::DistributionCentre' do

        setup do
            @config ={
              'HMGU'        =>{:preferred=>'www.HMGU.com?query=MARKER_SYMBOL', :default=>'www.HMGU-default.com'},
              'CNB'         =>{:preferred=>'', :default=>''},
              'Monterotondo'=>{:preferred=>'www.Monterotondo.com?query=PROJECT_ID', :default=>'www.Monterotondo-default.com'},
              'JAX'         =>{:preferred=>'', :default=>''},
              'BCM'         =>{:preferred=>'mailto:kompgroup@bcm.edu?subject=Mutant mouse for MARKER_SYMBOL', :default=>'mailto:kompgroup@bcm.edu?subject=Mutant mouse enquiry'},
              'UCD'         =>{:preferred=>'http://www.komp.org/geneinfo.php?project=PROJECT_ID', :default=>'http://www.komp.org/'},
              'EMMA'        =>{:preferred=>'http://www.emmanet.org/mutant_types.php?keyword=MARKER_SYMBOL', :default=>'www.EMMA-default.com'},
              'KOMP'        =>{:preferred=>'http://www.komp.org/geneinfo.php?project=PROJECT_ID', :default=>'http://www.komp.org/'},
              'MMRRC'       =>{:preferred=>'http://www.mmrrc.org/catalog/StrainCatalogSearchForm.php?search_query=MARKER_SYMBOL', :default=>'http://www.mmrrc.org/catalog/StrainCatalogSearchForm.php'},
              'CMMR'        =>{:preferred=>'mailto:Lauryl.Nutter@phenogenomics.ca?subject=Mutant mouse for MARKER_SYMBOL', :default=>'mailto:Lauryl.Nutter@phenogenomics.ca?subject=Mutant mouse'}
            }
        end

        context 'Creation of Mi Attempt Distribution Centre order links' do

            # with network    -> should use config preferred or default, if they are not there error
            # without network -> use the dist centre to look in yaml, otherwise looks at centre email, if both blank error

            context 'Where Mi Attempt distribution network is provided' do

                should 'use the default distribution network config link when neither project id or marker symbol are supplied' do
                    params = { :distribution_network_name => 'CMMR', :distribution_centre_name => 'HMGU', :dc_start_date => '2014-01-01' }
                    assert_equal ['CMMR', 'mailto:Lauryl.Nutter@phenogenomics.ca?subject=Mutant mouse'], ApplicationModel::DistributionCentre.calculate_order_link( params, @config )
                end

                should 'use the preferred distribution network config link when it requires a project id and one is supplied' do
                    midc = create_mi_dist_centre( 'KOMP', 'UCD', '2014-01-01', nil )
                    project_id = midc.try(:mi_attempt).try(:es_cell).try(:ikmc_project_id)
                    assert_false project_id.nil?
                    assert_equal ['KOMP', "http://www.komp.org/geneinfo.php?project=#{project_id}"], midc.calculate_order_link( @config )
                end

                should 'use the preferred distribution network config link when it requires a marker symbol and one is supplied' do
                    midc = create_mi_dist_centre( 'EMMA', 'BCM', '2014-01-01', nil )
                    marker_symbol = midc.try(:mi_attempt).try(:mi_plan).try(:gene).try(:marker_symbol)
                    assert_false marker_symbol.nil?
                    assert_equal ['EMMA', "http://www.emmanet.org/mutant_types.php?keyword=#{marker_symbol}"], midc.calculate_order_link( @config )
                end

                should 'error if neither default nor preferred distribution network config link is supplied' do
                    params = { :distribution_network_name => 'TEST', :distribution_centre_name => 'HMGU', :dc_start_date => '2014-01-01' }
                    exception = assert_raises(RuntimeError) { ApplicationModel::DistributionCentre.calculate_order_link( params, @config ) }
                    assert_equal( "Failed to select a centre with name <HMGU> and a contact email address", exception.message )
                end

                should 'error if neither distribution network or centre is supplied' do
                    params = { :distribution_network_name => nil, :distribution_centre_name => nil, :dc_start_date => '2014-01-01' }
                    exception = assert_raises(RuntimeError) { ApplicationModel::DistributionCentre.calculate_order_link( params, @config ) }
                    assert_equal( "Unrecognised or missing distribution network and unrecognised centre with no contact email address", exception.message )
                end

                should 'error if the current time is outside of the start and end date range' do
                    params = { :distribution_network_name => 'CMMR', :distribution_centre_name => 'HMGU', :dc_start_date => '2014-01-01', :dc_end_date => '2014-02-01' }
                    exception = assert_raises(RuntimeError) { ApplicationModel::DistributionCentre.calculate_order_link( params, @config ) }
                    assert_equal( "Distribution Centre date range not current, cannot create order links", exception.message )
                end

            end

            context 'Where Mi Attempt distribution network is not available' do

                setup do
                    puts "setting centre contact emails"
                    bcm_centre = Centre.find_by_name("BCM")
                    bcm_centre.contact_email = "kompgroup@bcm.edu"
                    bcm_centre.save!

                    jax_centre = Centre.find_by_name("JAX")
                    jax_centre.contact_email = "komp2@jax.org"
                    jax_centre.save!
                end

                should 'use the default distribution centre config link when neither project id or marker symbol are supplied' do
                    params = { :distribution_centre_name => 'BCM', :dc_start_date => '2014-01-01' }
                    assert_equal [ 'BCM', 'mailto:kompgroup@bcm.edu?subject=Mutant mouse enquiry'], ApplicationModel::DistributionCentre.calculate_order_link( params, @config )
                end

                should 'use the preferred distribution centre config link when it requires a project id and one is supplied' do
                    midc = create_mi_dist_centre( nil, 'Monterotondo', '2014-01-01', nil )
                    project_id = midc.try(:mi_attempt).try(:es_cell).try(:ikmc_project_id)
                    assert_false project_id.nil?
                    assert_equal [ 'Monterotondo', "www.Monterotondo.com?query=#{project_id}"], midc.calculate_order_link( @config )
                end

                should 'use the preferred distribution centre config link when it requires a marker symbol and one is supplied' do
                    midc = create_mi_dist_centre( nil, 'BCM', '2014-01-01', nil )
                    marker_symbol = midc.try(:mi_attempt).try(:mi_plan).try(:gene).try(:marker_symbol)
                    assert_false marker_symbol.nil?
                    assert_equal [ 'BCM', "mailto:kompgroup@bcm.edu?subject=Mutant mouse for #{marker_symbol}"], midc.calculate_order_link( @config )
                end

                should 'use the distribution centre email contact for the link when neither default or preferred config links are supplied' do
                    midc = create_mi_dist_centre( nil, 'JAX', '2014-01-01', nil )
                    assert_equal [ 'JAX', "mailto:komp2@jax.org?subject=Mutant mouse enquiry"], midc.calculate_order_link( @config )
                end

                should 'error if the distribution centre email contact is blank and neither default or preferred config links are supplied' do
                    midc = create_mi_dist_centre( nil, 'CNB', '2014-01-01', nil )
                    exception = assert_raises(RuntimeError) { midc.calculate_order_link( @config ) }
                    assert_equal( "Failed to select a centre with name <CNB> and a contact email address", exception.message )
                end

            end

            context 'For Mi Attempt KOMP-specific tests' do

                should 'set the network to KOMP and return a KOMP link when the centre is UCD' do
                    midc = create_mi_dist_centre( nil, 'UCD', '2014-01-01', nil )
                    project_id = midc.try(:mi_attempt).try(:es_cell).try(:ikmc_project_id)
                    assert_false project_id.nil?
                    assert_equal [ 'KOMP', "http://www.komp.org/geneinfo.php?project=#{project_id}"], midc.calculate_order_link( @config )
                end

                should 'set the network to KOMP and return a KOMP link when the centre is KOMP Repo' do
                    midc = create_mi_dist_centre( nil, 'KOMP Repo', '2014-01-01', nil )
                    project_id = midc.try(:mi_attempt).try(:es_cell).try(:ikmc_project_id)
                    assert_false project_id.nil?
                    assert_equal [ 'KOMP', "http://www.komp.org/geneinfo.php?project=#{project_id}"], midc.calculate_order_link( @config )
                end

                should 'allow MMRRC as the distribution network when not blank and the centre is KOMP Repo or UCD' do
                    midc = create_mi_dist_centre( 'MMRRC', 'KOMP Repo', '2014-01-01', nil )
                    marker_symbol = midc.try(:mi_attempt).try(:mi_plan).try(:gene).try(:marker_symbol)
                    assert_false marker_symbol.nil?
                    assert_equal [ 'MMRRC', "http://www.mmrrc.org/catalog/StrainCatalogSearchForm.php?search_query=#{marker_symbol}"], midc.calculate_order_link( @config )
                end

            end

        end

        context 'Creation of Phenotype Attempt Distribution Centre order links' do

            # with network    -> should use config preferred or default, if they are not there error
            # without network -> use the dist centre to look in yaml, otherwise looks at centre email, if both blank error

            context 'Where Phenotype Attempt distribution network is provided' do

                # test done in Mi section above
                # should 'use the default distribution network config link when neither project id or marker symbol are supplied' do
                #     params = { :distribution_network_name => 'CMMR', :distribution_centre_name => 'HMGU', :dc_start_date => '2014-01-01' }
                #     assert_equal ['CMMR', 'mailto:Lauryl.Nutter@phenogenomics.ca?subject=Mutant mouse'], ApplicationModel::DistributionCentre.calculate_order_link( params, @config )
                # end

                should 'use the preferred distribution network config link when it requires a project id and one is supplied' do
                    padc = create_pa_dist_centre( 'KOMP', 'UCD', '2014-01-01', nil )
                    project_id = padc.try(:mouse_allele_mod).try(:mi_attempt).try(:es_cell).try(:ikmc_project_id)
                    assert_false project_id.nil?
                    assert_equal ['KOMP', "http://www.komp.org/geneinfo.php?project=#{project_id}"], padc.calculate_order_link( @config )
                end

                should 'use the preferred distribution network config link when it requires a marker symbol and one is supplied' do
                    padc = create_pa_dist_centre( 'EMMA', 'BCM', '2014-01-01', nil )
                    marker_symbol = padc.try(:mouse_allele_mod).try(:mi_plan).try(:gene).try(:marker_symbol)
                    assert_false marker_symbol.nil?
                    assert_equal ['EMMA', "http://www.emmanet.org/mutant_types.php?keyword=#{marker_symbol}"], padc.calculate_order_link( @config )
                end

                # test done in Mi section above
                # should 'error if neither default nor preferred distribution network config link is supplied' do
                #     params = { :distribution_network_name => 'TEST', :distribution_centre_name => 'HMGU', :dc_start_date => '2014-01-01' }
                #     exception = assert_raises(RuntimeError) { ApplicationModel::DistributionCentre.calculate_order_link( params, @config ) }
                #     assert_equal( "Failed to select a centre with name <HMGU> and a contact email address", exception.message )
                # end

                # test done in Mi section above
                # should 'error if neither distribution network or centre is supplied' do
                #     params = { :distribution_network_name => nil, :distribution_centre_name => nil, :dc_start_date => '2014-01-01' }
                #     exception = assert_raises(RuntimeError) { ApplicationModel::DistributionCentre.calculate_order_link( params, @config ) }
                #     assert_equal( "Unrecognised or missing distribution network and unrecognised centre with no contact email address", exception.message )
                # end

                # test done in Mi section above
                # should 'error if the current time is outside of the start and end date range' do
                #     params = { :distribution_network_name => 'CMMR', :distribution_centre_name => 'HMGU', :dc_start_date => '2014-01-01', :dc_end_date => '2014-02-01' }
                #     exception = assert_raises(RuntimeError) { ApplicationModel::DistributionCentre.calculate_order_link( params, @config ) }
                #     assert_equal( "Distribution Centre date range not current, cannot create order links", exception.message )
                # end

            end

            context 'Where Phenotype Attempt distribution network is not available' do

                setup do
                    puts "setting centre contact emails"
                    bcm_centre = Centre.find_by_name("BCM")
                    bcm_centre.contact_email = "kompgroup@bcm.edu"
                    bcm_centre.save!

                    jax_centre = Centre.find_by_name("JAX")
                    jax_centre.contact_email = "komp2@jax.org"
                    jax_centre.save!
                end

                # test done in Mi section above
                # should 'use the default distribution centre config link when neither project id or marker symbol are supplied' do
                #     params = { :distribution_centre_name => 'BCM', :dc_start_date => '2014-01-01' }
                #     assert_equal [ 'BCM', 'mailto:kompgroup@bcm.edu?subject=Mutant mouse enquiry'], ApplicationModel::DistributionCentre.calculate_order_link( params, @config )
                # end

                should 'use the preferred distribution centre config link when it requires a project id and one is supplied' do
                    padc = create_pa_dist_centre( nil, 'Monterotondo', '2014-01-01', nil )
                    project_id = padc.try(:mouse_allele_mod).try(:mi_attempt).try(:es_cell).try(:ikmc_project_id)
                    assert_false project_id.nil?
                    assert_equal [ 'Monterotondo', "www.Monterotondo.com?query=#{project_id}"], padc.calculate_order_link( @config )
                end

                should 'use the preferred distribution centre config link when it requires a marker symbol and one is supplied' do
                    padc = create_pa_dist_centre( nil, 'BCM', '2014-01-01', nil )
                    marker_symbol = padc.try(:mouse_allele_mod).try(:mi_plan).try(:gene).try(:marker_symbol)
                    assert_false marker_symbol.nil?
                    assert_equal [ 'BCM', "mailto:kompgroup@bcm.edu?subject=Mutant mouse for #{marker_symbol}"], padc.calculate_order_link( @config )
                end

                should 'use the distribution centre email contact for the link when neither default or preferred config links are supplied' do
                    padc = create_pa_dist_centre( nil, 'JAX', '2014-01-01', nil )
                    assert_equal [ 'JAX', "mailto:komp2@jax.org?subject=Mutant mouse enquiry"], padc.calculate_order_link( @config )
                end

                should 'error if the distribution centre email contact is blank and neither default or preferred config links are supplied' do
                    padc = create_pa_dist_centre( nil, 'CNB', '2014-01-01', nil )
                    exception = assert_raises(RuntimeError) { padc.calculate_order_link( @config ) }
                    assert_equal( "Failed to select a centre with name <CNB> and a contact email address", exception.message )
                end

            end

            context 'For Phenotype Attempt KOMP-specific tests' do

                should 'set the network to KOMP and return a KOMP link when the centre is UCD' do
                    padc = create_pa_dist_centre( nil, 'UCD', '2014-01-01', nil )
                    project_id = padc.try(:mouse_allele_mod).try(:mi_attempt).try(:es_cell).try(:ikmc_project_id)
                    assert_false project_id.nil?
                    assert_equal [ 'KOMP', "http://www.komp.org/geneinfo.php?project=#{project_id}"], padc.calculate_order_link( @config )
                end

                should 'set the network to KOMP and return a KOMP link when the centre is KOMP Repo' do
                    padc = create_pa_dist_centre( nil, 'KOMP Repo', '2014-01-01', nil )
                    project_id = padc.try(:mouse_allele_mod).try(:mi_attempt).try(:es_cell).try(:ikmc_project_id)
                    assert_false project_id.nil?
                    assert_equal [ 'KOMP', "http://www.komp.org/geneinfo.php?project=#{project_id}"], padc.calculate_order_link( @config )
                end

                should 'allow MMRRC as the distribution network when not blank and the centre is KOMP Repo or UCD' do
                    padc = create_pa_dist_centre( 'MMRRC', 'KOMP Repo', '2014-01-01', nil )
                    marker_symbol = padc.try(:mouse_allele_mod).try(:mi_plan).try(:gene).try(:marker_symbol)
                    assert_false marker_symbol.nil?
                    assert_equal [ 'MMRRC', "http://www.mmrrc.org/catalog/StrainCatalogSearchForm.php?search_query=#{marker_symbol}"], padc.calculate_order_link( @config )
                end

            end

        end
    end
end