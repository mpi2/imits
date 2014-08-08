class ColonyController < ApplicationController
  def show
    @id = params[:id]
    debug = true

    return if ! @id

    @colony = Colony.find_by_id @id

    @files = {}

    return if @colony.nil?

    @title = "Colony #{@colony.name} (#{@colony.trace_file_file_name})"

    show = true

    @files[:alignment] = {:filename => 'alignment.txt', :name => 'Alignment', :data => nil, :show => show}
    @files[:filtered_analysis_vcf] = {:filename => 'filtered_analysis.vcf', :name => 'filtered_analysis_vcf', :data => nil, :show => show}
    @files[:vep_log] = {:filename => 'vep.log', :name => 'vep_log', :data => nil, :show => show}
    @files[:mutant_fa] = {:filename => 'mutated.fa', :name => 'mutated_fa', :data => nil, :show => show}
    @files[:read_seq_fa] = {:filename => 'read_seq.fa', :name => 'read_seq_fa', :data => nil, :show => show}
    @files[:variant_effect_output_txt] = {:filename => 'variant_effect_output.txt', :name => 'variant_effect_output.txt', :data => nil, :show => show}
    @files[:analysis_pileup] = {:filename => 'analysis.pileup', :name => 'analysis.pileup', :data => nil, :show => true}

    if params[:filename]
      key = params[:filename].to_sym
      if @files.has_key? key
        send_file "#{Rails.root}/public/trace_files/#{@id}/#{@files[key][:filename]}", :disposition => 'attachment'
      end

      return
    end


    folder = "#{Colony::FOLDER_OUT}/#{@id}"
    if ! File.exists?(folder)
      return;
    end

    @ok = false

    @files.keys.each do |key|

        data = nil

        file = "#{folder}/#{@files[key][:filename]}"
        if File.exists?(file) && File.size?(file)
          file = File.open(file, "rb")
          data = file.read

          data = data.strip || data

          @files[key][:data] = data

          @ok = true if data
        end
    end

    #folder = "#{Colony::FOLDER_OUT}/#{@id}"
    #if File.exists?(folder)
    #
    #  @alignment = nil
    #
    #  file = "#{folder}/alignment.txt"
    #  if File.exists?(file)
    #    file = File.open(file, "rb")
    #    @alignment = file.read
    #
    #    @alignment = @alignment.strip || @alignment
    #
    #    @files[:alignment] = {:name => 'Alignment', :data => @alignment}
    #  end
    #
    #
    #
    #
    #  @filtered_analysis_vcf = nil
    #
    #  file = "#{folder}/filtered_analysis.vcf"
    #  if File.exists?(file)
    #    file = File.open(file, "rb")
    #    @filtered_analysis_vcf = file.read
    #
    #    @filtered_analysis_vcf = @filtered_analysis_vcf.strip || @filtered_analysis_vcf
    #
    #    @files[:filtered_analysis_vcf] = {:name => 'filtered_analysis_vcf', :data => @filtered_analysis_vcf}
    #  end
    #
    #
    #
    #
    #
    #
    #  @vep_log = nil
    #
    #  file = "#{folder}/vep.log"
    #  if File.exists?(file)
    #    file = File.open(file, "rb")
    #    @vep_log = file.read
    #
    #    @vep_log = @vep_log.strip || @vep_log
    #
    #    @files[:vep_log] = {:name => 'vep_log', :data => @vep_log}
    #  end
    #
    #
    #
    #
    #
    #
    #  @mutant_fa = nil
    #
    #  file = "#{folder}/mutant.fa"
    #  if File.exists?(file)
    #    file = File.open(file, "rb")
    #    @mutant_fa = file.read
    #
    #    @mutant_fa = @mutant_fa.strip || @mutant_fa
    #
    #    @files[:vep_log] = {:name => 'mutant_fa', :data => @mutant_fa}
    #  end
    #
    #
   # end
  end

  def index_old
    @colonies = []

    Colony.all.each do |colony|
      @colonies.push colony if colony.trace_data_available
    end
  end

  def index
    @colonies = Colony.all
  end
end
