#!/usr/bin/env ruby

require 'pp'
require 'color'

marker_symbols = %W{
  Ap4e1
  Nxn
  Dnase1l2
  Rnf10
  Dbn1
  Prkab1
  Nalcn
  Asic4
  Kcna10
  Ano3
  Catsper3
  Gpr126
  Trib2
  Snrk
  Nuak2
  Sik2
  Gjc3
  Nr1d2
  Stk36
  Gpr39
  Vrk1
  Gja10
  Fzd8
  Npbwr1
  Tssk6
  Kcnc3
  Wnk3
  Galr3
  Gpr65
  Tnfsf10
  Ly86
  1700040L02Rik
  Vwa2
  Caskin1
  Bpifb1
  Il20rb
  Lypd6
  Ifi204
  Accn4
  Mfsd2a
  Cdan1
  Fcer1g
  Fam151a
  Chst8
  Mad1l1
  Peli1
  1700010I14Rik
  Gpsm1
  Plcb2
  Casp4
  Map3k8
  Elf3
  Tbx4
  Flii
  Lgsn
  Aoah
  Gabpa
  Pde6a
  Olfm3
  Aasdhppt
  Klhdc4
  Haus7
  Rbm22
  Agbl4
  Mctp1
  Utp18
  Upf3a
  Sh3rf2
  Sqrdl
  Enpp1
  1700015E13Rik
  Gm14496
  Tcf25
  Gfra2
  Gm16039
  Znrf1
  Hcn2
  1700069L16Rik
  Mak
  Clca3
  Olfr376
  Parp11
  Serpina6
  5430419D17Rik
  Speer4f
  Il16
  Sec61b
  Pkhd1
  E2f5
  Pcsk6
  Gm9733
  Arhgef16
  Smr3a
  Ptpre
  Pacrg
  Lpar4
  Zfp81
  Foxo6
  Hs3st3b1
  Pcdh11x
  Nedd9
  Olfr1098
  Spag11a
  Nfatc4
  Hhatl
  Trh
  Nkx2-9
  Map3k4
  Lyzl1
  Rps12
  Rps4x
  Sstr1
  B3galt2
  Cnr1
  Zbtb33
  Ifitm10
  Ccr1
  Lhx5
  Wwp1
  Foxred2
  Stc1
  Nell2
  Bin3
  Mrgprb2
  Fam160a2
  Selm
  Cpne7
  Tmem225
  Olfr392
  Isg15
  Chsy3
  Atxn7l2
  Dpy19l1
  Bpifa2
  Cxcl10
  Gpr150
  Akap4
  Antxrl
  Tspan2
  Nxf3
  Abhd11
  Gm15217
  Lrrc8c
  Olfr380
  Dok7
  2700054A10Rik
  Atp8a2
  Scn2a1
  Setd3
  Zbtb48
  Dsg1c
  Pgpep1l
  Slc6a18
  Surf2
}

DEBUG = false
EXPECTED_COUNT = 154

missing_genes = {
  'Accn4' => {  # synonym for Asic4
    'mgi_id' => ' MGI:2652846'
  }
}

counts = {
  1 => 0,
  2 => 0,
  3 => 0
}

raise "#### marker_symbols expected/found: #{EXPECTED_COUNT}/#{marker_symbols.size}" if EXPECTED_COUNT != marker_symbols.size

def create_plan(gene)
  MiPlan.create!( :gene => gene,
  :consortium => Consortium.find_by_name('DTCC'),
  :production_centre => Centre.find_by_name('UCD'),
  :mutagenesis_via_crispr_cas9 => true,
  :priority => MiPlan::Priority.find_by_name!('Low'),
  :status => MiPlan::Status.find_by_name!('Assigned'))
end

MiAttempt.transaction do

  marker_symbols.each do |marker_symbol|
    gene = Gene.find_by_marker_symbol marker_symbol

    #If the gene doesn't exist for the plan, then create it & mark it up for crispr production.
    if ! gene
      #puts "#### 3. create gene & add plan: '#{marker_symbol}'".blue
      gene = Gene.create!(:marker_symbol => marker_symbol, :mgi_accession_id => missing_genes[marker_symbol]['mgi_id'])
      plan = create_plan(gene)
      puts "#{marker_symbol},create gene & add plan,#{plan.id}"
      counts[3] += 1
      next
    end

    plans = gene.mi_plans.where("consortium_id = (select id from consortia where name = 'DTCC') and production_centre_id = (select id from centres where name = 'UCD')")
    crispr_cas9_plans = gene.mi_plans.where("consortium_id = (select id from consortia where name = 'DTCC') and mutagenesis_via_crispr_cas9 is true and production_centre_id = (select id from centres where name = 'UCD')")

    raise "#### found plans with crispr_cas9_plans set true!" if crispr_cas9_plans.size != 0

    production = false

    filtered_plans = []

    plans.each do |plan|
      next if plan.phenotype_only
      raise "#### '#{marker_symbol}' already has mutagenesis_via_crispr_cas9!" if plan.mutagenesis_via_crispr_cas9
      production = plan.mi_attempts.size > 0
      filtered_plans.push plan
    end

    #If the plan exists for the gene already AND there's non-crispr production, create a second plan.
    if filtered_plans.size > 0 && production
      #puts "#### 1. create another plan for '#{marker_symbol}'!".blue
      plan = create_plan(gene)
      puts "#{marker_symbol},create another plan - production (#{filtered_plans.size}),#{plan.id}"
      counts[1] += 1
      next
    end

    #If the plan exists for the gene already and there's NO production, alter the plan to have this boolean set to true.
    if filtered_plans.size == 1 && ! production
      #puts "#### 2. convert plan for '#{marker_symbol}'!".blue
      puts "#{marker_symbol},convert plan - NO production (#{filtered_plans.size}),#{filtered_plans.first.id}"
      filtered_plans.first.mutagenesis_via_crispr_cas9 = true
      filtered_plans.first.save!
      counts[2] += 1
      next
    end

    if filtered_plans.size > 1 && ! production
      #puts "#### 1. create another plan for '#{marker_symbol}'!".blue
      plan = create_plan(gene)
      puts "#{marker_symbol},create another plan - NO production (#{filtered_plans.size}),#{plan.id}"
      counts[1] += 1
      next
    end

    if filtered_plans.size == 0 && ! production
      #puts "#### 1. create another plan for '#{marker_symbol}'!".blue
      plan = create_plan(gene)
      puts "#{marker_symbol},create another plan - NO production (#{filtered_plans.size}),#{plan.id}"
      counts[1] += 1
      next
    end

    puts "#### not processed '#{marker_symbol}' (filtered_plans.size/production) - (#{filtered_plans.size}/#{production})".red
  end

  pp counts

  processed = counts[1] + counts[2] + counts[3]

  raise "#### missing (#{processed}/#{EXPECTED_COUNT})!" if processed != EXPECTED_COUNT

  raise "rollback!" if DEBUG

  puts "done!".green

  #Mark up / assign plans selected by DTCC for crispr-pilot (attached).
  #
  #If the plan exists for the gene already AND there's non-crispr production, create a second plan.
  #If the plan exists for the gene already and there's NO production, alter the plan to have this boolean set to true.
  #If the gene doesn't exist for the plan, then create it & mark it up for crispr production.

end
