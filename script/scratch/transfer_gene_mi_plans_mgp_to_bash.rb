#Script to transfer MGP MiPlans to BaSH consortium
bash_consortium = Consortium.where(:name => "BaSH").first
mgp_consortium = Consortium.where(:name => "MGP").first
gene_symbols = [
"Klhl35",
"Krt31",
"Krt74",
"Krt82",
"Krtdap",
"Ksr2",
"Larp4b",
"Lce1f",
"Lcor",
"Lgi3",
"Lman1",
"Lrrc40",
"Lrrc8b",
"Lyg1",
"Lyzl6",
"Mamstr",
"Mau2",
"Morn4",
"Mrpl16",
"Mrpl27",
"Mrpl55",
"Mslnl",
"Mthfsd",
"Plekhg2",
"Plscr2",
"Poc5",
"Pold3",
"Pole4",
"Polr1c",
"Pxk",
"Qser1",
"Rab17",
"Rnpep",
"Slc25a18",
"Slc27a6",
"Sfpq",
"Raph1",
"Rcc2",
"Rnasek",
"Rpl35",
"Sdr9c7",
"Samd8",
"Slc24a6",
"Slc25a28",
"Rbak",
"Slc12a9",
"Rreb1",
"Rnf157",
"Sgsm1",
"Sfrs18",
"Rwdd1",
"Rpl26",
"Rrp7a",
"Rnf183",
"Rnf145",
"Rpe",
"Samhd1",
"Rrp1",
"Rtn1",
"Rnf38",
"S100a16",
"Sec23b"
]

MiPlan.transaction do
  Audit.as_user(User.find_by_email!("gj2@sanger.ac.uk")) do
      count = 0
    gene_symbols.each do |this_gene_symbol|
      this_gene = Gene.where(:marker_symbol => this_gene_symbol).first
      mi_plans = MiPlan.where(:consortium_id => mgp_consortium.id, :gene_id => this_gene.id)
      if !mi_plans.empty?
        mi_plans.each do |this_mi_plan|
          if !this_mi_plan.mi_attempts.empty?
            #write warning to log
            Rails.logger.info "#{this_gene.marker_symbol} :: MI Plan #{this_mi_plan} has #{this_mi_plan.mi_attempts.length} MI Attempts"
          else
            bash_mi_plans = MiPlan.where(:consortium_id => bash_consortium.id, :gene_id => this_gene.id)
            if !bash_mi_plans.empty?
              #write warning to log
              Rails.logger.info"#{this_gene.marker_symbol} :: Gene has existing #{bash_mi_plans.length} BaSH Mi Plans :: Ids #{bash_mi_plans.map{ |b| b.id} } "
            else
              this_mi_plan.consortium = bash_consortium
              if this_mi_plan.save!
                count = count + 1
              end
              Rails.logger.info "#{this_mi_plan.consortium.name}"
              Rails.logger.info "SAVE #{this_gene.marker_symbol} MI Plan #{this_mi_plan.id}"

            end
          end
        end
      end
    end
      puts count
  end#Audited
end
