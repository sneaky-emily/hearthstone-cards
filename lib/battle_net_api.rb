require 'redis'
require 'faraday'
require_relative 'cache_helper'

# A helper class to abstract some of the quirks of the BattleNet API away. An alternative here would be to use a gem,
# but I felt that would not be in the spirit of this assessment
class BattleNetApi
  # Since the data is generally the same regardless of region for Hearthstone, we're just hard coding the region. An app
  # accessing differing data (say M+ keystone data), this would not include the region nor the hearthstone path hardcoded
  API_URL = 'https://us.api.blizzard.com/hearthstone/'.freeze

  class << self
    def get(slug, params)
      if CacheHelper.enabled? && CacheHelper.exists?(slug, params)
        get_cached_response(slug, params)
      else
        get_live_response(slug, params)
      end
    end

    private

    def get_cached_response(slug, params)
      CacheHelper.get(slug, params)
    end

    def get_live_response(slug, params)
      response = Faraday::Response.new ## Placeholder response object so response is correctly scoped
      backoff = 0.1
      success = false
      while !success && backoff < 1
        response = do_api_request(slug, params)
        if response.status == 200
          CacheHelper.set(slug, response.body, 2_629_800, params) if CacheHelper.enabled? # 1 month cache length
          success = true
        else
          # 503, 404, 429, etc
          # These should be handled separately (i.e. 429 would change request behavior to slow them down for a period
          # but not reauth, 401 or 503 should try reauthing) but for simplicity of this are handled together
          sleep(backoff)
          backoff *= 2
          CacheHelper.del('auth') if CacheHelper.enabled? # This forces a new bearer token to be generated if cached
        end
      end
      raise 'Request to Blizzard was unsuccessful' unless success

      response.body
    end

    def do_api_request(slug, params)
      conn = Faraday.new(url: API_URL) do |c|
        c.request :authorization, 'Bearer', -> { auth_token }
      end
      conn.get(slug) do |req|
        req.params = params
      end
    end

    def auth_token
      if CacheHelper.enabled? && CacheHelper.exists?('auth')
        CacheHelper.get('auth')
      else
        bnet_public_auth_flow
      end
    end

    def bnet_public_auth_flow
      auth_url = 'https://us.battle.net/oauth/token'.freeze
      auth = Faraday.new do |conn|
        conn.request :authorization, :basic, ENV['BNET_ID'], ENV['BNET_SECRET']
      end
      bnet_auth_resp = auth.post(auth_url, 'grant_type=client_credentials')
      bnet_auth = JSON.parse(bnet_auth_resp.body)
      CacheHelper.set('auth', bnet_auth['access_token'], 86_400) if CacheHelper.enabled? # sets auth cache for 1 day
      bnet_auth['access_token']
    end
  end
end
