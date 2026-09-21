json.array! @comments do |comment|
  json.partial! 'partials/comment', comment: comment
  json.editable current_user.author?(comment)
end
