require 'openapi_helper'

RSpec.describe '<%= controller_path %>', type: :request do
  let(:manager) { create_manager }
  let(:auth_header) { auth_headers(manager) }
  let(:request_headers) { auth_header }
  let(:resource_name) { controller_path.singularize }
  let!(:resource) { create(resource_name.to_sym) }
  let(:id) { resource.id }

  <%- @routes.each do |template, path_item| -%>
  path '<%= template %>.json' do
    <%- unless path_item[:params].empty? -%>
    <%- path_item[:params].each do |param| -%>
    parameter name: '<%= param %>',
              in: :path,
              schema: { type: :string, format: :uuid },
              required: true,
              description: '<%= param.humanize %> UUID'
    <%- end -%>
    <%- end -%>

    <%- path_item[:actions].each do |action, details| -%>
    <%= action %>('<%= details[:summary] %>') do
      tags <%= path_item[:tag].inspect %>
      operationId '<%= action %>-<%= path_item[:tag].downcase.gsub(/\s+/, '-') %>'
      produces 'application/json'
      description <<~DESC
        <%= details[:summary] %>.

        ## Scope:
        - System Admin:
        - School Admin:
        - Principal:
        - Counselor:
        - Teacher:
        - Student:
      DESC

      <%- operation_type = details[:summary].to_s.split(' ').first -%>
      <%- case operation_type -%>
      <%- when 'list' -%>
      pagination_parameters.each { |param| parameter param }
      parameter(search_parameter(['name']))
      parameter(order_parameter(['name', 'created_at', 'updated_at']))

      response '200', '<%= path_item[:tag].downcase %> found' do
        pagination_headers.each do |header_name, header_schema|
          header header_name, header_schema
        end

        run_test! do |response|
          response_data = JSON.parse(response.body)
          expect(response_data.first["id"]).to eq(resource.id)
        end
      end

      <%- when 'show' -%>
      response '200', '<%= resource_name %> found' do
        let(:request_params) { { 'id' => id } }

        run_test! do |response|
          response_data = JSON.parse(response.body)
          expect(response_data["id"]).to eq(id)
        end
      end

      it_behaves_like 'not_found_response'

      <%- when 'create' -%>
      parameter name: :<%= resource_name %>, in: :body, schema: {
        type: :object,
        properties: {
          # TODO: Add properties based on model
        }
      }

      response '201', '<%= resource_name %> created' do
        let(:request_params) { attributes_for(:<%= resource_name %>) }

        run_test! do |response|
          response_data = JSON.parse(response.body)
          expect(response_data["id"]).to be_present
        end
      end

      response '422', 'invalid request' do
        let(:request_params) { attributes_for(:<%= resource_name %>).merge(name: nil) }
        run_test!
      end

      <%- when 'update' -%>
      parameter name: :<%= resource_name %>, in: :body, schema: {
        type: :object,
        properties: {
          # TODO: Add properties based on model
        }
      }

      response '200', '<%= resource_name %> updated' do
        let(:request_params) { attributes_for(:<%= resource_name %>) }

        run_test! do |response|
          response_data = JSON.parse(response.body)
          expect(response_data["id"]).to eq(id)
        end
      end

      response '422', 'invalid request' do
        let(:request_params) { attributes_for(:<%= resource_name %>).merge(name: nil) }
        run_test!
      end

      it_behaves_like 'not_found_response'

      <%- when 'delete' -%>
      response '204', '<%= resource_name %> deleted' do
        let(:request_params) { { 'id' => id } }
        run_test!
      end

      it_behaves_like 'not_found_response'

      <%- end -%>
    end
    <%- end -%>
  end
  <%- end -%>
end
