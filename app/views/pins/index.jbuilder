json.array! @pins do |pin|
  json.partial! 'partials/pin', pin: pin, comments: @comments_by_pin_id.fetch(pin.id, [])
end
