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
# 	election_data = ElectionData.new( CSV_FILE_ARR, TXT_FILE_ARR )
# 	table = election_data.create_table
#
# 	...or...
#
# 	election_data = InvariantPairTable.new
# 	table = election_data.create_table( CSV_FILE_ARR, TXT_FILE_ARR )
class ElectionData

	def initialize(voters_list=nil, results_list=nil)
    setup(voters_list, results_list) if voters_list && results_list
  end

  def create_lookup(voters_list=nil, results_list=nil)
    setup(voters_list, results_list) if voters_list && results_list
    raise 'You must provide `voter_list`.' unless @voter_list_files
    raise 'You must provide `results_list`.' unless @results_list_file

    build_table
    import_voter_lists


    pp @results_list_file
    # pp open(@results, &:read)

    # pp @election_data.all

  end

protected

  def setup(voters_list, results_list)
    raise 'voters_list must be an Array.' unless voters_list.is_a? Array
    raise 'results_list must be an Array.' unless results_list.is_a? Array

    @voter_list_files  = voters_list
    @results_list_file = results_list
  end

  def build_table
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
    @election_data = @@DB[:election_data]
  end

  def import_voter_lists
    # need to nuke the first line, since it interfears with headers
    @voter_list_files = @voter_list_files.map do |input|
      output = "__TEMP__#{input}"
      system("tail -n +2 #{input} > #{output}") #kinda hacky
      output
    end

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
  end

end
