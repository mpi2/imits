#!/usr/bin/env ruby

# script to remove unwanted mi_attempts inserted in error by UCD-KOMP

class String
  # colorize functions
  # see http://blog.sosedoff.com/2010/06/01/making-colorized-console-output-with-ruby/
  def red; colorize(self, "\e[1m\e[31m"); end
  def green; colorize(self, "\e[1m\e[32m"); end
  def dark_green; colorize(self, "\e[32m"); end
  def yellow; colorize(self, "\e[1m\e[33m"); end
  def blue; colorize(self, "\e[1m\e[34m"); end
  def dark_blue; colorize(self, "\e[34m"); end
  def pur; colorize(self, "\e[1m\e[35m"); end
  def colorize(text, color_code) "#{color_code}#{text}\e[0m" ; end
end

list = [
  { :id => 5256, :mgi => 'EPD0013_1_C02' },
  { :id => 5257, :mgi => 'EPD0018_1_D08' },
  { :id => 5258, :mgi => 'EPD0018_2_D02' },
  { :id => 5259, :mgi => 'EPD0018_2_C08' },
  { :id => 5260, :mgi => 'EPD0026_1_H08' },
  { :id => 5261, :mgi => 'EPD0026_1_C12' },
  { :id => 5262, :mgi => 'EPD0026_4_C08' },
  { :id => 5263, :mgi => 'EPD0026_5_G02' },
  { :id => 5264, :mgi => 'EPD0025_1_A04' },
  { :id => 5265, :mgi => 'EPD0025_2_F01' },
  { :id => 5266, :mgi => 'EPD0025_2_A04' },
  { :id => 5267, :mgi => 'EPD0025_2_A10' },
  { :id => 5268, :mgi => 'EPD0025_3_C05' },
  { :id => 5269, :mgi => 'EPD0025_3_C07' },
  { :id => 5270, :mgi => 'EPD0025_4_B07' },
  { :id => 5271, :mgi => 'EPD0025_5_A08' },
  { :id => 5272, :mgi => 'EPD0017_2_C11' },
  { :id => 5273, :mgi => 'EPD0017_3_A07' },
  { :id => 5274, :mgi => 'EPD0019_1_A05' },
  { :id => 5275, :mgi => 'EPD0029_1_G04' },
  { :id => 5276, :mgi => 'EPD0029_4_F01' },
  { :id => 5277, :mgi => 'EPD0029_4_E08' },
  { :id => 5278, :mgi => 'EPD0032_2_H06' },
  { :id => 5279, :mgi => 'EPD0031_1_G01' },
  { :id => 5280, :mgi => 'EPD0031_1_H07' },
  { :id => 5281, :mgi => 'EPD0033_1_E01' },
  { :id => 5282, :mgi => 'EPD0033_1_E05' },
  { :id => 5283, :mgi => 'EPD0033_1_D06' },
  { :id => 5284, :mgi => 'EPD0033_1_C08' },
  { :id => 5285, :mgi => 'EPD0033_1_F12' },
  { :id => 5286, :mgi => 'EPD0033_3_A02' },
  { :id => 5287, :mgi => 'EPD0033_3_F04' },
  { :id => 5288, :mgi => 'EPD0033_3_D07' },
  { :id => 5289, :mgi => 'EPD0033_3_C09' },
  { :id => 5290, :mgi => 'EPD0033_3_C11' },
  { :id => 5291, :mgi => 'EPD0033_4_D01' },
  { :id => 5292, :mgi => 'EPD0033_4_C03' },
  { :id => 5293, :mgi => 'EPD0033_4_F05' },
  { :id => 5294, :mgi => 'EPD0033_4_C09' },
  { :id => 5295, :mgi => 'EPD0034_4_C03' },
  { :id => 5296, :mgi => 'EPD0033_5_D02' },
  { :id => 5297, :mgi => 'EPD0033_5_E04' },
  { :id => 5298, :mgi => 'EPD0033_5_A07' },
  { :id => 5299, :mgi => 'EPD0033_2_B02' },
  { :id => 5300, :mgi => 'EPD0033_2_D07' },
  { :id => 5344, :mgi => 'EPD0019_1_A05' },
  { :id => 5345, :mgi => 'EPD0022_2_D02' },
  { :id => 5346, :mgi => 'EPD0023_3_A02' },
  { :id => 5347, :mgi => 'EPD0028_1_F01' },
  { :id => 5348, :mgi => 'EPD0041_1_F06' },
  { :id => 5349, :mgi => 'EPD0042_1_A05' },
  { :id => 5350, :mgi => 'EPD0043_3_B02' },
  { :id => 5351, :mgi => 'EPD0044_5_B04' },
  { :id => 5352, :mgi => 'EPD0048_1_E02' },
  { :id => 5359, :mgi => 'EPD0064_1_G02' },
  { :id => 5360, :mgi => 'EPD0064_2_C12' },
  { :id => 5361, :mgi => 'EPD0064_2_D04' },
  { :id => 5362, :mgi => 'EPD0064_2_H09' },
  { :id => 5363, :mgi => 'EPD0068_1_B03' },
  { :id => 5364, :mgi => 'EPD0068_1_H05' },
  { :id => 5365, :mgi => 'EPD0071_1_D03' },
  { :id => 5366, :mgi => 'EPD0071_3_H09' },
  { :id => 5367, :mgi => 'EPD0023_2_F10' },
  { :id => 5368, :mgi => 'EPD0085_6_H01' },
  { :id => 5369, :mgi => 'EPD0085_6_H06' },
  { :id => 5370, :mgi => 'EPD0085_1_C10' },
  { :id => 5371, :mgi => 'EPD0085_1_D04' },
  { :id => 5372, :mgi => 'EPD0079_1_A10' },
  { :id => 5373, :mgi => 'EPD0079_5_E10' },
  { :id => 5374, :mgi => 'EPD0079_5_G07' },
  { :id => 5375, :mgi => 'EPD0082_5_A09' },
  { :id => 5377, :mgi => 'EPD0085_2_F07' },
  { :id => 5378, :mgi => 'EPD0081_6_C05' },
  { :id => 5379, :mgi => 'EPD0081_6_E02' },
  { :id => 5380, :mgi => 'EPD0086_2_F11' },
  { :id => 5381, :mgi => 'EPD0081_4_A11' },
  { :id => 5382, :mgi => 'EPD0079_6_H08' },
  { :id => 5383, :mgi => 'EPD0078_2_C07' },
  { :id => 5384, :mgi => 'EPD0082_2_G11' },
  { :id => 5385, :mgi => 'EPD0079_4_E02' },
  { :id => 5386, :mgi => 'EPD0081_5_C11' },
  { :id => 5387, :mgi => 'EPD0081_5_E07' },
  { :id => 5388, :mgi => 'EPD0083_2_C05' },
  { :id => 5389, :mgi => 'EPD0083_2_E03' },
  { :id => 5390, :mgi => 'EPD0050_2_B11' },
  { :id => 5391, :mgi => 'EPD0090_5_B04' },
  { :id => 5392, :mgi => 'EPD0075_1_B10' },
  { :id => 5393, :mgi => 'EPD0084_1_B08' },
  { :id => 5394, :mgi => 'EPD0084_1_C03' },
  { :id => 5395, :mgi => 'EPD0090_4_A04' },
  { :id => 5396, :mgi => 'EPD0090_4_H11' },
  { :id => 5397, :mgi => 'EPD0050_1_E07' },
  { :id => 5405, :mgi => 'EPD0107_4_E05' },
  { :id => 5406, :mgi => 'EPD0106_3_D09' },
  { :id => 5407, :mgi => 'EPD0106_2_B05' },
  { :id => 5408, :mgi => 'EPD0110_1_E10' },
  { :id => 5409, :mgi => 'EPD0109_6_F01' },
  { :id => 5410, :mgi => 'EPD0109_3_E07' },
  { :id => 5412, :mgi => 'EPD0125_1_E10' },
  { :id => 5414, :mgi => 'EPD0133_4_C12' },
  { :id => 5415, :mgi => 'EPD0135_1_A05' },
  { :id => 5416, :mgi => 'EPD0135_3_B03' },
  { :id => 5417, :mgi => 'EPD0136_3_G02' },
  { :id => 5425, :mgi => 'EPD0132_5_A03' },
  { :id => 5426, :mgi => 'EPD0132_5_C11' },
  { :id => 5427, :mgi => 'EPD0150_1_D07' },
  { :id => 5428, :mgi => 'EPD0150_2_B12' },
  { :id => 5429, :mgi => 'EPD0164_3_G07' },
  { :id => 5430, :mgi => 'EPD0164_3_H04' },
  { :id => 5431, :mgi => 'EPD0164_6_A02' },
  { :id => 5432, :mgi => 'EPD0151_3_G04' },
  { :id => 5434, :mgi => 'EPD0101_4_E03' },
  { :id => 5435, :mgi => 'EPD0101_4_F09' },
  { :id => 5436, :mgi => 'EPD0056_1_A10' },
  { :id => 5437, :mgi => 'EPD0056_1_B09' },
  { :id => 5438, :mgi => 'EPD0098_5_H10' },
  { :id => 5439, :mgi => 'EPD0097_2_E01' },
  { :id => 5440, :mgi => 'EPD0097_3_B06' },
  { :id => 5441, :mgi => 'EPD0097_1_C09' },
  { :id => 5442, :mgi => 'EPD0097_1_D01' },
  { :id => 5443, :mgi => 'EPD0099_3_G04' },
  { :id => 5444, :mgi => 'EPD0099_4_D09' },
  { :id => 5445, :mgi => 'EPD0099_4_B07' },
  { :id => 5446, :mgi => 'EPD0099_2_E04' },
  { :id => 5447, :mgi => 'EPD0099_1_B03' },
  { :id => 5448, :mgi => 'EPD0096_1_A05' },
  { :id => 5449, :mgi => 'EPD0094_4_B01' },
  { :id => 5450, :mgi => 'EPD0093_2_B04' },
  { :id => 5451, :mgi => 'EPD0162_1_G07' },
  { :id => 5452, :mgi => 'EPD0166_6_C04' },
  { :id => 5453, :mgi => 'EPD0168_1_D04' },
  { :id => 5461, :mgi => 'EPD0167_3_F08' },
  { :id => 5466, :mgi => 'EPD0199_3_B01' },
  { :id => 5467, :mgi => 'EPD0211_3_A05' },
  { :id => 5494, :mgi => 'EPD0276_1_G04' },
  { :id => 5495, :mgi => 'EPD0272_2_D07' },
  { :id => 5504, :mgi => 'EPD0287_1_C05' },
  { :id => 5506, :mgi => 'EPD0300_3_C05' },
  { :id => 5507, :mgi => 'EPD0296_2_A10' },
  { :id => 5508, :mgi => 'EPD0296_3_C07' },
  { :id => 5509, :mgi => 'EPD0312_4_B10' },
  { :id => 5514, :mgi => 'EPD0319_2_E12' },
  { :id => 5523, :mgi => 'EPD0076_1_F07' },
  { :id => 5524, :mgi => 'EPD0095_1_A11' },
  { :id => 5528, :mgi => 'EPD0392_6_E12' },
  { :id => 5530, :mgi => 'EPD0406_1_H11' },
  { :id => 5531, :mgi => 'EPD0287_1_A02' },
  { :id => 5532, :mgi => 'EPD0413_2_A01' },
  { :id => 5533, :mgi => 'EPD0412_2_C09' },
  { :id => 5544, :mgi => 'EPD0468_4_B11' },
  { :id => 5555, :mgi => 'EPD0538_1_D06' },
  { :id => 5563, :mgi => 'EPD0553_2_A09' },
  { :id => 5564, :mgi => 'EPD0553_3_A01' },
  { :id => 5565, :mgi => 'EPD0553_3_A07' },
  { :id => 5566, :mgi => 'EPD0552_1_A11' },
  { :id => 5567, :mgi => 'EPD0555_2_B11' }
]

