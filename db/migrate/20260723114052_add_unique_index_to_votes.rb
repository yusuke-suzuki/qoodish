class AddUniqueIndexToVotes < ActiveRecord::Migration[7.2]
  def change
    # vote_scope is intentionally excluded: this app never sets it, and MySQL
    # treats NULLs as distinct in a unique index, which would void the
    # constraint. Run lib/tasks/dedup_votes.rb before this migration so no
    # existing duplicates block the index.
    add_index :votes,
              %i[votable_type votable_id voter_type voter_id],
              unique: true,
              name: 'index_votes_on_votable_and_voter'
  end
end
