# =============================================================================
# Load dependencies
# -----------------------------------------------------------------------------
require 'csv'

require 'rubygems'
require 'bundler/setup'
Bundler.require :default

# Reads in inconsistent data and builds workable dataset.
#
# - - - - - U S A G E - - - - -
#
# Initial Usage:
#
# 	election_data = ElectionData.new({ voter_list: CSV_FILE_ARR, results: FILE })
# 	table = election_data.create_table
#
# 	...or...
#
# 	election_data = InvariantPairTable.new
# 	table = election_data.create_table({ voter_list: CSV_FILE_ARR, results: FILE })
class ElectionData

	def initialize(params = nil)
    setup(params) if params
  end

  def create_lookup(params = nil)
    setup(params) if params
    raise 'You must provide both a `voter_list` and `results`.' unless @voter_list_files && @results_file
    setup_table

    # need to nuke the first line, since it interfears with headers
    @voter_list_files = @voter_list_files.map do |input|
      output = "__TEMP__#{input}"
      system("tail -n +2 #{input} > #{output}") #kinda hacky
      output
    end

    @election_data = @@DB[:election_data]
    @voter_list_files.each do |f|
      CSV.foreach(f, headers: :first_row) do |row|
        @election_data.insert(
             student_id: row['Student ID'],
                user_id: row['User'],
             first_name: row['First Name'],
            middle_name: row['Middle'],
              last_name: row['Last'],
                  email: row['Email ID'],
                program: row['Program'],
          academic_plan: row['Acad Plan'],
                   term: row['Proj Level'],
                 campus: row['Campus']
        ) rescue next
      end
    end
    FileUtils.rm @voter_list_files

    pp @election_data.all

  end

protected

  def setup(params)
    raise 'Params must be a Hash.' unless params.is_a? Hash

    @voter_list_files = params[:voter_list]
    @results_file     = params[:results]
  end

  def setup_table
    @@DB = Sequel.sqlite
    @@DB.create_table :election_data do
      primary_key :id
      Integer :student_id, unique: true
      String  :user_id, unique: true

      String  :first_name
      String  :middle_name
      String  :last_name
      String  :email

      String  :program
      String  :academic_plan
      String  :term
      String  :campus
    end
  end

end