#The Mis with these ids should be:
#1) checked to have the appropriate ES-cell name, and they must be checked to belong to the UCD-KOMP consortium
#2) Deleted (along with status stamps)

DEBUG = true
RECORD_COUNT = 156
BLAT = true

if list.length != RECORD_COUNT
  warn "Found #{list.length} when expecting RECORD_COUNT".red
  exit
end

puts "Count: #{list.length}".green if DEBUG

MiAttempt.audited_transaction do

  count_start = MiAttempt.count

  list.each do |item|
    mi_attempt = MiAttempt.find_by_id item[:id]

    if ! mi_attempt
      warn "Cannot find #{item[:id]}".red
      next
    end

    puts "id: #{item[:id]} - mgi: #{item[:mgi]} - consortium: #{mi_attempt.consortium_name}".green if DEBUG

    if ! mi_attempt.es_cell_name || mi_attempt.es_cell_name != item[:mgi]
      warn "Expected '#{item[:mgi]}' - Found '#{mi_attempt.es_cell_name}'".red
      next
    end

    if ! mi_attempt.consortium_name || mi_attempt.consortium_name != 'UCD-KOMP'
      warn "Expected 'UCD-KOMP' - Found '#{mi_attempt.consortium_name}'".red
      next
    end

    stamp_ids = mi_attempt.status_stamps.map(&:id)

    puts "status stamps: #{stamp_ids.inspect}".blue if DEBUG

    # ok to blat

    mi_plan = mi_attempt.mi_plan
    mi_attempt_id = mi_attempt.id

    if mi_plan.mi_attempts.length == 1
      #puts mi_plan.mi_attempts.inspect if DEBUG
      raise "Illegal id detected - expected #{mi_attempt_id} - found: #{mi_plan.mi_attempts[0].id}".red if mi_plan.mi_attempts[0].id != mi_attempt_id
      #puts "mi_plan.mi_attempts.length: #{mi_plan.mi_attempts.length.inspect}".blue if DEBUG
      mi_attempt.status_stamps.destroy_all if BLAT
      mi_attempt.destroy if BLAT
      mi_plan.status_stamps.destroy_all if BLAT
      mi_plan.destroy if BLAT
    else
      mi_attempt.status_stamps.destroy_all if BLAT
      mi_attempt.destroy if BLAT
    end

  end

  count_end = MiAttempt.count

  # final sanity checks
  if count_start-count_end != RECORD_COUNT
    raise "Record count error: expected #{RECORD_COUNT} - found #{count_start-count_end}".red
  end

  exit  #######################

end

puts "done!".green
