json.partial! 'partials/guest/chapter', chapter: @chapter
json.comments_count @chapter.comments.count
