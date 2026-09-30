json.partial! 'partials/chapter', chapter: @chapter
json.comments_count @chapter.comments.not_blocking(current_user).not_blocked_by(current_user).not_muted_by(current_user).count
