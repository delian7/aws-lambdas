# frozen_string_literal: true

require 'json'
require 'logger'
require 'byebug'

require_relative 'notion_client.rb'
require_relative 'google_client.rb'
LOGGER = Logger.new($stdout)
LOGGER.level = ENV['LOG_LEVEL'] || Logger::INFO

def lambda_handler(event:, context:) # rubocop:disable Lint/UnusedMethodArgument
  http_method = event['httpMethod']
  # resource = event['resource']
  # raw_data = event.dig('queryStringParameters', 'raw_data')
  google_client = GoogleClient.new
  notion_client = NotionClient.new

  case http_method
  when 'POST'
    send_response(notion_client.coffee_shops)
  when 'PATCH'
    existing_recommendations = google_client.get_names_of_all_rows

    new_recommendations = notion_client.get_new_recommendations(existing_recommendations)
    google_formatted_recommendations = google_client.recommendations_to_google_format(new_recommendations)
    send_response(google_client.append_rows(google_formatted_recommendations))
  else
    method_not_allowed_response
  end
rescue StandardError => e
  error_response(e)
end

def send_response(data)
  {
    'statusCode' => 200,
    'body' => JSON.generate(data)
  }
end

def method_not_allowed_response
  {
    'statusCode' => 405,
    'body' => JSON.generate({ error: 'Method Not Allowed' })
  }
end

def error_response(error)
  {
    'statusCode' => 500,
    'body' => JSON.generate({ error: error.message })
  }
end

p lambda_handler(event: { 'httpMethod' => 'PATCH' }, context: {})
