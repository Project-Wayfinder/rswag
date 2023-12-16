# frozen_string_literal: true

require 'rspec/core'
require 'rswag/specs/example_group_helpers'
require 'rswag/specs/example_helpers'
require 'rswag/specs/configuration'
require 'rswag/specs/railtie' if defined?(Rails::Railtie)

module Rswag
  module Specs
    # Extend RSpec with a swagger-based DSL
    ::RSpec.configure do |c|
      c.add_setting :openapi_root
      c.add_setting :openapi_specs
      c.add_setting :rswag_dry_run
      c.add_setting :openapi_format, default: :json
      c.add_setting :openapi_strict_schema_validation
      c.extend ExampleGroupHelpers, type: :request
      c.include ExampleHelpers, type: :request
    end

    def self.config
      @config ||= Configuration.new(RSpec.configuration)
    end

    # Support Rails 3+
    RAILS_VERSION = Rails::VERSION::MAJOR
  end
end
