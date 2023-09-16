module OmniAuth
  module Strategies
    class Idonethis < OmniAuth::Strategies::OAuth2
      # Give your strategy a name.
      option :name, "idonethis"

      # This is where you pass the options you would pass when
      # initializing your consumer from the OAuth gem.
      option :client_options, {
        :site => "https://idonethis.com",
        :authorize_url => "/api/oauth2/authorize/",
        :token_url => '/api/oauth2/token/'
      }

      def authorize_params
        super.tap do |params|
          params['approval_prompt'] = 'auto'
        end
      end

      def build_access_token
        options.token_params.merge!(:headers => {'Authorization' => basic_auth_header })
        super
      end

      def basic_auth_header
        'Basic ' + Base64.strict_encode64("#{options[:client_id]}:#{options[:client_secret]}")
      end

      def callback_url
        full_host + script_name + callback_path
      end

      uid{ raw_info['user'] }

      info do
        {
          username: raw_info['user']
        }
      end

      extra do
        {
          raw_info: raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get('/api/v0.1/noop').parsed
      end
    end
  end
end
