
require 'apartment/elevators/generic'
require 'public_suffix'
require 'apartment/elevators/subdomain'
module Apartment
  module Elevators
    class ActiveWebsite < Subdomain

      def self.excluded_subdomains
        @excluded_subdomains ||= []
      end

      def self.excluded_subdomains=(arg)
        @excluded_subdomains = arg
      end

      def parse_tenant_name(request)
        request_subdomain = subdomain(request.host)

        # If the domain acquired is set to be excluded, set the tenant to whatever is currently
        # next in line in the schema search path.
        tenant = if self.class.excluded_subdomains.include?(request_subdomain)
        else
          request_subdomain
        end

        tenant.presence
      end	


      def by_domain(request)
        website = User.find_by(subdomain: request.host.split(".").first)
        website && website.subdomain
      end

      def call(env)
        request = Rack::Request.new(env)
        database = @processor.call(request)
        if database
           Apartment::Tenant.switch!(database)
          if User.where(subdomain: database).exists?
             Apartment::Tenant.switch(database) { @app.call(env) }
          else
           ::NotFound.new(Rails.root.join('public/404.html')).call(env)
           end
        else
          Apartment::Tenant.switch("public"){ @app.call(env) }
        end
      end
     protected

      # *Almost* a direct ripoff of ActionDispatch::Request subdomain methods

      # Only care about the first subdomain for the database name
      def subdomain(host)
        subdomains(host).first
      end

      def subdomains(host)
        host_valid?(host) ? parse_host(host) : []
      end

      def host_valid?(host)
        !ip_host?(host) && domain_valid?(host)
      end

      def ip_host?(host)
        !/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/.match(host).nil?
      end

      def domain_valid?(host)
        PublicSuffix.valid?(host, ignore_private: true)
      end

      def parse_host(host)
         host.split(".")
      end
    end
  end
end
