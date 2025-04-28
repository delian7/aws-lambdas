# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require_relative 'notion_client'
require_relative 'lambda_function'

class App
  def initialize(api_key, database_id, problem_type)
    @notion_client = NotionClient.new(api_key, database_id, problem_type)
  end

  def create_notion_page(title, markdown_content)
    @notion_client.create_page(title, markdown_content)
  end
end
