require 'logger'
require 'notion-ruby-client'
require 'uri'

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

  def create_recommendation(recommendation)
    type = recommendation['type']
    database_id = type == 'Coffee Shop' ? ENV['NOTION_COFFEE_DATABASE'] : ENV['NOTION_RESTAURANT_DATABASE']

    @client.create_page(
      parent: {
        type: 'database_id',
        database_id: database_id
      },
      properties: type == 'Coffee Shop' ? coffee_shop_properties(recommendation) : restaurant_properties(recommendation)
    )
  end

  def get_new_recommendations(existing_recommendations)
    recommendations = coffee_shops + restaurants

    recommendations.select! do |recommendation|
      !existing_recommendations.include?(recommendation[:name])
    end

    recommendations
  end

  def coffee_shops
    response = @client.database_query(
      database_id: ENV['NOTION_COFFEE_DATABASE'],
      filter: {
        property: 'Synced to Google',
        checkbox: {
          equals: false
        }
      }
    )

    response.results.map do |result|
      address = result.properties.dig('Address', 'rich_text', 0, 'plain_text')
      maps_url = result.properties.dig('Maps Link', 'url')
      created_by_id = result.properties.dig('Created by', 'created_by', 'id')

      if address.nil? && !maps_url.nil? && maps_url.include?('maps.apple.com')
        address = maps_url.split('address=')[1].split('&')[0]
        address = URI.decode_www_form_component(address)
      end

      tags = result.properties.dig('Tags', 'multi_select')&.map { |tag| tag['name'] }

      {
        name: result.properties['Name']['title'][0]['plain_text'],
        notes: result.properties.dig('Notes', 'rich_text', 0, 'plain_text'),
        maps_url: maps_url,
        created_by: created_by_id == '17eb3923-e326-493f-8b8a-b529a323c973' ? 'Lawrence Bot' : 'Delian Bot',
        address: address,
        type: 'Coffee Shop',
        experience: tags.include?('Need to Go') ? 'Never Been There' : 'Tried It Already',
        dogs_allowed: result.properties.dig('Buddy Friendly 🐶', 'checkbox'),
        rewards_program: result.properties.dig('Offers Rewards Program', 'checkbox'),
        fast_wifi: result.properties.dig('Fast WiFi', 'checkbox'),
        good_for_work: result.properties.dig('Good for Coworking', 'checkbox'),
        outlets: result.properties.dig('Outlets', 'checkbox'),
        tags: tags,
        rating: result.properties.dig('Rating', 'number')
      }
    end
  end

  def restaurants
    response = @client.database_query(
      database_id: ENV['NOTION_RESTAURANT_DATABASE'],
      filter: {
        property: 'Synced to Google',
        checkbox: {
          equals: false
        }
      }
    )

    response.results.map do |result|
      maps_url = result.properties.dig('Maps Link', 'url')
      address = result.properties.dig('Address', 'rich_text', 0, 'plain_text')

      if address.nil? && !maps_url.nil? && maps_url.include?('maps.apple.com')
        address = maps_url.split('address=')[1].split('&')[0]
        address = URI.decode_www_form_component(address)
      end

      tags = result.properties.dig('Tags', 'multi_select')&.map { |tag| tag['name'] }
      created_by_id = result.properties.dig('Created by', 'created_by', 'id')

      tags_without_experience = tags - ['Need to Go']
      notes = result.properties.dig('Notes', 'rich_text', 0, 'plain_text')

      {
        name: result.properties.dig('Name', 'title', 0, 'plain_text'),
        notes: "#{tags_without_experience.join(', ')} #{!notes.nil? ? '. ' : ''}#{notes}",
        maps_url: maps_url,
        type: 'Restaurant',
        address: address,
        created_by: created_by_id == '17eb3923-e326-493f-8b8a-b529a323c973' ? 'Lawrence Bot' : 'Delian Bot',
        experience: tags.include?('Need to Go') ? 'Never Been There' : 'Tried It Already',
        price_range: result.properties.dig('$$$', 'select', 'name'),
        dogs_allowed: result.properties.dig('Buddy Friendly 🐶', 'checkbox'),
        rating: result.properties.dig('Our Rating', 'number'),
        tags: tags
      }
    end
  end

  def hikes
    @client.database_query(
      database_id: ENV['NOTION_HIKING_DATABASE']
    )
  end

  private

  def coffee_shop_properties(recommendation)
    properties = {
      Name: {
        title: [{ type: 'text', text: { content: recommendation['name'] } }]
      }
    }

    if recommendation['creator'] != 'undefined'
      properties['Creator'] = {
        rich_text: [{ type: 'text', text: { content: recommendation['creator'] } }]
      }
    end

    if recommendation['notes'] != 'undefined'
      properties['Notes'] = {
        rich_text: [{ type: 'text', text: { content: recommendation['notes'] } }]
      }
    end

    if recommendation['maps_url'] != 'undefined'
      properties['Maps Link'] = {
        url: recommendation['maps_url']
      }
    end

    if recommendation['dogs_allowed'] != 'undefined'
      properties['Buddy Friendly 🐶'] = {
        checkbox: recommendation['dogs_allowed']
      }
    end

    if recommendation['rewards_program'] != 'undefined'
      properties['Offers Rewards Program'] = {
        checkbox: recommendation['rewards_program']
      }
    end

    if recommendation['fast_wifi'] != 'undefined'
      properties['Fast WiFi'] = {
        checkbox: recommendation['fast_wifi']
      }
    end

    if recommendation['good_for_work'] != 'undefined'
      properties['Good for Coworking'] = {
        checkbox: recommendation['good_for_work']
      }
    end

    if recommendation['outlets'] != 'undefined'
      properties['Outlets'] = {
        checkbox: recommendation['outlets']
      }
    end

    if recommendation['tags'] != 'undefined'
      properties['Tags'] = {
        multi_select: recommendation['tags'].map { |tag| { name: tag } }
      }
    end

    if recommendation['rating'] != 'undefined'
      properties['Rating'] = {
        number: recommendation['rating']
      }
    end

    properties
  end

  def restaurant_properties(recommendation)
    properties = {
      Name: {
        title: [{ type: 'text', text: { content: recommendation['name'] } }]
      },
      Notes: {
        rich_text: [{ type: 'text', text: { content: recommendation['notes'] } }]
      },
      'Maps Link': {
        url: recommendation['maps_url']
      }
    }

    # Only add creator if it exists and is not nil
    if recommendation['creator'] != 'undefined'
      properties['Creator'] = {
        rich_text: [{ type: 'text', text: { content: recommendation['creator'] } }]
      }
    end

    # Only add rating if it exists and is not nil
    if recommendation['rating'] != 'undefined'
      properties['Our Rating'] = {
        select: {
          name: recommendation['rating']
        }
      }
    end

    # Only add tags if they exist and are not empty
    if recommendation['tags'] != 'undefined'
      properties['Tags'] = {
        multi_select: recommendation['tags'].map { |tag| { name: tag } }
      }
    end

    # Only add price range if it exists and is not nil
    if recommendation['price_range'] != 'undefined'
      properties['$$$'] = {
        select: {
          name: recommendation['price_range']
        }
      }
    end

    properties
  end
end
