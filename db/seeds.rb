# encoding: utf-8

module Seeds
  def self.load(model_class, data)
    data.each do |data|
      data_id = data.delete(:id)
      thing = model_class.find_by_id(data_id)
      if thing
        thing.attributes = data
      else
        thing = model_class.new(data)
        thing.id = data_id
      end

      thing.save! if thing.changed?
    end
    update_db_sequence(model_class)
  end

  def self.update_db_sequence(model_class)
    model_class.connection.execute(<<-"SQL")
      select setval( '#{model_class.table_name}_id_seq',
                     (select id from #{model_class.table_name}
                                order by id desc
                                limit 1
                     )
                   );
    SQL
  end
end

Seeds.load Strain, [
  {:id =>  1, :name => "BALB/c"},
  {:id =>  2, :name => "BALB/cAm"},
  {:id =>  3, :name => "BALB/cAnNCrl"},
  {:id =>  4, :name => "BALB/cJ"},
  {:id =>  5, :name => "BALB/cN"},
  {:id =>  6, :name => "BALB/cWtsi;C57BL/6J-Tyr<c-Brd>"},
  {:id =>  7, :name => "C3HxBALB/c"},
  {:id =>  8, :name => "C57BL/6J"},
  {:id =>  9, :name => "C57BL/6J Albino"},
  {:id => 10, :name => "C57BL/6J-A<W-J>/J"},
  {:id => 11, :name => "C57BL/6J-Tyr<c-2J>"},
  {:id => 12, :name => "C57BL/6J-Tyr<c-2J>/J"},
  {:id => 13, :name => "C57BL/6J-Tyr<c-Brd>"},
  {:id => 14, :name => "C57BL/6J-Tyr<c-Brd>;C57BL/6JIco"},
  {:id => 15, :name => "C57BL/6J-Tyr<c-Brd>;C57BL/6N"},
  {:id => 16, :name => "C57BL/6J-Tyr<c-Brd>;Stock"},
  {:id => 17, :name => "C57BL/6JcBrd/cBrd"},
  {:id => 18, :name => "C57BL/6N"},
  {:id => 19, :name => "C57BL/6NCrl"},
  {:id => 20, :name => "C57BL6/NCrl"},
  {:id => 21, :name => "C57Bl/6J Albino"},
  {:id => 22, :name => "CD1"},
  {:id => 23, :name => "FVB"},
  {:id => 24, :name => "Stock"},
  {:id => 25, :name => "Swiss Webster"},
  {:id => 26, :name => "b"},
  {:id => 27, :name => "129P2"},
  {:id => 28, :name => "129P2/OlaHsd"},
  {:id => 29, :name => "129S5/SvEvBrd/Wtsi"},
  {:id => 30, :name => "129S5/SvEvBrd/Wtsi or C57BL/6J-Tyr<c-Brd>"},
  {:id => 31, :name => "C57BL/6J-Tyr<c-Brd> or C57BL/6NTac/Den"},
  {:id => 32, :name => "C57BL/6J-Tyr<c-Brd> or C57BL/6NTac/Den or CBA/Wtsi"},
  {:id => 33, :name => "C57BL/6J-Tyr<c-Brd> or C57BL/6NTac/USA"},
  {:id => 34, :name => "C57BL/6JIco"},
  {:id => 35, :name => "C57BL/6NTac"},
  {:id => 36, :name => "C57BL/6NTac/Den"},
  {:id => 37, :name => "C57BL/6NTac/Den or C57BL/6NTac/USA"},
  {:id => 38, :name => "C57BL/6NTac/USA"},
  {:id => 39, :name => "C57BL/6JIco;C57BL/6J-Tyr<c-Brd>"},
  {:id => 40, :name => "Delete once confirmed its use"},
  {:id => 41, :name => "c"},
  {:id => 42, :name => 'B6D2F1 x B6'},
  {:id => 43, :name => 'C57BL6'},
  {:id => 43, :name => 'ICR/Jcl'},
  {:id => 44, :name => 'C57BL/6Dnk'},
  {:id => 45, :name => 'C57BL/6Brd-Tyr<c-Brd>;Stock'},
  {:id => 46, :name => 'C57BL/6Brd-Tyr<c-Brd>;C57BL/6JIco'},
  {:id => 47, :name => 'C57BL/6Dnk or C57BL/6NTac'}
]

