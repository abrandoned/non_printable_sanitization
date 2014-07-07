require 'rack'
require 'rack/request'
require 'stringio'
require 'uri'
require "non_printable_sanitization/version"

class NonPrintableSanitization
  def initialize(app, options = {})
    @app = app
    @options = options
  end

  def call(env)
    request = ::Rack::Request.new(env)

    if request.content_length.to_i > 0 # check we even have data
      if !request.get? && !request.delete? # make sure it's not a GET/DELETE request
        unless request_is_file_upload?(env) # make sure we don't want binary data
          remove_non_printable_characters!(env)
        end
      end
    end

    @app.call(env)
  end

  private

  def is_url_encoded?(env)
    content_type = env["CONTENT_TYPE"] || "none"
    content_type.downcase.include?("urlencoded")
  end

  def remove_non_printable_characters!(env)
    input = env["rack.input"].read
    
    if input && input.size > 0
      url_encoded = is_url_encoded?(env)
      input = ::URI.decode(input) if url_encoded
      input.gsub!(/[^[:print:]]/, "")
      input = ::URI.encode(input) if url_encoded
      env["rack.input"] = StringIO.new(input)
    end
  ensure
    env["rack.input"].rewind
  end

  def request_is_file_upload?(env)
    content_type = env["CONTENT_TYPE"] || "none"
    content_type.downcase.include?("form-data")
  end
end
