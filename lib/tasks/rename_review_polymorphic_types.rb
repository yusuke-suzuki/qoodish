# rails runner lib/tasks/rename_review_polymorphic_types.rb
class RenameReviewPolymorphicTypes
  COLUMNS = {
    Comment => :commentable_type,
    Vote => :votable_type,
    Notification => :notifiable_type,
    Image => :imageable_type,
    InappropriateContent => :content_type
  }.freeze

  def run
    COLUMNS.each do |model, column|
      updated = model.where(column => 'Review').update_all(column => Pin.name)

      puts "[Rename] #{model.name}##{column}: #{updated} rows renamed to Pin"
    end
  end
end

runner = RenameReviewPolymorphicTypes.new
runner.run