Seeds.load MiAttemptStatus, [
  {:id => 1, :description => 'Micro-injection in progress', :order_by => 220},
  {:id => 2, :description => 'Genotype confirmed', :order_by => 240},
  {:id => 3, :description => 'Micro-injection aborted', :order_by => 210},
  {:id => 4, :description => 'Chimeras obtained', :order_by => 230}
]

Seeds.load QcResult, [
  {:id => 1, :description => 'na'},
  {:id => 2, :description => 'fail'},
  {:id => 3, :description => 'pass'},
]

Seeds.load DepositedMaterial, [
  {:id => 1, :name => 'Frozen embryos'},
  {:id => 2, :name => 'Live mice'},
  {:id => 3, :name => 'Frozen sperm'}
]

Seeds.load Consortium, [
  {:id => 1,  :name => 'EUCOMM-EUMODIC', :funding => 'EUCOMM / EUMODIC', :participants => nil},
  {:id => 2,  :name => 'UCD-KOMP',       :funding => 'KOMP', :participants => 'Davis'},
  {:id => 3,  :name => 'MGP-KOMP',       :funding => 'KOMP / Wellcome Trust', :participants => 'Mouse Genetics Project, WTSI'},
  {:id => 4,  :name => 'BaSH',           :funding => 'KOMP2', :participants => 'Baylor, Sanger, Harwell'},
  {:id => 5,  :name => 'DTCC',           :funding => 'KOMP2', :participants => 'Davis-Toronto-Charles River-CHORI'},
  {:id => 6,  :name => 'Helmholtz GMC',  :funding => 'Infrafrontier/BMBF', :participants => 'Helmholtz Muenchen'},
  {:id => 7,  :name => 'JAX',            :funding => 'KOMP2', :participants => 'The Jackson Laboratory'},
  {:id => 8,  :name => 'MARC',           :funding => 'China', :participants => 'Model Animal Research Centre, Nanjing University'},
  {:id => 9,  :name => 'MGP',            :funding => 'Wellcome Trust', :participants => 'Mouse Genetics Project, WTSI'},
  {:id => 10, :name => 'Monterotondo',   :funding => 'European Union', :participants => 'Monterotondo Institute for Cell Biology (CNR)'},
  {:id => 11, :name => 'MRC',            :funding => 'MRC', :participants => 'MRC - Harwell'},
  {:id => 12, :name => 'NorCOMM2',       :funding => 'Genome Canada', :participants => 'NorCOMM2'},
  {:id => 13, :name => 'Phenomin',       :funding => 'Phenomin', :participants => 'ICS'},
  {:id => 14, :name => 'RIKEN BRC',      :funding => 'Japanese government', :participants => 'RIKEN BRC'},
  {:id => 15,  :name => 'DTCC-Legacy',   :funding => 'KOMP312/KOMP', :participants => 'Davis-CHORI'},
  {:id => 16,  :name => 'MGP Legacy',    :funding => 'Wellcome Trust', :participants => 'Mouse Genetics Project, WTSI'}
]

Seeds.load Centre, [
  {:id => 1,  :name => 'WTSI'},
  {:id => 2,  :name => 'ICS'},
  {:id => 3,  :name => 'Harwell'},
  {:id => 4,  :name => 'Monterotondo'},
  {:id => 5,  :name => 'UCD'},
  {:id => 6,  :name => 'HMGU'},
  {:id => 7,  :name => 'CNB'},
  {:id => 8,  :name => 'APN'},
  {:id => 9,  :name => 'BCM'},
  {:id => 10, :name => 'Oulu'},
  {:id => 11, :name => 'TCP'},
  {:id => 12, :name => 'RIKEN BRC'},
  {:id => 13, :name => 'DTCC'},
  {:id => 14, :name => 'JAX'},
  {:id => 15, :name => 'MARC'},
  {:id => 16, :name => 'VETMEDUNI'},
  {:id => 17, :name => 'IMG'},
  {:id => 18, :name => 'CNRS'}
]

