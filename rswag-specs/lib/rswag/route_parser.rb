# frozen_string_literal: true

module Rswag
  class RouteParser
    attr_reader :controller

    def initialize(controller)
      @controller = controller
    end

    def routes
      ::Rails.application.routes.routes.select do |route|
        route.defaults[:controller] == controller &&
        path_from(route).start_with?('/api/')
      end.each_with_object({}) do |route, tree|
        path = path_from(route)
        path = path.gsub('/api/v{api_version}/', '/api/v1/') if path.include?('/api/v{api_version}/')

        verb = select_primary_verb(verb_from(route))

        # Generate the tag once per path
        tag = controller_tag

        tree[path] ||= { params: params_from(route), actions: {}, tag: tag }
        tree[path][:params] = tree[path][:params].reject { |param| param == 'api_version' || param == 'id' }

        tree[path][:actions][verb] = { summary: summary_from(route) }
        tree
      end
    end

    private

    def path_from(route)
      route.path.spec.to_s
        .chomp('(.:format)') # Ignore any format suffix
        .gsub(/:([^\/.?]+)/, '{\1}') # Convert :id to {id}
    end

    def select_primary_verb(verb)
      verbs = verb.split('|')
      return verb if verbs.size == 1

      # Priority order: delete > post > put > patch > get
      return 'delete' if verbs.include?('delete')
      return 'post' if verbs.include?('post')
      return 'put' if verbs.include?('put')
      return 'patch' if verbs.include?('patch')
      return 'options' if verbs.include?('options')
      return 'get' if verbs.include?('get')
      verbs.first || 'post' # fallback to first verb if none match
    end

    def controller_tag
      # Remove 'Controller' suffix and any namespacing
      base_name = controller.split('/').last.sub(/Controller$/, '')

      # Convert from plural to singular if it ends with 's'
      base_name = base_name.singularize

      # Convert from snake_case to Title Case
      base_name.split('_').map(&:capitalize).join(' ')
    end

    def summary_from(route)
      verb = route.requirements[:action]
      noun = route.requirements[:controller].split('/').last.singularize

      # Apply a few customizations to make things more readable
      case verb
      when 'index'
        verb = 'list'
        noun = noun.pluralize
      when 'destroy'
        verb = 'delete'
      end

      "#{verb} #{noun}"
    end

    def verb_from(route)
      verb = route.verb
      if verb.is_a? String
        verb.downcase
      else
        verb.source.gsub(/[$^]/, '').downcase
      end
    end

    def params_from(route)
      route.segments - ['format']
    end
  end
end
