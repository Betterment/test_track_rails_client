module Her
  module Model
    class Relation

      # @private
      attr_accessor :params, :request_headers, :request_options
      attr_writer :parent

      # @private
      def initialize(parent)
        @parent = parent
        @params = {}
        @request_headers = {}
        @request_options = {}
      end

      # @private
      def apply_to(attributes)
        @params.merge(attributes)
      end

      # Build a new resource
      def build(attributes = {})
        @parent.build(@params.merge(attributes))
      end

      def with_request_headers(headers = {})
        return self if headers.blank?
        self.clone.tap do |r|
          r.request_headers = r.request_headers.merge!(headers)
          r.clear_fetch_cache!
        end
      end

      def with_request_options(options = {})
        return self if options.blank?
        self.clone.tap do |r|
          r.request_options = r.request_options.merge!(options)
          r.clear_fetch_cache!
        end
      end

      # Add a query string parameter
      #
      # @example
      #   @users = User.all
      #   # Fetched via GET "/users"
      #
      # @example
      #   @users = User.where(:approved => 1).all
      #   # Fetched via GET "/users?approved=1"
      def where(params = {})
        return self if params.blank? && !@_fetch.nil?
        clone.tap do |r|
          r.params = r.params.merge(params)
          r.clear_fetch_cache!
        end
      end
      alias all where

      # Bubble all methods to the fetched collection
      #
      # @private
      def method_missing(method, *args, &blk)
        fetch.send(method, *args, &blk)
      end

      # @private
      def respond_to?(method, *args)
        super || fetch.respond_to?(method, *args)
      end

      # @private
      def nil?
        fetch.nil?
      end

      # @private
      def kind_of?(thing)
        fetch.is_a?(thing)
      end

      # Fetch a collection of resources
      #
      # @private
      def fetch
        @_fetch ||= begin
          path = @parent.build_request_path(@parent.collection_path, @params)
          method = @parent.method_for(:find)
          @parent.request(@params.merge(:_method => method, :_path => path, :_headers => request_headers, :_options => request_options)) do |parsed_data, _|
            @parent.new_collection(parsed_data)
          end
        end
      end

      # Fetch first result
      #
      # @example
      #   @user = User.where(id: 1).first
      #   # Fetched via GET "/users/1"
      #
      # @example
      #   @users = User.where(id: 1, age: 25)
      #   # Fetched via GET "/users/1?age=25"
      #
      # @example
      #   @users = User.where(age: 25)
      #   # Fetched via GET "/users?age=25"
      #   # locally limit to single result
      #
      # @example
      #   @users = User.where(id: [1, 2])
      #   # Fetched via GET "/users?id[]=1&id[]=2"
      #   # locally limit to single result
      def first
        id_param = self.params[@parent.primary_key]

        if id_param && !id_param.is_a?(Array)
          self.params.delete(@parent.primary_key)
          request_params = self.params.merge(
            :_method => @parent.method_for(:find),
            :_path => @parent.build_request_path(self.params.merge(@parent.primary_key => id_param)),
            :_headers => request_headers,
            :_options => request_options
          )
          @parent.request(request_params) do |parsed_data, response|
            if response.success?
              resource = @parent.new_from_parsed_data(parsed_data)
              resource.instance_variable_set(:@changed_attributes, {})
              resource.run_callbacks :find
              resource
            elsif [404, 410].include? response.status
              nil
            else
              raise Her::Errors::ResponseError.for(response.status).new("Request against #{@parent.name} returned a #{response.status}")
            end
          end
        else
          fetch.first
        end
      end

      # Fetch specific resource(s) by their ID
      #
      # @example
      #   @user = User.find(1)
      #   # Fetched via GET "/users/1"
      #
      # @example
      #   @users = User.find([1, 2])
      #   # Fetched via GET "/users/1" and GET "/users/2"
      def find(*ids)
        params = @params.merge(ids.last.is_a?(Hash) ? ids.pop : {})
        ids = Array(params[@parent.primary_key]) if params.key?(@parent.primary_key)

        results = ids.flatten.compact.uniq.map do |id|
          resource = nil
          request_params = params.merge(
            :_method => @parent.method_for(:find),
            :_path => @parent.build_request_path(params.merge(@parent.primary_key => id)),
            :_headers => request_headers,
            :_options => request_options
          )

          @parent.request(request_params) do |parsed_data, response|
            if response.success?
              resource = @parent.new_from_parsed_data(parsed_data)
              resource.run_callbacks :find
            else
              raise Her::Errors::ResponseError.for(response.status).new("Request against #{@parent.name} returned a #{response.status}")
            end
          end

          resource
        end

        ids.length > 1 || ids.first.is_a?(Array) ? results : results.first
      end

      # Fetch first resource with the given attributes.
      #
      # If no resource is found, returns <tt>nil</tt>.
      #
      # @example
      #   @user = User.find_by(name: "Tobias", age: 42)
      #   # Called via GET "/users?name=Tobias&age=42"
      def find_by(params)
        where(params).first
      end

      # Fetch first resource with the given attributes, or create a resource
      # with the attributes if one is not found.
      #
      # @example
      #   @user = User.find_or_create_by(email: "remi@example.com")
      #
      #   # Returns the first item in the collection if present:
      #   # Called via GET "/users?email=remi@example.com"
      #
      #   # If collection is empty:
      #   # POST /users with `email=remi@example.com`
      #   @user.email # => "remi@example.com"
      #   @user.new? # => false
      def find_or_create_by(attributes)
        find_by(attributes) || create(attributes)
      end

      # Fetch first resource with the given attributes, or initialize a resource
      # with the attributes if one is not found.
      #
      # @example
      #   @user = User.find_or_initialize_by(email: "remi@example.com")
      #
      #   # Returns the first item in the collection if present:
      #   # Called via GET "/users?email=remi@example.com"
      #
      #   # If collection is empty:
      #   @user.email # => "remi@example.com"
      #   @user.new? # => true
      def find_or_initialize_by(attributes)
        find_by(attributes) || build(attributes)
      end

      # Create a resource and return it
      #
      # @example
      #   @user = User.create(:fullname => "Tobias Fünke")
      #   # Called via POST "/users/1" with `&fullname=Tobias+Fünke`
      #
      # @example
      #   @user = User.where(:email => "tobias@bluth.com").create(:fullname => "Tobias Fünke")
      #   # Called via POST "/users/1" with `&email=tobias@bluth.com&fullname=Tobias+Fünke`
      def create(attributes = {})
        _build(attributes).tap(&:save)
      end

      # Create a resource and return it, raises if there are validation or response errors
      #
      # @example
      #   @user = User.create!(:fullname => "Tobias Fünke")
      #   # Called via POST "/users/1" with `&fullname=Tobias+Fünke`
      #
      # @example
      #   @user = User.where(:email => "tobias@bluth.com").create!(:fullname => "Tobias Fünke")
      #   # Called via POST "/users/1" with `&email=tobias@bluth.com&fullname=Tobias+Fünke`
      def create!(attributes = {})
        _build(attributes).tap(&:save!)
      end

      # Fetch a resource and create it if it's not found
      #
      # @example
      #   @user = User.where(:email => "remi@example.com").find_or_create
      #
      #   # Returns the first item of the collection if present:
      #   # GET "/users?email=remi@example.com"
      #
      #   # If collection is empty:
      #   # POST /users with `email=remi@example.com`
      def first_or_create(attributes = {})
        fetch.first || create(attributes)
      end

      # Fetch a resource and build it if it's not found
      #
      # @example
      #   @user = User.where(:email => "remi@example.com").find_or_initialize
      #
      #   # Returns the first item of the collection if present:
      #   # GET "/users?email=remi@example.com"
      #
      #   # If collection is empty:
      #   @user.email # => "remi@example.com"
      #   @user.new? # => true
      def first_or_initialize(attributes = {})
        fetch.first || build(attributes)
      end

      # @private
      def clear_fetch_cache!
        instance_variable_set(:@_fetch, nil)
      end

      # @private
      def _build(attributes)
        resource = @parent.new(@params.merge(attributes))
        resource.request_headers = request_headers
        resource.request_options = request_options
        resource
      end
    end
  end
end
