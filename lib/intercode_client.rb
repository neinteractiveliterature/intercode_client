# frozen_string_literal: true

require_relative "intercode_client/version"
require 'graphql/client'
require 'graphql/client/http'
require 'json/jwt'

module IntercodeClient
  class Error < StandardError; end

  def self.intercode_url
    ENV['INTERCODE_URL'] || 'https://www.neilhosting.net'
  end

  HTTP = GraphQL::Client::HTTP.new("#{IntercodeClient.intercode_url}/graphql") do
    def headers(context)
      context[:headers] || {}
    end
  end
  Schema = GraphQL::Client.load_schema(
    File.expand_path('../intercode_schema.json', __FILE__)
  )
  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

  def self.decode_jwt(jwt)
    JSON::JWT.decode(jwt, IntercodeClient.jwk_set)
  end

  def self.jwk_set
    JSON::JWK::Set.new(JSON.parse(jwk_response))
  end

  def self.jwk_response
    if !@jwk_response_last_fetched || @jwk_response_last_fetched < Time.now.to_i - 3600
      @jwk_response_last_fetched = Time.now.to_i
      @jwk_response = Net::HTTP.get(URI("#{IntercodeClient.intercode_url}/oauth/discovery/keys"))
    end

    @jwk_response
  end
end
