# frozen_string_literal: true

class NotionClient
  NOTION_API_URL = 'https://api.notion.com/v1/pages'

  def initialize(api_key, database_id, problem_type)
    @api_key = api_key
    @database_id = database_id
    @coding_language = problem_type == 'ruby' ? 'ruby' : 'javascript'
  end

  def create_page(title, markdown_content)
    uri = URI.parse(NOTION_API_URL)
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    request['Notion-Version'] = '2022-06-28'

    children_blocks = text_to_notion_blocks(markdown_content)

    request.body = {
      parent: { database_id: @database_id },
      properties: {
        title: { title: [{ text: { content: title } }] }
      },
      children: children_blocks
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  end

  private

  def text_to_notion_blocks(text)
    blocks = []
    lines = text.split("\n")
    inside_code_block = false

    lines.each_with_index do |line, index|
      if line.strip.empty?
        next
      elsif line.start_with?('```')
        if inside_code_block
          inside_code_block = false
        else
          inside_code_block = true
          code_content = []
          while (index += 1) < lines.size && !lines[index].start_with?('```')
            code_content << lines[index]
          end

          blocks.concat(chunk_text(code_content.join("\n"), 2000, 'code', @coding_language))
        end
      elsif inside_code_block
        next
      elsif line.start_with?('# ')
        blocks << {
          object: 'block',
          type: 'heading_1',
          heading_1: { rich_text: [{ type: 'text', text: { content: line[2..].strip } }] }
        }
      elsif line.start_with?('## ')
        blocks << {
          object: 'block',
          type: 'heading_2',
          heading_2: { rich_text: [{ type: 'text', text: { content: line[3..].strip } }] }
        }
      elsif line.start_with?('### ')
        blocks << {
          object: 'block',
          type: 'heading_3',
          heading_3: { rich_text: [{ type: 'text', text: { content: line[4..].strip } }] }
        }
      elsif line.start_with?('- ')
        blocks << {
          object: 'block',
          type: 'bulleted_list_item',
          bulleted_list_item: {
            rich_text: [{ type: 'text', text: { content: line[2..].strip } }]
          }
        }
      elsif line.match(/^\d+\. /)
        blocks << {
          object: 'block',
          type: 'numbered_list_item',
          numbered_list_item: {
            rich_text: [{ type: 'text', text: { content: line.split('. ', 2)[1].strip } }]
          }
        }
      elsif line.start_with?('> ')
        blocks << {
          object: 'block',
          type: 'quote',
          quote: {
            rich_text: [{ type: 'text', text: { content: line[2..].strip } }]
          }
        }
      else
        blocks.concat(chunk_text(line.strip, 2000, 'paragraph'))
      end
    end

    blocks
  end

  def chunk_text(text, max_length, type, language = nil)
    text.scan(/.{1,#{max_length}}/m).map do |chunk|
      content = {
        rich_text: [{ type: 'text', text: { content: chunk.strip } }]
      }
      content['language'] = language unless language.nil?

      {
        object: 'block',
        type: type,
        type => content
      }
    end
  end
end
