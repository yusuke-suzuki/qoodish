json.partial! 'partials/chapter', chapter: @chapter
json.comments_count @chapter.comments.count
