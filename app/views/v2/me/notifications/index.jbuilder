json.data @page.groups, partial: 'v2/partials/notification_group', as: :group
json.next_cursor @page.next_cursor&.to_s
