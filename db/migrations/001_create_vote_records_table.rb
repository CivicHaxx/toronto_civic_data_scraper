class CreateVoteRecordsTable < ActiveRecord::Migration

  def change
    create_table :vote_records do |t|
      t.string  :committee
      t.string  :date_time
      t.string  :agenda_item
      t.text  :agenda_item_title 
      t.string  :motion_type
      t.string  :vote
      t.string  :result
      t.text    :vote_description
      t.integer :councillor_id
      t.integer :councillor_name
    end
    puts "Created Vote Records table"
  end
end
