json.partial! 'partials/comment', comment: @comment
json.editable current_user.author?(@comment)
