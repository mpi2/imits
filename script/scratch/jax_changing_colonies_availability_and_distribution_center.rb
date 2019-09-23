############################################################
### pre cre JAX colonies that are not available any more ###
############################################################

colony_names = ["JAX-17782A-B5-1", "JAX-14600A-G5-1", "JAX-14171A-A2-1", "JAX-11164C-G3-1", "JAX-HEPD0678_2_F05-1", "JAX-18550A-G4-1", "JAX-HEPD0719_3_G08-1", "JAX-13348A-C10-1", "JAX-HEPD0788_6_B09-1", "JAX-15075A-A5-1", "JAX-11588A-A1-1", "JAX-18731A-C12-1", "JAX-15630B-C4-1", "JAX-12702A-D12-1", "JAX-19162A-A6-1", "JAX-15324A-A6-1", "JAX-HEPD0617_2_A06-1", "JAX-EPD0838_4_A06-1", "JAX-12053A-G2-1", "JAX-13357A-A1-1", "JAX-HEPD0764_3_E08-1", "JAX-DEPD0003_13_A01-1", "JAX-EPD0901_5_D12-1", "JAX-15602A-A5-1", "JAX-13360A-B7-1", "JAX-HEPD0583_2_B09-1", "JAX-HEPD0752_5_F07-1", "JAX-11713A-F8-1", "JAX-12474B-D10-1", "JAX-12494A-F11-1", "JAX-EPD0208_4_B08-1", "JAX-12049A-A2-1", "JAX-10264A-B5-1", "JAX-10669A-H9-1", "JAX-11786A-F7-1", "JAX-HEPD0677_1_C11-1", "JAX-10776A-A12-1", "JAX-HEPD0720_1_C02-1", "JAX-13346B-G3-1", "JAX-EPD0401_3_G09-1", "JAX-14354A-G10-1", "JAX-17785A-B7-1", "JAX-EPD0653_2_A06-1", "JAX-17027A-F6-1", "JAX-17312A-C11-1", "JAX-EPD0670_4_A08-1", "JAX-EPD0516_1_G08-1", "JAX-EPD0754_3_D01-1", "JAX-12016A-C4-1", "PH19131", "JAX-EPD0394_3_G06-1", "JAX-HEPD0510_4_F05-1", "JAX-12241A-A8-1", "JAX-13389A-A11-1", "JAX-HEPD0686_5_H08-1", "JAX-EPD0776_3_C08-1", "JAX-15992A-H10-1", "JAX-EPD0599_4_C06-1", "JAX-HEPD0722_8_H07-1", "JAX-10925A-F2-1", "JAX-12058A-B5-1", "JAX-EPD0208_6_G02-2", "JAX-DEPD00501_4_C09-1", "JAX-11736A-D7-1", "JAX-12882A-F6-1", "JAX-13396A-F8-1", "JAX-DEPD0003_3_D01-1", "JAX-DEPD00535_5_A01-1", "JAX-EPD0618_1_B03-2", "JAX-10211A-E7-1", "JAX-12132A-H9-1", "JAX-15754B-E2-1", "JAX-14596A-D6-1", "JAX-EPD0741_1_F11-1", "JAX-EPD0073_5_D06-1", "JAX-EPD0293_6_D02-1", "JAX-15239A-C1-1", "JAX-14478B-H12-1", "JAX-14012D-G9-1", "JAX-11902A-A6-1", "JAX-EPD0932_3_H07-1", "JAX-11452A-E5-1", "JAX-13036A-D9-1", "JAX-DEPD00549_6_B03-2", "JAX-HEPD0647_2_C11-1", "JAX-11674A-C9-1", "JAX-DEPD00568_3_A03-1", "JAX-18773A-E11-1", "JAX-EPD0336_1_F05-1", "JAX-11854A-A1-1", "JAX-EPD0653_2_D02-1", "JAX-19252A-D9-1", "JAX-EPD0319_6_B07-1", "JAX-DEPD00518_3_C02-1", "JAX-DEPD00013_2_G06-1", "JAX-10296B-H3-1", "JAX-EPD0305_5_H03-1", "JAX-DEPD00583_3_G07-1", "JAX-15497A-A12-1", "JAX-DEPD00521_1_A04-1", "JAX-EPD0161_2_C01-1", "JAX-HEPD0789_6_F04-1", "JAX-14437A-C3-1", "JAX-DEPD0003_16_E02-1", "JAX-HEPD0933_4_G06-1", "JAX-EPD0246_4_C03-1", "JAX-17330A-A2-1", "JAX-10235B-G11-1", "JAX-DEPD00577_6_C12-1", "JAX-13429A-A5-1", "JAX-12298A-C9-1", "JAX-EPD0394_1_G07-1", "JAX-14944A-C8-1", "JAX-10263A-F9-1", "JAX-15502A-C9-1", "JAX-EPD0357_3_G04-1", "JAX-EPD0742_2_D11-1", "JAX-14467A-C5-1", "JAX-HEPD0681_4_B12-1", "JAX-15565A-F8-1", "17806 (PH)", "JAX-HEPD0535_5_H05-1", "JAX-HEPD0748_8_F07-1", "JAX-DEPD00518_3_C12-1", "JAX-EPD0267_5_C12-1", "JAX-14858B-B5-1", "JAX-EPD0805_2_C01-1", "JAX-EPD0727_5_F01-1", "JAX-12670B-G6-1", "JAX-EPD0817_6_G06-1", "JAX-EPD0234_3_C05-1", "JAX-EPD0331_1_A04-1", "JAX-10451A-D6-1", "JAX-EPD0406_4_H07-1", "JAX-EPD0168_2_A08-1", "JAX-HEPD0755_6_B08-1", "JAX-EPD0842_5_F11-1", "JAX-17597C-B10-1", "JAX-EPD0714_4_C11-1", "JAX-EPD0396_3_H07-1", "JAX-18796A-G12-1", "JAX-16092A-B4-1", "JAX-HEPD0705_6_G06-1", "JAX-12893A-A12-1", "JAX-HEPD0698_4_C07-1", "JAX-DEPD00581_2_D04-1", "JAX-17987A-F5-1", "JAX-18800A-A10-1", "JAX-DEPD00534_4_E12-1", "JAX-13475A-G5-1", "JAX-12088A-C4-1", "JAX-11515B-H12-1", "JAX-HEPD0711_6_D09-1", "JAX-15347A-G12-1", "JAX-EPD0657_5_D04-1", "JAX-17346A-B4-1", "JAX-10851A-D11-2", "JAX-11798A-A5-1", "JAX-12859A-A2-1", "JAX-17603A-A10-2", "JAX-13239A-E6-2", "JAX-11576A-B10-2", "JAX-16795A-F1-2", "JAX-15380A-C6-1", "JAX-EPD0309_4_B09-1", "JAX-13480A-E3-1", "JAX-EPD0332_1_A05-1", "JR19050(PH)", "JAX-EPD0315_2_B08-1", "JAX-11792A-E10-1", "JAX-HEPD0638_4_G06-1", "JAX-EPD0489_2_E04-1", "JAX-12666C-E6-1", "JAX-12547A-C9-1", "JAX-DEPD00567_7_D03-1", "JAX-11034A-C11-1", "JAX-EPD0322_4_E10-1", "JAX-HEPD0594_4_E08-1", "JAX-19258A-B11-1", "JAX-13491A-G1-2", "JAX-10664A-A5-1", "JAX-15747A-C5-1", "JAX-DEPD00577_2_F08-1", "JAX-DEPD00532_6_B11-1", "JAX-EPD0628_1_C10-1", "PH19139", "JAX-EPD0658_5_D08-1", "JAX-13336A-F3-1", "JAX-17795A-F9-1", "JAX-EPD0086_1_B11-1", "JAX-13493A-H6-1", "JAX-17610A-C12-1", "JAX-EPD0592_3_B04-2", "JAX-HEPD0652_5_C12-1", "JAX-EPD0625_3_E10-2", "JAX-DEPD00011_3_A09-1", "JAX-16084A-A8-1", "JAX-EPD0815_7_G05-1", "JAX-11301B-D4-1", "JAX-EPD0490_5_F02-1", "JAX-13464A-B8-2", "JAX-EPD0351_3_H02-1", "JAX-HEPD0778_6_G06-1", "JAX-EPD0195_3_H07-1", "JAX-13465A-A2-2", "JAX-EPD0244_2_E01-1", "JAX-10658A-A10-1", "JAX-EPD0770_1_C03-2", "JAX-11485A-F4-1", "JAX-EPD0577_1_C01-1", "JAX-13508A-C5-1", "JAX-EPD0742_4_C08-1", "JAX-15770A-B4-1", "JAX-DEPD00524_3_A06-1", "JAX-EPD0125_5_H05-1", "JAX-10030C-F5-1", "JAX-12455A-G6-1", "JAX-EPD0075_2_F04-1", "JAX-11066A-C12-1", "EPD0101_2_E10", "JAX-10392A-E12-1", "JAX-19731A-F11-1", "JAX-HEPD0741_5_G05-1", "JAX-EPD0770_2_E05-1", "JAX-17991A-H8-1", "JAX-EPD0351_3_G05-1", "JAX-EPD0430_5_E03-1", "JAX-15144A-C11-2", "JAX-10390D-F4-1", "JAX-10674A-D6-1", "JAX-DEPD00522_1_C01-1", "JAX-12911A-G3-1", "JAX-EPD0507_4_E01-1", "JAX-11890A-C12-1", "JAX-14664A-G8-1", "JAX-DEPD00536_4_C05-1", "JAX-10866A-D7-1", "JAX-EPD0653_3_C12-1", "JAX-DEPD00554_4_A03-1", "JAX-EPD0647_3_B12-1", "JAX-DEPD00557_2_E01-1", "JAX-13548A-D3-1", "JAX-18862A-E10-1", "JAX-EPD0110_4_B05-1", "JAX-DEPD0005_5_G07-1", "JAX-EPD0816_4_B02-1", "JAX-HEPD0712_7_H05-1", "JAX-HEPD0755_4_C05-1", "JAX-13566A-G7-1", "JAX-10231B-H11-1", "JAX-13571A-A2-1", "JAX-15769A-B10-1", "JAX-EPD0282_6_H06-1", "JAX-EPD0207_5_B07-1", "JAX-12997A-A1-2", "JAX-13573A-B8-1", "JAX-13574A-G11-1", "JAX-11502A-B6-1", "JAX-13006A-C11-1", "JAX-13007A-F5-2", "JAX-18576A-D2-1", "JAX-13331A-E12-1", "17873 (PH)", "JAX-10050A-F4-1", "JAX-EPD0307_1_F05-1", "JAX-12237B-E2-1", "JAX-10712A-A11-1", "JAX-11135B-A6-1", "JAX-HEPD0774_6_H07-1", "JAX-19295A-E11-1", "JAX-HEPD0637_4_F12-1", "JAX-15411B-D1-1", "JAX-EPD0822_4_A03-1", "JR19387 (PH)", "JAX-DEPD00539_7_G09-1", "JAX-13586B-H3-1", "JAX-11911A-E10-1", "JAX-EPD0044_1_B02-1", "JAX-14956A-A7-1", "JAX-14312A-C12-1", "JAX-12092A-G2-1", "JAX-EPD0804_6_E02-2", "JAX-EPD0246_7_C11-1", "JAX-11187B-E2-1", "JAX-EPD0855_4_A09-1", "JAX-EPD0569_1_D04-1", "JAX-DEPD00517_6_B05-1", "JAX-15514A-D8-1", "JAX-13985A-F4-1", "JAX-17908A-A10-1", "JAX-10920A-E3-1", "JAX-17146A-A5-2", "JAX-DEPD00576_1_A06-1", "JAX-EPD0624_1_H07-2", "JAX-HEPD0697_4_H11-1", "JAX-EPD0478_1_A04-1", "JAX-14545B-A5-1", "JAX-EPD0680_2_H02-1", "JAX-12806A-A3-1", "JAX-11217A-F1-1", "JAX-14930A-H9-1", "JAX-HEPD0764_5_E02-1", "JAX-12489A-E11-1", "JAX-10313A-C10-1", "JAX-16791A-G4", "JAX-EPD0889_5_D01-1", "JAX-EPD0825_1_D03-1", "JAX-EPD0282_5_A02-1", "JAX-HEPD0700_1_B04-1", "JAX-HEPD0886_5_C09-1", "JAX-16064A-B12-1", "JAX-EPD0284_1_C05-1", "JAX-16457A-A6-2", "JAX-14613A-D9-1", "JAX-EPD0496_2_C05-1", "JAX-10756D-A8-1", "JAX-13145A-C1-1", "JAX-DEPD0003_20_H02-1", "JAX-HEPD0663_8_F10-2", "JAX-EPD0415_3_C09-1", "JAX-EPD0730_2_F11-1", "JAX-EPD0618_5_H10-1", "JAX-EPD0865_1_B07-1", "JAX-12650A-B5-1", "JAX-18894A-F10-2", "JAX-HEPD0706_1_C09-1", "JAX-16874A-F11-1", "JAX-EPD0375_4_A05-1", "JAX-DEPD00560_2_B08-1", "JAX-16025A-A2-1", "JAX-DEPD00513_1_C09-1", "JAX-14015A-G3-2", "JAX-13624A-A1-1", "JAX-HEPD0632_4_F11-1", "JAX-14747A-A12-1", "JAX-DEPD00539_6_E09-2", "JAX-15237A-C6-2", "11016A-G7", "JAX-12880A-F1-1", "JAX-13630A-A7-2", "JAX-13636A-B2-2", "JAX-15506A-D3-1", "JAX-14348A-A7-1", "JAX-EPD0661_4_E03-1", "JAX-HEPD0746_2_D02-1", "JAX-10621A-E12-1", "JAX-13785A-E7-1", "17161A-H2", "JAX-DEPD0007_6_E07-1", "JAX-11729A-A7-1", "JAX-HEPD0616_5_D07-1", "12639A-D8", "18909A-B8", "17847 (PH)", "JAX-12105B-B6-2", "JAX-HEPD0711_6_E04-1", "JAX-EPD0334_7_D05-1", "JAX-EPD0025_1_G12-1", "JAX-HEPD0746_3_D08-1", "JAX-EPD0135_2_A05-1", "JAX-17270C-G8-1", "JAX-EPD0603_4_E09-1", "JAX-EPD0763_2_A06-1", "JAX-HEPD0673_6_D02-1", "JAX-HEPD0543_6_E02-1", "19033 (PH)", "JAX-11571A-A3-1", "JAX-10871A-A7-1", "JAX-15762A-A6-1", "JAX-EPD0531_1_B09-1", "JAX-18924A-A2-1", "JAX-12335A-F4-1", "JAX-EPD0082_6_A03-1", "JAX-EPD0094_3_B10-1", "JAX-HEPD0703_3_A01-1", "JAX-HEPD0744_5_D10-1", "JAX-EPD0379_2_F12-1", "JAX-13664A-C12-1", "JAX-EPD0503_4_F01-1", "JAX-15734A-E2-1", "JAX-10312B-B2-2", "JAX-13674A-B9-1", "JAX-10509A-B6-2", "JAX-13675A-C4-1", "JAX-13677A-A4-1", "JAX-13678B-F5-2", "JAX-DEPD00542_3_B09-1", "JAX-EPD0479_4_E10-2", "JAX-13683A-E4-1", "JAX-10523B-G10-1", "JAX-DEPD00520_2_A09-2", "JAX-EPD0174_1_G02-1", "JAX-10861A-C8-1", "JAX-13685A-B9-2", "JAX-EPD0739_2_C12-1", "JAX-18938A-E2-1", "JAX-EPD0588_3_D03-1", "JAX-HEPD0580_5_C04-1", "JAX-EPD0755_2_F06-1", "JAX-EPD0694_5_B10-1", "JAX-EPD0610_4_F10-1", "JAX-DEPD0007_1_G07-1", "JAX-EPD0570_3_D10-1", "JAX-HEPD0756_4_F07-1", "JAX-14579B-G5-1", "JAX-EPD0898_4_F05-1", "JAX-11288A-A10-1", "JAX-DEPD00583_7_C07-1", "JAX-DEPD00505_1_C01-1", "JAX-EPD0374_4_F12-1", "JAX-17287A-C4-2", "JAX-DEPD00502_6_A05-1", "JAX-14754A-G8-1", "JAX-16712A-A8-1", "JAX-10751E-A4-1", "JAX-18632A-A2-2", "JAX-EPD0285_1_C04-1", "JAX-DEPD00524_4_E10-1", "JAX-EPD0375_3_A09-1", "JAX-13544A-F2-1", "JAX-18954A-C12-2", "JAX-15467A-D10-1", "JAX-14340A-A3-1", "JAX-13038A-G1-1", "JAX-EPD0383_6_B01-1", "JAX-EPD0199_3_B01-2", "JAX-13722A-C12-1", "JAX-17947A-B7-2", "JAX-EPD0102_4_B10-1", "JAX-10480A-B4-2", "JAX-17454A-H12-2", "JAX-13021A-C2-1", "JAX-DEPD00572_5_B12-1", "JAX-DEPD00539_8_A08-1", "JAX-13729A-H11-1", "JAX-EPD0374_5_A09-1", "JAX-18960A-B11-1", "JAX-EPD0428_7_H01-1", "JAX-10197D-C11-2", "JAX-14018A-G3-2", "JAX-15631A-A2-1", "JAX-18963A-C1-1", "JAX-EPD0813_5_B06-1", "JAX-HEPD0641_3_C10-1", "JAX-17468-A11-1", "JAX-10763C-A2-1", "JAX-16086A-B10-2", "JAX-11483A-F5-1", "JAX-EPD0740_4_G01-1", "JAX-HEPD0723_1_C12-1", "JAX-15276A-E3-1", "JAX-15671A-D10-1", "JAX-EPD0113_4_G12-1", "JAX-EPD0699_2_D05-1", "JAX-13163A-A7-1", "JAX-EPD0389_3_B05-1", "JAX-EPD0539_5_F01-1", "JAX-EPD0852_3_D01-1", "JAX-18644A-B10-1", "JAX-10869A-A2-1", "JAX-14897A-F12-1", "JAX-EPD0815_3_G11-1", "JAX-EPD0267_4_C09-1", "JAX-15413A-A12-1", "JAX-HEPD0759_7_H11-1", "JAX-EPD0390_1_E02-1", "JAX-EPD0101_5_B03-1", "JAX-HEPD0666_1_D01-1", "JAX-EPD0107_5_F04-1", "JR21342(PH)", "JAX-EPD0719_1_E12-1", "JAX-EPD0731_3_F01-1", "JAX-17478A-C8-1", "JAX-EPD0317_6_H07-1", "JAX-12297A-G5-1", "JAX-EPD0806_6_A02-1", "JAX-13756A-E1-2", "JAX-EPD0241_2_A07-1", "JR19498 (PH)", "JAX-EPD0399_1_C12-1", "JAX-19191A-A1-1", "JAX-12890A-H11-2", "JAX-EPD0334_4_H02-1", "JAX-HEPD0637_7_H01-1", "JAX-JKOMP47947-1F2-1", "JAX-HEPD0515_2_B06-1", "JAX-15888A-C1-1", "JAX-DEPD00539_8_F12-1", "JAX-11246A-H7-2", "JAX-HEPD0733_5_F03-1", "JAX-14779A-E2-1", "JAX-EPD0208_2_A04-1", "JAX-13150A-G6-1", "JAX-10152A-A5-1", "JAX-HEPD0760_8_D04-1", "JAX-EPD0205_2_A04-2", "JAX-12112A-A9-1", "JAX-EPD0151_6_C04-2", "JAX-13772A-E3-1", "JAX-EPD0903_5_B01-1", "JAX-EPD0394_4_A01-1", "JAX-EPD0503_3_D09-1", "JAX-EPD0528_5_A08-1", "JAX-11974A-H1-1", "JAX-10977A-E9-1", "JAX-EPD0527_3_D03-1", "JAX-10610A-F3-1", "JAX-18681A-E12-1", "JAX-11486A-F2-2", "JAX-13782A-H5-1", "JAX-DEPD00534_4_G01-2", "JAX-EPD0395_5_A02-1", "JAX-15989A-E12-1", "JAX-11383A-F1-1", "JAX-11836A-B1-1", "JAX-11204A-E2-2", "JAX-15981A-G3-1", "JAX-11056B-B3-1", "JAX-EPD0663_2_B04-1", "JAX-12921A-H2-1", "JAX-12927A-B11-1", "JAX-18995A-G10-2", "JAX-13813A-H4-1", "JAX-HEPD0534_5_E11-1", "JAX-14965A-E4-1", "JAX-10153A-B6-1", "JR17781(PH)", "JAX-14720A-C12-1", "JAX-HEPD0769_4_E07-1", "JAX-EPD0425_6_F05-1", "JAX-EPD0706_4_A09-2", "JAX-EPD0052_5_G08-1", "JAX-DEPD00513_4_C01-1", "JAX-DEPD00513_4_D01-1", "JAX-EPD0442_1_H11-1", "JAX-EPD0107_2_B05-1", "JAX-HEPD0688_6_D11-1", "JAX-DEPD00540_3_A05-1", "JAX-EPD0309_4_A07-1", "JAX-19803A-B11-1", "JAX-EPD0570_3_F06-1", "JAX-11777A-C8-1", "JAX-EPD0652_2_E11-1", "JAX-DEPD00548_3_A09-1", "JAX-13834A-A6-1", "JAX-15005A-H9-1", "JAX-EPD0090_1_B07-1", "JAX-DEPD00519_2_F12-1", "JAX-15032A-F5-1", "JAX-13759A-A4-1", "JAX-EPD0860_2_D04-1", "JAX-EPD0304_3_G01-1", "JAX-13078A-B4-1", "JAX-16694B-G5-1", "JAX-12045A-A7-1", "JAX-19020A-H7-1", "JAX-14409A-C2-2 JR27104", "JAX-15552A-B8-1", "JAX-DEPD00505_6_B03-1", "JAX-12788B-C6-1", "JAX-EPD0612_2_C09-1", "JAX-EPD0234_6_C05-2", "JR24810", "JAX-14363A-E1-1", "JAX-EPD0923_1_G10-1", "JAX-17512A-B7-1", "JAX-10995B-E6-2", "JAX-12470A-H9-1", "JAX-11507A-B3-1", "JAX-11464A-C4-1", "JAX-EPD0346_5_B07-1", "JAX-DEPD00539_9_E02-1", "JAX-19023A-F10-1", "JAX-EPD0575_2_B02-1", "JAX-13862A-E11-1", "JAX-EPD0505_4_B10-1", "JAX-19027A-C5-1", "JAX-HEPD0705_5_H05-1", "JAX-HEPD0833_1_G03-1", "JAX-17516A-H1-1", "JAX-13867A-D12-1", "JAX-EPD0896_1_H01-1", "JAX-EPD0897_2_G08-1", "JAX-EPD0771_3_F02-1", "JAX-HEPD0837_2_B04-1", "JAX-EPD0550_1_B09-1", "JAX-EPD0025_3_F02-1", "JAX-EPD0085_2_H10-1", "JAX-11147A-A9-1", "JAX-EPD0697_2_A11-1", "JAX-18654A-F5-1", "JAX-HEPD0510_5_H11-1", "JAX-HEPD0747_6_B06-1", "JAX-EPD0393_2_C09-1", "JAX-16142A-G2-1", "JAX-11560A-D8-1", "JAX-13871A-D1-1", "JAX-EPD0152_1_C02-1", "JAX-16914A-G8-1", "JAX-10577A-A12-1", "JAX-HEPD0601_5_E07-1", "JAX-HEPD0678_1_D08-1", "JAX-14446B-C4-1", "JAX-EPD0700_3_A11-1", "JAX-EPD0735_3_B11-1", "JAX-13057A-C1-2", "JAX-15477A-E6-1", "JAX-EPD0825_3_E12-1", "JAX-EPD0204_5_A03-2", "JAX-11443B-B7-1", "JAX-DEPD00577_4_D04-1", "JAX-16754A-H4-1", "JAX-EPD0035_1_C02-1", "JAX-17200A-E2-2", "JAX-19201A-H12-1", "JAX-HEPD0682_8_H05-1", "JAX-EPD0346_3_A03-1", "JAX-16057B-G8-1", "JAX-15653B-B5-1", "JAX-10468A-B5-1", "JAX-17207A-B5-2", "JAX-EPD0728_4_E11-1", "JAX-EPD0479_2_H11-1", "JAX-EPD0850_2_B03-2", "JAX-DEPD00562_2_B07-1", "JAX-EPD0391_7_D08-1", "JAX-EPD0739_5_C02-2", "JAX-10209A-A10-2", "JAX-19742A-F7-1", "JAX-HEPD0718_2_C10-1", "JAX-EPD0282_6_A12-1", "JAX-13907A-C10-1", "JAX-EPD0033_2_C05-1", "JAX-HEPD0524_2_A08-1", "JAX-DEPD00525_3_F11-1", "JAX-13234A-G2-1", "JAX-17289A-B9-1", "JAX-12652A-F5-1", "JAX-EPD0938_2_C02-1", "JAX-13400A-E12-1", "JAX-13142A-H7-1", "JAX-12597A-C7-1", "JAX-16072A-D12-1", "JAX-13927A-D11-1", "JAX-17697A-A5-1", "JAX-EPD0391_2_A06-1", "JAX-EPD0901_4_A08-1", "17828(PH)", "JAX-EPD0411_3_B02-1", "JAX-EPD0391_5_A05-1", "JAX-DEPD00564_2_D02-1", "JAX-HEPD0674_1_E02-1", "JAX-DEPD00562_5_D12-1", "JAX-13522A-A2-1", "JAX-HEPD0653_1_F04-1", "JAX-HEPD0611_4_F08-1", "JAX-EPD0927_2_E02-1", "JAX-EPD0514_1_B09-1", "JAX-HEPD0753_3_G03-1", "JAX-DEPD00552_2_G06-1", "JAX-15335A-A7-1", "JAX-17706A-A11-1", "JAX-DEPD00532_2_D02-1", "JAX-16234C-E2-1", "JAX-19163A-F2-1", "JAX-EPD0867_6_E11-1", "JAX-15774A-H6-1", "JAX-DEPD00575_1_A05-1", "JAX-13992A-G2-1", "JAX-EPD0271_5_H05-1", "JAX-13947A-C4-1", "JAX-DEPD00519_2_C05-1", "JAX-12268A-E10-1", "JAX-DEPD00518_2_H05-1", "JAX-13169A-A4-1", "JAX-EPD0748_5_A03-2", "JAX-13960A-E11-1", "JAX-18132A-C2-1", "JAX-EPD0867_4_G04-1", "JAX-DEPD00524_3_E01-1", "JAX-DEPD00525_1_E02-1", "JAX-19082A-B5-1", "JAX-DEPD00546_3_A09-1", "JAX-10680C-D1-1", "JAX-18077A-E5-1", "JAX-18561B-G9-1"]

