class Fcm < ApiClientBase
  def send_message_to_topic(topic_name, body, request_path, image = nil, data = {})
    auth_client = Firebase::Auth.new
    token = auth_client.fetch_access_token

    headers = {
      Authorization: "Bearer #{token}",
      'Content-Type' => 'application/json'
    }

    notification = {
      title: 'Qoodish',
      body: body,
      icon: ENV['SUBSTITUTE_URL'],
      click_action: "#{ENV['WEB_ENDPOINT']}/#{request_path}"
    }
    notification.merge!(image: image) if image.present?
    notification.merge!(data: data) if data.present?

    params = {
      message: {
        topic: topic_name,
        webpush: {
          notification: notification
        }
      }
    }
    response = request("/v1/projects/#{ENV['FIREBASE_PROJECT_ID']}/messages:send", headers, params.to_json, :post)

    case response.status
    when 200
      json = JSON.parse(response.body)
    when 401
      raise Exceptions::Unauthorized
    when 404
      raise Exceptions::NotFound
    else
      raise Exceptions::InternalServerError
    end

    json
  end
end
