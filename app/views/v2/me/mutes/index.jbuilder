json.data @mutes do |mute|
  json.id mute.muted.id
  json.name mute.muted.name
  json.biography mute.muted.biography
  json.image mute.muted.image_variants
  json.image_url mute.muted.image_url
end
json.next_cursor @next_cursor
