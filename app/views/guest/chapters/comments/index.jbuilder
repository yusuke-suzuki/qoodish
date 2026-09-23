json.array! @comments do |comment|
  json.partial! 'partials/guest/comment', comment: comment
end
