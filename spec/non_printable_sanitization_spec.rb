require 'spec_helper'

class Rack::MockRackApp
  attr_reader :request_body

  def initialize
    @request_headers = {}
  end

  def call(env)
    @env = env
    @request_body = env['rack.input'].read
    [200, {'Content-Type' => 'text/plain'}, ['OK']]
  end

  def [](key)
    @env[key]
  end
end

describe ::NonPrintableSanitization do
  let(:app) { Rack::MockRackApp.new }
  let(:start_app) { described_class.new(app) }

  context "when called with a binary body POST request" do
    let(:request) { Rack::MockRequest.new(start_app) }
    let(:path) { "/some/path" }

    before(:each) do
      ::NonPrintableSanitization.skip_paths << /skippable/i
      request.post(path, :input => post_data, "CONTENT_TYPE" => content_type)
      ::NonPrintableSanitization.skip_paths.clear
    end

    context "with text/plain content" do
      let(:post_data) { "derp derp derp\0" }
      let(:content_type) { "text/plain" }

      it "sanitizes the non-printable \0" do
        expect(app.request_body).to eq("derp derp derp")
      end
    end

    context "with URL encoded content" do
      let(:post_data) { "derp%20derp%20derp%00" }
      let(:content_type) { "application/x-www-form-urlencoded" }

      it "sanitizes the non-printable \0" do
        expect(app.request_body).to eq("derp%20derp%20derp")
      end
    end

    context "when path is skipped" do
      context "with text/plain content" do
        let(:path) { "/skippable" }
        let(:post_data) { "derp derp derp\0" }
        let(:content_type) { "text/plain" }

        it "skips sanitize of the non-printable \0" do
          expect(app.request_body).to eq(post_data)
        end
      end
    end

    context "with multipart/form-data content" do
      let(:post_data) { "derp derp derp\0" }
      let(:content_type) { "multipart/form-data" }

      it "does not sanitize the non-printable \0" do
        expect(app.request_body).to eq(post_data)
      end
    end
  end
end

