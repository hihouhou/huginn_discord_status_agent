module Agents
  class DiscordStatusAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule '5m'

    description do
      <<-MD
      The Discord status agent fetches Discord service status.

      `changes_only` is only used to emit event everytime.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:
        {
          "page": {
            "id": "srhpyqt94yxb",
            "name": "Discord",
            "url": "https://discordstatus.com",
            "time_zone": "America/Tijuana",
            "updated_at": "2020-10-28T14:23:33.064-07:00"
          },
          "status": {
            "indicator": "none",
            "description": "All Systems Operational"
          }
        }
    MD

    def default_options
      {
        'expected_receive_period_in_days' => '2',
        'changes_only' => 'true'
      }
    end

    form_configurable :expected_receive_period_in_days, type: :string
    form_configurable :changes_only, type: :boolean

    def validate_options

      if options.has_key?('changes_only') && boolify(options['changes_only']).nil?
        errors.add(:base, "if provided, changes_only must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def check
      check_status
    end

    private

    def check_status()

        uri = URI.parse("https://srhpyqt94yxb.statuspage.io/api/v2/status.json")
        response = Net::HTTP.get_response(uri)

        log "fetch status request status : #{response.code}"
        parsed_json = JSON.parse(response.body)
        payload = { :status => { :indicator => "#{parsed_json['status']['indicator']}", :description => "#{parsed_json['status']['description']}" } }

        if interpolated['changes_only'] == 'true'
          if payload.to_s != memory['last_status']
            memory['last_status'] = payload.to_s
            create_event payload: payload
          end
        else
          create_event payload: payload
          if payload.to_s != memory['last_status']
            memory['last_status'] = payload.to_s
          end
        end
    end
  end
end
