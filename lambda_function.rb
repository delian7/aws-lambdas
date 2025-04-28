# frozen_string_literal: true

require 'json'
require_relative 'app'

def lambda_handler(event:, context:)
  body = event['body'] ? JSON.parse(event['body']) : {}
  title = body['title'] || 'Untitled'
  markdown_content = body['markdown_content']
  api_key = ENV['NOTION_API_KEY']
  problem_type = body['problem_type'] || 'ruby'

  database_id = case problem_type
                when 'javascript'
                  ENV['NOTION_JAVASCRIPT_DATABASE_ID']
                when 'system_design'
                  ENV['NOTION_SYSTEM_DESIGN_DATABASE_ID']
                else
                  ENV['NOTION_RUBY_DATABASE_ID']
                end

  app = App.new(api_key, database_id, problem_type)
  response = app.create_notion_page(title, markdown_content)

  {
    statusCode: 200,
    body: response
  }
rescue StandardError => e
  {
    statusCode: 500,
    body: e.message,
    markdown_content: markdown_content
  }
end
