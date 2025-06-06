require 'json'
require 'google/apis/sheets_v4'
require 'dotenv/load'
require 'byebug'

class GoogleClient
  SEATTLE_SPREADSHEET_ID = ENV['SEATTLE_RECS_SPREADSHEET_ID']
  SEATTLE_SHEET_NAME = 'SEATTLE'

  def initialize
    @service = Google::Apis::SheetsV4::SheetsService.new

    credentials_path = File.expand_path('../credentials.json', __dir__)

    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(credentials_path),
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    )
  end

  def recommendations_to_google_format(recommendations)
    recommendations.map do |recommendation|
      [
        recommendation[:name],
        recommendation[:type],
        recommendation[:experience],
        nil,
        recommendation[:notes],
        'Delian Bot',
        recommendation[:address]
      ]
    end
  end

  def append_rows(values)
    value_range = Google::Apis::SheetsV4::ValueRange.new(values: values)

    @service.append_spreadsheet_value(
      SEATTLE_SPREADSHEET_ID,
      SEATTLE_SHEET_NAME,
      value_range,
      value_input_option: 'USER_ENTERED'
    )
  end

  private

  # def credentials_json
  #   ENV['GOOGLE_TOKEN_JSON'] || raise('Missing GOOGLE_CREDENTIALS environment variable')
  # end
end
