# mechanize is used to get the member ids from the json form
require 'mechanize'
# net/http is used to post form data
require 'net/http'
# use awesome_print to make things look nice ap instead of print
require "awesome_print"
#helps us parse csvs
require "csv"
# for debugging
require "pry"
#for persisting
require 'data_mapper'

#create our DB
DataMapper.setup( :default, "sqlite3:database.sqlite3" )

# create voterecords table
class VoteRecord
  include DataMapper::Resource

  property :id, 						Serial
  property :name, 					String
  property :councillor_id, 	String
  property :csv_raw, 				Text
end

#create parsedcsvs table linked to 
# vote record by vote_record_id
class ParsedCSV
	include DataMapper::Resource

	property :id, 								Serial
  property :committee, 					String
  property :date_time, 					String
  property :agenda_item_number, String
  property :agenda_item_title, 	String
  property :motion_type, 				String
  property :vote, 							String
  property :result, 						String
  property :vote_description, 	String
  property :vote_record_id,			Integer

  belongs_to :vote_record
end

DataMapper.finalize
DataMapper.auto_upgrade!
# end datamapper setup

# create a agent to go get ids
agent = Mechanize.new
# set url for agent
url = URI('http://app.toronto.ca/tmmis/getAdminReport.do')
report_function = '?function=prepareMemberVoteReport'

# send the agent to the page
page = agent.get(url + report_function)
#and grab the correct form
form = page.form('adminReportForm')

#add member names and ids to an array
members = []
member_field = form.field_with(:name => "memberId")
member_field.options.each { |member| members << [member.text, member.value] }

#delete the first one
members.delete(["---Select Member---", "0"])

# create an empty hash for our results
result = {}

# go through each member in the array and add the vote data to the hash
# members.each.map do |member| # use this to get all the data
members[0..4].map do |member| # use this for testing. no point in asking for everything
	name = member[0]
	id = member[1]
	# set the params for our POST
	params = { 
		toDate: "",
		termId: 6,
		sortOrder: "",
		sortBy: "",
		page: 0,
		memberId: id,
		itemsPerPage: 50,
		function: "getMemberVoteReport",
		fromDate: "",
		exportPublishReportId: 2,
		download: "csv",
		decisionBodyId: 0
	}

	# POST our params and put the result (csv) into the DB
	v = VoteRecord.create!({
		name: name,
		councillor_id: id,
		csv_raw: Net::HTTP.post_form(url, params).body
	})

	# parses the csv into a table linked to voterecords
	persist_csv(v.csv_raw, v.id)
end

def persist_csv(csv_raw, vote_record_id)
	# parses the csv. scrub cleans up non utf-8 chars
	parsed = CSV.parse(csv_raw.scrub, headers: true)
	# adds data in each row to db table
	parsed.each do |row|
		entries = row.to_h.values
		ParsedCSV.create!({
  		committee: 					entries[0],
  		date_time:  				entries[1],
  		agenda_item_number: entries[2],
  		agenda_item_title:  entries[3],
  		motion_type:        entries[4], 
  		vote:  							entries[5],
  		result:   					entries[6],
  		vote_description:   entries[7],
  		vote_record_id:  		vote_record_id
		})
	end
end

# binding.pry

# puts ""