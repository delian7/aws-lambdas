# spec/notion_client_spec.rb

require 'spec_helper'
require 'dotenv'
require_relative '../src/notion_client'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data('<NOTION_TOKEN>') { ENV['NOTION_TOKEN'] }
  config.filter_sensitive_data('<NOTION_COFFEE_DATABASE>') { ENV['NOTION_COFFEE_DATABASE'] }
end

RSpec.describe NotionClient do
  before(:all) do
    Dotenv.load('.env.test')
  end

  let(:client) { NotionClient.new }

  describe '#coffee_shops' do
    context 'when API call is successful' do
      it 'returns coffee shops from the database' do
        VCR.use_cassette('notion_coffee_shops_success') do
          response = client.coffee_shops

          expect(response).to be_a(Notion::Response)
          expect(response.results).to be_an(Array)
          expect(response.results).not_to be_empty
        end
      end
    end

    context 'when API call fails' do
      before do
        allow_any_instance_of(Notion::Client).to receive(:database_query)
          .and_raise(Notion::APIResponseError.new("API Error"))
      end

      it 'raises a NotionError' do
        expect { client.coffee_shops }.to raise_error(NotionError)
      end
    end

    context 'when database ID is missing' do
      before do
        @original_database_id = ENV['NOTION_COFFEE_DATABASE']
        ENV['NOTION_COFFEE_DATABASE'] = nil
      end

      after do
        ENV['NOTION_COFFEE_DATABASE'] = @original_database_id
      end

      it 'raises an error' do
        expect { client.coffee_shops }.to raise_error(NotionError)
      end
    end
  end
end