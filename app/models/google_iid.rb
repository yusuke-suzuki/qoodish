class GoogleIid < ApiClientBase
  def subscribe_topic(registration_token, topic_name)
    headers = {
      Authorization: "key=#{ENV['FCM_SERVER_KEY']}",
      'Content-Type' => 'application/json'
    }
    response = request("/iid/v1/#{registration_token}/rel/topics/#{topic_name}", headers, {}, :post)
    Rails.logger.debug(response)

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

  def unsubscribe_topic(registration_token, topic_name)
    headers = {
      Authorization: "key=#{ENV['FCM_SERVER_KEY']}",
      'Content-Type' => 'application/json'
    }
    response = request("/iid/v1/#{registration_token}/rel/topics/#{topic_name}", headers, {}, :delete)
    Rails.logger.debug(response)

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