Seeds.load MiPlan::Status, [
  {:order_by => 110,  :id => 8,  :name => 'Assigned - ES Cell QC In Progress', :description => 'Assigned - The ES cells are currently being QCed by the production centre'},
  {:order_by => 100,  :id => 9,  :name => 'Assigned - ES Cell QC Complete', :description => 'Assigned - ES cells have passed the QC phase and are ready for micro-injection'},
  {:order_by => 90,  :id => 10, :name => 'Aborted - ES Cell QC Failed', :description => 'Aborted - ES cells have failed the QC phase, and micro-injection cannot proceed'},
  {:order_by => 80,  :id => 1,  :name => 'Assigned', :description => 'Assigned - A single consortium has expressed an interest in injecting this gene'},
  {:order_by => 70,  :id => 4,  :name => 'Inspect - GLT Mouse', :description => 'Inspect - A GLT mouse is already recorded in iMits'},
  {:order_by => 60,  :id => 5,  :name => 'Inspect - MI Attempt', :description => 'Inspect - An active micro-injection attempt is already in progress'},
  {:order_by => 50,  :id => 6,  :name => 'Inspect - Conflict', :description => 'Inspect - This gene is already assigned in another planned micro-injection'},
  {:order_by => 40,  :id => 3,  :name => 'Conflict', :description => 'Conflict - More than one consortium has expressed an interest in micro-injecting this gene'},
  {:order_by => 30,  :id => 2,  :name => 'Interest', :description => 'Interest - A consortium has expressed an interest to micro-inject this gene'},
  {:order_by => 20,  :id => 7,  :name => 'Inactive', :description => 'Inactive - A consortium/production centre has failed micro-injections on this gene dated over 6 months ago - they have given up'},
  {:order_by => 10, :id => 11, :name => 'Withdrawn', :description => 'Withdrawn - Interest in micro-injecting this gene was withdrawn by the parties involved'}
]

Seeds.load MiPlan::Priority, [
  {:id => 1, :name => 'High', :description => 'Estimated injection in the next 0-4 months'},
  {:id => 2, :name => 'Medium', :description => 'Estimated injection in the next 5-8 months'},
  {:id => 3, :name => 'Low', :description => 'Estimated injection in the next 9-12 months'}
]

Seeds.load MiPlan::SubProject, [
  {:id => 1, :name => ''},
  {:id => 2, :name => 'MGPinterest'},
  {:id => 3, :name => 'WTSI_Blood_A'},
  {:id => 4, :name => 'WTSI_Cancer_A'},
  {:id => 5, :name => 'WTSI_Infection_A'},
  {:id => 6, :name => 'WTSI_MGPcollab_A'},
  {:id => 7, :name => 'WTSI_Hear_A'},
  {:id => 11, :name => 'WTSI_IBD_A'},
  {:id => 8, :name => 'Legacy EUCOMM'},
  {:id => 9, :name => 'Legacy KOMP'},
  {:id => 10, :name => 'Legacy with new Interest'},
  {:id => 12, :name => 'WTSI_Bone_A'},
  {:id => 13, :name => 'WTSI_Bespoke_A'},
  {:id => 14, :name => 'MGP Legacy'},
  {:id => 15, :name => 'WTSI_Sense_A'},
  {:id => 16, :name => 'WTSI_Metabolism_A'},
  {:id => 17, :name => 'WTSI_Cre'},
  {:id => 18, :name => 'WTSI_Malaria_A'},
  {:id => 19, :name => 'WTSI_Rarediseases_A'},
  {:id => 20, :name => 'WTSI_Fat_A'}
]

Seeds.load PhenotypeAttempt::Status, [
  {:id =>  1, :name => 'Phenotype Attempt Aborted', :order_by => 310},
  {:id =>  2, :name => 'Phenotype Attempt Registered', :order_by => 320},
  {:id =>  3, :name => 'Rederivation Started', :order_by => 330},
  {:id =>  4, :name => 'Rederivation Complete', :order_by => 340},
  {:id =>  5, :name => 'Cre Excision Started', :order_by => 350},
  {:id =>  6, :name => 'Cre Excision Complete', :order_by => 360},
  {:id =>  7, :name => 'Phenotyping Started', :order_by => 370},
  {:id =>  8, :name => 'Phenotyping Complete', :order_by => 380}
]

Seeds.load DeleterStrain, [
  {:id => 1, :name => 'MGI:2176052: Tg(Zp3-cre)3Mrt'},
  {:id => 2, :name => 'MGI:3046308: Hprt<tm1(CMV-cre)Brd>'},
  {:id => 3, :name => 'B6N.Cg-Tg(Sox2-cre)1Amc/J'},
  {:id => 4, :name => 'Gt(ROSA)26Sor<tm16(cre)Arte>'}
]
