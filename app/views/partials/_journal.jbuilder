json.id journal.id
json.title journal.title
json.description journal.description
json.author do
  json.id journal.user.id
  json.name journal.user.name
  json.image journal.user.image_variants
  json.image_url journal.user.image_url
end
json.chapters_count journal.chapters.published.size
json.editable current_user.author?(journal)
json.bookmarking journal.bookmarked_by?(current_user)
json.created_at journal.created_at
json.updated_at journal.updated_at
