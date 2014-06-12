require 'test_helper'

class TargRep::RealAlleleTest < ActiveSupport::TestCase

	context "creating random real alleles" do
		should "creating 20 random real alleles should succeed" do
			x = 20
			x.times do |i|
			    test_allele = Factory.build(:base_real_allele)
			    assert_true test_allele.save
			end

			# TargRep::RealAllele.all.map{ |ra| puts "#{ra.try(:gene_id)} : #{ra.try(:gene).try(:marker_symbol)} : #{ra.try(:allele_name)}" }
		end
	end

	context "validation checks" do
		should "creating cbx1 real allele type a should succeed" do
			real_allele_a = Factory.build(:real_allele_cbx1_a)
			assert_true real_allele_a.save
		end

		should "creating real allele should not succeed without a gene" do
			real_allele = Factory.build :real_allele,
				:gene_id => nil,
				:allele_name => "tm1z(EUCOMM)Wtsi"
			assert_false real_allele.save
		end

		should "creating real allele should not succeed without an allele name" do
			cbx1gene = Factory.create(:gene_cbx1)
			real_allele = Factory.build :real_allele,
				:gene_id => cbx1gene.id,
				:allele_name => nil
			assert_false real_allele.save
		end

		should "creating cbx1 real allele should not succeed with an incorrect type" do
			cbx1gene = Factory.create(:gene_cbx1)
			real_allele = Factory.build :real_allele,
				:gene_id => cbx1gene.id,
				:allele_name => "tm1z(EUCOMM)Wtsi"
			assert_false real_allele.save
		end

		should "creating cbx1 real allele type a twice should NOT succeed due to uniqueness validation" do
			cbx1gene = Factory.create(:gene_cbx1)
			real_allele_a1 = Factory.build :real_allele,
				:gene_id => cbx1gene.id,
				:allele_name => "tm1a(EUCOMM)Wtsi"
			assert_true real_allele_a1.save

			real_allele_a2 = Factory.build :real_allele,
				:gene_id => cbx1gene.id,
				:allele_name => "tm1a(EUCOMM)Wtsi"
			assert_false real_allele_a2.save
		end
	end

	context "creating set of cbx1 alleles" do
		should "creating cbx1 real allele type a should succeed" do
			real_allele_a = Factory.build(:real_allele_cbx1_a)
			assert_true real_allele_a.save
		end

		should "creating cbx1 real allele type b should succeed" do
			real_allele_b = Factory.build(:real_allele_cbx1_b)
			assert_true real_allele_b.save
		end

		should "creating cbx1 real allele type c should succeed" do
		  	real_allele_c = Factory.build(:real_allele_cbx1_c)
		  	assert_true real_allele_c.save
		end

		should "creating cbx1 real allele type d should succeed" do
		  	real_allele_d = Factory.build(:real_allele_cbx1_d)
		  	assert_true real_allele_d.save
		end

		should "creating cbx1 real allele type e should succeed" do
		  	real_allele_e = Factory.build(:real_allele_cbx1_e)
		  	assert_true real_allele_e.save
		end

		should "creating cbx1 real allele type e.1 should succeed" do
		  	real_allele_e1 = Factory.build(:real_allele_cbx1_e1)
		  	assert_true real_allele_e1.save
		end

		should "creating cbx1 real allele type deletion should succeed" do
		  	real_allele_del = Factory.build(:real_allele_cbx1_del)
		  	assert_true real_allele_del.save
		end
	end

end
