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
#
# Get the table to play with:
# 	table = election_data.election_data_table
#
# Write the table out to file:
#   election_data.create_csv
#
class ElectionData

  attr_reader :election_data_table

	def initialize(voters_list=nil, results_list=nil)
    setup(voters_list, results_list) if voters_list && results_list
    raise 'You must provide `voter_list`.' unless @voter_list_files
    raise 'You must provide `results_list`.' unless @results_list_file

    build_table
    import_voter_lists
    import_results_lists
  end

  def create_csv(file_name='__election_data.csv')
    CSV.open( file_name, 'w',
              write_headers: true,
              headers: @election_data_table.columns.map(&:to_s)
             ) do |csv_out|
      @election_data_table.each do |row|
        csv_out << row.to_a.transpose.last
      end
    end
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

      String  :ip
      String  :vote_time
    end
    @election_data_table = @@DB[:election_data]
  end

  def import_voter_lists
    # need to nuke the first line, since it interfears with headers
    @voter_list_files = @voter_list_files.map do |input|
      output = "#{input}.tmp"
      system("tail -n +2 #{input} > #{output}") #kinda hacky
      output
    end

    @voter_list_files.each do |f|
      CSV.foreach(f, headers: :first_row) do |row|
        @election_data_table.insert(
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

  def import_results_lists
    file_results = @results_list_file.map do |f|
      raw_string = open(f, &:read)
      results_arr = raw_string.scan(/ ([a-zA-Z]\w{3,11}  .*?) ((?= [a-zA-Z]\w{3,11}) | $) /mx).map(&:first)
    end

    file_results.each do |result|
      result.each do |data|
        user_id = find_user_id(data)
        ip = find_ip(data)
        vote_datetime = find_vote_datetime(data)

        @election_data_table.where('user_id = ?', user_id).update( ip: ip, vote_time: vote_datetime)
      end
    end
  end

  def find_user_id(str)
    str.match(/ [a-zA-Z]\w{3,11} /mx).to_s
  end

  def find_ip(str)
    raw_ip = str.match(/ \[ (.*) \] /mx)
    raw_ip[1].to_s if raw_ip
  end

  def find_vote_datetime(str)
    raw_vote_datetime = str.match(/ at\ (.*) /mx)
    DateTime.parse( raw_vote_datetime.to_s ) if raw_vote_datetime
  end

end
