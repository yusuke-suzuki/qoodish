json.array! @comments do |comment|
  json.partial! 'partials/comment', comment: comment
end
