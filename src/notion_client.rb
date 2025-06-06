
require 'logger'
require 'notion-ruby-client'

class NotionError < StandardError; end

NOTION_DATABASE_ID = ENV['NOTION_DATABASE_ID']
LOGGER = Logger.new($stdout)
LOGGER.level = ENV['LOG_LEVEL'] || Logger::INFO

class NotionClient
  def initialize
    @client = Notion::Client.new(token: ENV['NOTION_TOKEN'])
  rescue StandardError => e
    LOGGER.error("Failed to initialize Notion client: #{e.message}")
    raise NotionError, "Failed to initialize Notion client: #{e.message}"
  end

  def coffee_shops
    response = @client.database_query(
      database_id: ENV['NOTION_COFFEE_DATABASE']
    )

    response.results.map do |result|
      address = result.properties.dig('Address', 'rich_text', 0, 'plain_text')
      maps_url = result.properties.dig('Maps Link', 'url')

      if address.nil? && !maps_url.nil? && maps_url.include?('maps.apple.com')
        address = maps_url.split('address=')[1].split('&')[0]
        address = address.gsub('%20', ' ')
      end

      {
        name: result.properties['Name']['title'][0]['plain_text'],
        notes: result.properties.dig('Notes', 'rich_text', 0, 'plain_text'),
        maps_url: maps_url,
        address: address,
        type: 'Coffee Shop',
        experience: 'Tried It Already',
        dogs_allowed: result.properties.dig('Buddy Friendly 🐶', 'checkbox'),
        rewards_program: result.properties.dig('Offers Rewards Program', 'checkbox'),
        fast_wifi: result.properties.dig('Fast WiFi', 'checkbox'),
        good_for_work: result.properties.dig('Good for Coworking', 'checkbox'),
        outlets: result.properties.dig('Outlets', 'checkbox'),
        tags: result.properties.dig('Tags', 'multi_select').map { |tag| tag['name'] },
        rating: result.properties.dig('Rating', 'number')
      }
    end
  end

  def restaurants
    response = @client.database_query(
      database_id: ENV['NOTION_RESTAURANT_DATABASE']
    )

    response.results.map do |result|
      maps_url = result.properties.dig('Maps Link', 'url')
      address = result.properties.dig('Address', 'rich_text', 0, 'plain_text')

      if address.nil? && !maps_url.nil? && maps_url.include?('maps.apple.com')
        address = maps_url.split('address=')[1].split('&')[0]
        address = address.gsub('%20', ' ')
      end

      {
        name: result.properties.dig('Name', 'title', 0, 'plain_text'),
        notes: result.properties.dig('Notes', 'rich_text', 0, 'plain_text'),
        maps_url: maps_url,
        type: 'Restaurant',
        address: address,
        price_range: result.properties.dig('$$$', 'select', 'name'),
        dogs_allowed: result.properties.dig('Buddy Friendly 🐶', 'checkbox'),
        rating: result.properties.dig('Our Rating', 'number'),
        tags: result.properties.dig('Tags', 'multi_select').map { |tag| tag['name'] }
      }
    end
  end

  def hikes
    @client.database_query(
      database_id: ENV['NOTION_HIKING_DATABASE']
    )
  end
end
