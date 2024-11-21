require 'openapi_helper'

RSpec.describe '<%= controller_path %>', type: :request do
  # Authentication setup
  let(:manager) { create_manager }
  let(:Authorization) { "Bearer #{generate_token(manager)}" }
  let(:resource_name) { controller_path.singularize }
  let(:valid_attributes) { attributes_for(resource_name.to_sym) }
  let(:invalid_attributes) { attributes_for(resource_name.to_sym) }
  let(:resource) { create(resource_name.to_sym) }
  let(:id) { resource.id }

  # Shared examples for common response patterns
  shared_examples 'requires authentication' do
    context 'without authentication' do
      let(:Authorization) { nil }

      it 'returns 401 unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  shared_examples 'requires authorization' do
    context 'without proper authorization' do
      it 'returns 403 forbidden' do
        subject
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  before do
    # Add setup code for tests here
  end

  <%- @routes.each do |template, path_item| -%>
  path '<%= template %>.json' do
    <%- unless path_item[:params].empty? -%>
      <%- path_item[:params].each do |param| -%>
    parameter name: '<%= param %>', in: :path, type: :string, description: '<%= param %>'
      <%- end -%>
    <%- end -%>

    <%- path_item[:actions].each do |action, details| -%>
    <%= action %>('<%= details[:summary] %>') do
      tags <%= path_item[:tag].inspect %>
      produces 'application/json'
      consumes 'application/json'

      deprecated false
      description <<~DESC
        <%= details[:summary] %>

        Authorization:
        - Required roles: System Admin

      DESC

      <%- case action -%>
      <%- when 'index', 'list' -%>
      # Pagination parameters for index/list endpoints
      parameter name: 'page', in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: 'per_page', in: :query, type: :integer, required: false, description: 'Items per page'
      parameter name: :order, in: :query,
          required: false,
          default: 'created_at',
          schema: {
            type: :string,
            enum: ['name', '-name', 'created_at', '-created_at']
          },
          description: 'Sort order (prefix with - for descending)'

      # Search/filter parameters
      parameter name: 'search', in: :query, type: :string, required: false, description: 'Search query'

      response(200, 'successful') do
        include_examples 'requires authentication'
        <%- unless path_item[:params].empty? -%>
          <%- path_item[:params].each do |param| -%>
        let(:<%= param %>) { '8d90edfc-44cf-44c6-8632-3bd47120b4cc' }
          <%- end -%>
        <%- end -%>

        header 'current-page', schema: { type: :integer }, description: 'Current page number'
        header 'page-items', schema: { type: :integer }, description: 'Items per page'
        header 'total-pages', schema: { type: :integer }, description: 'Total number of pages'
        header 'total-count', schema: { type: :integer }, description: 'Total number of items'
        # TODO: Add schema for response body
        # schema type: :array, items: { '$ref' => '#/components/schemas/<%= path_item[:tag].singularize.downcase %>' }

        before do
          create_list(:<%= path_item[:tag].singularize.downcase %>, 2)
        end

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          expect_pagination_headers
          expect(json_response).to be_an(Array)
        end
      end

      <%- when 'show' -%>
      response(200, 'successful') do
        include_examples 'requires authentication'
        <%- unless path_item[:params].empty? -%>
          <%- path_item[:params].each do |param| -%>
        let(:<%= param %>) { '8d90edfc-44cf-44c6-8632-3bd47120b4cc' }
          <%- end -%>
        <%- end -%>

        # TODO: Add schema for response body
        # schema { '$ref' => '#/components/schemas/<%= path_item[:tag].singularize.downcase %>' }

        before do
          # Add setup code for tests here
        end

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end

      response(404, 'not found') do
        <%- unless path_item[:params].empty? -%>
          <%- path_item[:params].each do |param| -%>
        let(:<%= param %>) { '8d90edfc-44cf-44c6-8632-3bd47120b4cc' }
          <%- end -%>
        <%- end -%>

        schema '$ref' => '#/components/schemas/Error'

        run_test!
      end

      <%- when 'create' -%>
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          <%= path_item[:tag].singularize.downcase %>: {
            '$ref' => '#/components/schemas/<%= path_item[:tag].singularize.downcase %>_input'
          }
        },
        required: ['<%= path_item[:tag].singularize.downcase %>']
      }

      response(201, 'created') do
        include_examples 'requires authentication'
        include_examples 'requires authorization'
        <%- unless path_item[:params].empty? -%>
          <%- path_item[:params].each do |param| -%>
        let(:<%= param %>) { '8d90edfc-44cf-44c6-8632-3bd47120b4cc' }
          <%- end -%>
        <%- end -%>

        let(:body) { { <%= path_item[:tag].singularize.downcase %>: valid_attributes } }

        # TODO: Add schema for response body
        # schema { '$ref' => '#/components/schemas/<%= path_item[:tag].singularize.downcase %>' }

        before do
          # Add setup code for tests here
        end

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:created)
        end
      end

      response(422, 'unprocessable entity') do
        <%- unless path_item[:params].empty? -%>
          <%- path_item[:params].each do |param| -%>
        let(:<%= param %>) { '8d90edfc-44cf-44c6-8632-3bd47120b4cc' }
          <%- end -%>
        <%- end -%>

        let(:body) { { <%= path_item[:tag].singularize.downcase %>: invalid_attributes } }

        schema '$ref' => '#/components/schemas/Error'

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      <%- when 'update' -%>
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          <%= path_item[:tag].singularize.downcase %>: {
            '$ref' => '#/components/schemas/<%= path_item[:tag].singularize.downcase %>_input'
          }
        },
        required: ['<%= path_item[:tag].singularize.downcase %>']
      }

      response(200, 'ok') do
        include_examples 'requires authentication'
        include_examples 'requires authorization'
        <%- unless path_item[:params].empty? -%>
          <%- path_item[:params].each do |param| -%>
        let(:<%= param %>) { '8d90edfc-44cf-44c6-8632-3bd47120b4cc' }
          <%- end -%>
        <%- end -%>

        let(:body) { { <%= path_item[:tag].singularize.downcase %>: valid_attributes } }

        # TODO: Add schema for response body
        # schema { '$ref' => '#/components/schemas/<%= path_item[:tag].singularize.downcase %>' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:ok)
        end
      end

      response(422, 'unprocessable entity') do
        <%- unless path_item[:params].empty? -%>
          <%- path_item[:params].each do |param| -%>
        let(:<%= param %>) { '8d90edfc-44cf-44c6-8632-3bd47120b4cc' }
          <%- end -%>
        <%- end -%>

        let(:body) { { <%= path_item[:tag].singularize.downcase %>: invalid_attributes } }

        schema '$ref' => '#/components/schemas/Error'

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      <%- when 'destroy', 'delete' -%>
      response(202, 'accepted') do
        include_examples 'requires authentication'
        include_examples 'requires authorization'
        <%- unless path_item[:params].empty? -%>
          <%- path_item[:params].each do |param| -%>
        let(:<%= param %>) { '8d90edfc-44cf-44c6-8632-3bd47120b4cc' }
          <%- end -%>
        <%- end -%>

        # TODO: Add schema for response body
        # schema { '$ref' => '#/components/schemas/<%= path_item[:tag].singularize.downcase %>' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:accepted)
        end
      end

      response(404, 'not found') do
        <%- unless path_item[:params].empty? -%>
          <%- path_item[:params].each do |param| -%>
        let(:<%= param %>) { '8d90edfc-44cf-44c6-8632-3bd47120b4cc' }
          <%- end -%>
        <%- end -%>

        schema '$ref' => '#/components/schemas/Error'

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end

      <%- else -%>
      response(200, 'successful') do
        include_examples 'requires authentication'
        include_examples 'requires authorization'
        <%- unless path_item[:params].empty? -%>
          <%- path_item[:params].each do |param| -%>
        let(:<%= param %>) { '8d90edfc-44cf-44c6-8632-3bd47120b4cc' }
          <%- end -%>
        <%- end -%>

        # TODO: Add schema for response body
        # schema { '$ref' => '#/components/schemas/<%= path_item[:tag].singularize.downcase %>' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
      <%- end -%>
    end
    <%- end -%>
  end
  <%- end -%>
end