current_time = Time.now

colony_names.each do |name|
  c = Colony.find_by_name(name)
  distribution_centres = c.distribution_centres
  distribution_centres.each do |d|
  	if !d.start_date
  	  d.start_date = current_time
    end
    d.end_date = current_time
    d.available = false
    d.save!
    c.save!
  end
end





###############################################################
### JAX colonies distributed by MMRRC - UCD => frozen sperm ###
###############################################################


colony_names_2 = ["jr28994", "JR24901", "JR26508", "JR24333", "JR26509", "jr29792", "JR26878", "JR24041", "JR24325", "JR28179", "jr27607", "JR24980", "jr27606", "jr29793", "JR23411", "jr28514", "JR28180", "jr29742", "JR25116", "jr29340", "jr29110", "JR24902", "JR24654", "jr29949", "JR24655", "JR25861", "JR27560", "jr29499", "jr25814", "jr25475", "JR26865", "jr29133", "jr29158", "jr29743", "JR22334", "JR24518", "JR25175", "JR27811", "jr27694", "JR26616", "JR27807", "JR26987", "JR18592", "JR24154", "JR18561", "jr29805", "JR23421", "JR23512", "JR25117", "JR24334", "JR24896", "JR26984", "JR28467", "JR24331", "JR27551", "JR24656", "jr29975", "jr29109", "jr29341", "jr29360", "JR27623", "JR26168", "jr29383", "JR21510", "jr26839", "JR27383", "JR26614", "jr27814", "JR24425", "jr28869", "jr28321", "jr29913", "jr29362", "JR22304", "JR18569", "JR26671", "jr28310", "JR22420", "JR18608", "JR18607", "JR18657", "JR18660", "jr29002", "JR22101", "jr29829", "JR28182", "JR21925", "JR22305", "jr29785", "JR24352", "JR22087", "JR26867", "JR24037", "JR24661", "JR24979", "jr28870", "JR24424", "JR24183", "JR27808", "JR24515", "JR27550", "JR25851", "JR22818", "jr26236", "JR28183", "JR28178", "JR24348", "JR21751", "jr29135", "JR18653", "JR22307", "JR22013", "jr29409", "JR18562", "JR22098", "JR22779", "jr29726", "JR22783", "JR22418", "JR26843", "JR23283", "JR24516", "JR23393", "JR25864", "JR18556", "JR18591", "jr29569", "JR27040", "jr28995", "jr29816", "jr27608", "JR24349", "JR22016", "JR24040", "JR27558", "JR18590", "JR24569", "jr29552", "jr30089", "JR25275", "JR25179", "JR24657", "JR23307", "jr26911", "JR28185", "jr29561", "jr28319", "JR22335", "JR18836", "JR28285", "jr29830", "JR24155", "JR27209", "jr29560", "JR22819", "JR24189", "JR21512", "JR24092", "JR24279", "JR18603", "jr26956", "JR25118", "JR27896", "JR23317", "JR18631", "JR18587", "JR27239", "JR24042", "jr27697", "JR23666", "JR27554", "JR28187", "jr29216", "jr30244", "JR24658", "JR28188", "JR22337", "JR24978", "jr29146", "JR28189", "JR27810", "jr29207", "JR18604", "JR25318", "JR27653", "JR21449", "JR21485", "JR25480", "JR27655", "JR22343", "jr29209", "JR24332", "JR26986", "JR22015", "jr29814", "JR22014", "jr28988", "JR22344", "jr29557", "jr29372", "JR22096", "JR24035", "JR26498", "JR27208", "JR26288", "JR24659", "JR24353", "jr28996", "JR22777", "JR21507", "jr27202", "JR26669", "JR24117", "JR23604", "jr29000", "jr25817", "JR27895", "JR25514", "jr28873", "JR24346", "JR22342", "JR25186", "JR18584", "jr29551", "JR18565", "JR24570", "JR27515", "JR18585", "JR22776", "JR18597", "jr29918", "JR18632", "JR18580", "JR18637", "JR18633", "JR18636", "JR28638", "JR18616", "JR22416", "JR22340", "jr27092", "JR18838", "JR23605", "JR27219", "jr26122", "jr29804", "jr26820", "JR25584", "jr29527", "jr28322", "JR27942", "JR28126", "JR28194", "jr29016", "JR26533", "jr27692", "JR25261", "JR26541", "JR18659", "jr29004", "JR27207", "JR25119", "JR25191", "JR26535", "JR26437", "JR27564", "jr26034", "JR22339", "JR27622", "PH21753", "JR24672", "JR25180", "jr33920", "JR23489", "JR24660", "JR26615", "jr25733", "JR18622", "JR25575", "jr29550", "jr29488", "JR27467", "JR18705", "JR24653", "JR26611", "JR22011", "JR27908", "jr26913", "JR26601", "jr30192", "JR25183", "JR26024", "JR27241", "JR24326", "jr29208", "JR26421", "JR27518", "JR26510", "JR26851", "JR25265", "jr29555", "JR26928", "JR22097", "JR26490", "JR26917", "jr29217", "jr29800", "jr25732", "jr29750", "jr27693", "jr29611", "JR27240", "JR21486", "JR19459", "JR18595", "JR24028", "JR26292", "JR18643", "JR25266", "JR28195", "UCD-10916A-F3-1-1", "JR27552", "JR28211", "JR24058", "JR26633", "JR26495", "JR18554", "JR26065", "jr27658", "JR26422", "JR26443", "JR26546", "JR26837", "JR27621", "JR26544", "jr29210", "JR26530", "JR26491", "JR18594", "jr29001", "JR27988", "JR24023", "JR24977", "JR18844", "JR27295", "JR24946", "JR25319", "JR25579", "JR24947", "JR27809", "JR27221", "JR26545", "jr28871", "jr28893", "JR25380", "JR25638", "JR18582", "JR24981", "JR21902", "JR19073", "JR22782", "JR18619", "JR18618", "JR18617", "JR18634", "JR24347", "JR24269", "JR18615", "JR23282", "JR25264", "jr29240", "JR26171", "JR25270", "JR27559", "JR23606", "JR27746", "JR21516", "JR22303", "JR27517", "JR22005", "JR22388", "JR26636", "JR26289", "JR27652", "JR26613", "JR26600", "JR24571", "jr29136", "jr26272", "JR24289", "jr29801", "JR18655", "jr29336", "JR25513", "JR26172", "JR23813", "JR24055", "JR22093", "JR26066", "jr29562", "JR22821", "JR26543", "jr27659", "jr28540", "jr27443", "JR21140", "jr29523", "JR27555", "jr29556", "JR23603", "JR27557", "JR22085", "JR26720", "JR27522", "JR26830", "JR28455", "jr29268", "JR25381", "jr27444", "JR25320", "JR23318", "jr25927", "jr27793", "JR25383", "jr29496", "JR28456", "jr29245", "JR26023", "JR26617", "jr29396", "JR22302", "JR25583", "JR26507", "JR25518", "JR26596", "JR25276", "jr29267", "JR18563", "JR27468", "JR26506", "JR22094", "JR27380", "JR25847", "JR22778", "JR23021", "JR27897", "JR26929", "JR18570", "JR25187", "JR27381", "JR26536", "JR24759", "JR26670", "JR26602", "jr29126", "JR25386", "JR23024", "JR25188", "jr29244", "JR22100", "jr27272", "JR25387", "JR26290", "JR25852", "JR25271", "JR28457", "JR25516", "JR25185", "JR26881", "JR22092", "jr27696", "JR26594", "JR23420", "jr25734", "jr29613", "jr28912", "JR27657", "JR26537", "JR24056", "JR28460", "JR26032", "jr27695", "jr27691", "JR24942", "JR27987", "JR28461", "JR28462", "JR18635", "JR26496", "JR18808", "JR24026", "JR25577", "jr33919", "jr29384", "JR26598", "jr25812", "JR25268", "jr33924", "jr29337", "JR26985", "JR26499", "JR25574", "JR24673", "jr27474", "JR21488", "jr28352", "jr29628", "JR23599", "JR18586", "JR18575", "jr25292", "jr29610", "jr25810", "JR27025", "jr28876", "JR28463", "jr28968", "JR18577", "jr28972", "JR25580", "JR26500", "JR27520", "JR18697", "JR24185", "JR25572", "JR26599", "JR24897", "jr29629", "JR25862", "JR25177", "JR18638", "JR28468", "JR26538", "JR25581", "JR26722", "jr25680", "JR18645", "JR24945", "JR26440", "JR18646", "JR27519", "JR24899", "JR25582", "JR26864", "jr27610", "JR28469", "JR24233", "jr26838", "jr26954", "jr29148", "JR18707", "JR25845", "jr28971", "JR26607", "jr27477", "JR24036", "jr26953", "jr29634", "JR22338", "jr28990", "JR26630", "JR23663", "jr29008", "JR25263", "jr29329", "JR22095", "jr31420", "JR25391", "JR25182", "JR25181", "JR21613", "JR23058", "JR28811", "JR26441", "jr29147", "JR23412", "jr27794", "jr26914", "JR26672", "JR26539", "JR26026", "jr28969", "JR18355", "JR22341", "jr29570", "JR26173", "jr28998", "JR25639", "jr32124", "JR25863", "JR25392", "JR23601", "jr27471", "JR18614", "JR26504", "JR23815", "JR22306", "JR25589", "JR25388", "jr33923", "JR26436", "jr27816", "JR26028", "jr26274", "JR24330", "JR26915", "JR26604", "JR26597", "JR23306", "JR24186", "JR26287", "JR26027", "JR25860", "JR18609", "JR26540", "JR22099", "JR21509", "jr27203", "JR28350", "JR28471", "jr27813", "JR18568", "JR18576", "jr29395", "JR18641", "JR28472", "jr29276", "JR26832", "JR27986", "JR28464", "JR24025", "JR27812", "JR27464", "JR28473", "JR24022", "JR26919", "JR26501", "JR26291", "JR28454", "JR23667", "JR26502", "JR26603", "jr29635", "jr28992", "jr27568", "JR26612", "jr28989", "JR24187", "jr29278", "JR22389", "JR23422", "JR24188", "JR23664", "JR23801", "JR27026", "JR24940", "JR23394", "jr29636", "JR24093", "JR23059", "jr29731", "JR22387", "jr28993", "JR26882", "JR26494", "JR22102", "JR25176", "jr30181", "jr29006", "JR25590", "JR26916", "JR25120", "JR23423", "jr29280", "JR27989", "JR28646", "jr29522", "JR26610", "JR25587", "JR25849", "jr29030", "jr33901", "JR18578", "JR27556", "JR28477", "JR18572", "JR26817", "JR26025", "JR23072", "jr29029", "JR22345", "JR25578", "JR26424", "JR24674", "JR25390", "JR26608", "JR21750", "JR22346", "JR25866", "JR21141", "jr29007", "JR21511", "jr27327", "JR26442", "JR26488", "JR25591", "JR25262", "JR26487", "JR18691", "jr29688", "jr29658", "JR26493", "JR23419", "jr29039", "JR25640", "JR28644", "JR24652", "JR28478", "JR26635", "jr29009", "jr27689", "JR25588", "jr32841", "JR26721", "jr29729", "JR28645", "JR28479", "JR25573", "jr28970", "JR26174", "JR26067", "jr29125", "jr29005", "JR23136", "JR28474", "jr28354", "jr30088", "JR27743", "jr29659", "jr27570", "jr27571", "jr25816", "JR28793", "JR25585", "jr29526", "JR27566", "JR18664", "JR21482", "JR28013", "JR26920", "JR27744", "JR24038", "jr29335", "JR21142", "jr29612", "JR25641", "JR23511", "JR28480", "JR24411", "JR18557", "JR24675", "JR23414", "jr29631", "JR28481", "JR27465", "jr29751", "JR25576", "JR25376", "JR28475", "JR26503", "jr27572", "JR22301", "JR24409", "jr26242", "jr29338", "jr27253", "JR24350", "jr29495", "JR25382", "JR26233", "JR27907", "JR26918", "JR22780", "JR23020", "JR26927", "jr33931", "JR26485", "JR26673", "JR26634", "JR25515", "JR28650", "jr27573", "JR25378", "jr28323", "JR26637", "JR26068", "JR18820", "JR23424", "JR26031", "JR24184", "JR25385", "jr29324", "jr29404", "jr29157", "JR21115", "JR24351", "JR28125", "JR27941", "JR26638", "jr28999", "JR18611", "JR26631", "jr26819", "JR26668", "JR27242", "JR27654", "JR18693", "JR22781", "JR24410", "JR25865", "JR28351", "JR24517", "JR27625", "JR23814", "JR26719", "JR26674", "JR22784", "JR23665", "JR27243", "JR26423", "JR26609", "jr33921", "jr29630", "jr29728", "JR26232", "jr28894", "JR27656", "JR21591", "jr29327", "JR24039", "jr29487", "JR26605", "JR28651", "jr29113", "JR25571", "jr29112", "JR26029", "JR25848", "JR21839", "JR27218", "JR28465", "JR24406", "JR18639", "JR28601", "JR27297", "jr29140", "jr27200", "JR27222", "JR28602", "JR28603", "JR28604", "jr29815", "JR18629", "JR27565", "JR23060", "JR25846", "JR27516", "JR26484", "jr29854", "jr29502", "JR24939", "JR28813", "JR26438", "JR27523", "jr29733", "JR26483", "JR26831", "jr29159", "jr29277", "JR23812", "JR28014", "JR26845", "JR26542", "jr29003", "JR21752", "JR24900", "JR26606", "JR18606", "jr29326", "JR18553", "jr27094", "JR28466", "JR26534", "JR21483", "JR26169", "jr33912", "jr29111", "jr26909", "JR25517", "jr33917", "jr29406", "jr29727", "JR26532", "jr29689", "jr29494", "jr27611", "JR27325", "JR23839", "JR22817", "JR24027", "JR22419", "jr27475", "jr28868", "JR27567", "JR22820", "JR24944", "JR24407", "JR26170", "JR27745", "jr27612", "JR24408", "JR23019", "jr28515", "JR21936", "jr29334", "JR18573", "jr27613", "JR27466", "JR25389", "jr29405", "jr33925", "jr29571", "JR28641", "jr25926", "JR27472", "jr31164", "jr29160", "JR28642", "JR24345", "JR24324", "JR27624", "JR26489", "JR23602", "JR23660", "JR26866", "jr29916", "JR18620", "JR26486", "jr28355", "jr26910", "jr28450", "JR28643", "JR24091", "JR27382", "JR23023", "jr28308", "jr29279", "jr28516", "JR27238", "jr29529", "jr28358", "JR26069", "jr29320", "jr29917", "JR24057", "jr29134", "jr26273", "jr33918", "JR18593", "jr29325", "JR25267", "jr28872", "JR22366"]

centre = Centre.find_by_name('UCD')
m = DepositedMaterial.find_by_name('Frozen sperm')


colony_names_2.each do |name|
  c = Colony.find_by_name(name)
  distribution_centres = c.distribution_centres
  distribution_centres.each do |d|
  d.centre_id = centre.id
  d.deposited_material_id = m.id
  d.distribution_network = 'MMRRC'
  d.save!
  c.save!
  end
end











