# bin/rails runner lib/tasks/dedup_votes.rb
#
# Removes duplicate votes that share the same votable and voter, keeping the
# earliest row, so 20260723114052_add_unique_index_to_votes can add its unique
# index without hitting existing duplicates.
# Run before that migration.

removed = 0

Vote
  .group(:votable_type, :votable_id, :voter_type, :voter_id)
  .having('COUNT(*) > 1')
  .pluck(:votable_type, :votable_id, :voter_type, :voter_id)
  .each do |votable_type, votable_id, voter_type, voter_id|
    duplicates = Vote
                 .where(
                   votable_type: votable_type,
                   votable_id: votable_id,
                   voter_type: voter_type,
                   voter_id: voter_id
                 )
                 .order(:id)
                 .offset(1)

    removed += duplicates.each(&:destroy!).size
  end

Rails.logger.info("Dedup complete: removed #{removed} duplicate votes")
