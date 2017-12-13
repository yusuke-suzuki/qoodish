class Fcm < ApiClientBase
  def send_message_to_topic(topic_name, body, request_path)
    headers = {
      Authorization: "key=#{ENV['FCM_SERVER_KEY']}",
      'Content-Type' => 'application/json'
    }
    params = {
      to: "/topics/#{topic_name}",
      notification: {
        title: 'Qoodish',
        body: body,
        icon: ENV['SUBSTITUTE_URL'],
        click_action: "#{ENV['WEB_ENDPOINT']}/#{request_path}"
      }
    }
    response = request('/fcm/send', headers, params.to_json, :post)

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

  def send_message_to_devices(registration_tokens, body, request_path)
    headers = {
      Authorization: "key=#{ENV['FCM_SERVER_KEY']}",
      'Content-Type' => 'application/json'
    }
    params = {
      to: registration_tokens.join(','),
      notification: {
        title: 'Qoodish',
        body: body,
        icon: ENV['SUBSTITUTE_URL'],
        click_action: "#{ENV['WEB_ENDPOINT']}/#{request_path}"
      }
    }
    response = request('/fcm/send', headers, params.to_json, :post)

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
