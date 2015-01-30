require 'mechanize'
require 'net/http'
require 'csv'

agent = Mechanize.new

url = URI('http://app.toronto.ca/tmmis/getAdminReport.do')
report_function = '?function=prepareMemberVoteReport'

page = agent.get(url + report_function)

form = page.form('adminReportForm')

members = []
member_field = form.field_with(:name => "memberId")
member_field.options.each { |member| members << [member.text, member.value] }
members.delete(["---Select Member---", "0"])

result = {}

 members.each do |member|
	name = member[0]
	id = member[1]
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
	votes = Net::HTTP.post_form(url, params).body
	result[id.to_sym] = [name, votes]

end