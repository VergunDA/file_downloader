require_relative '../../lib/validator'
require_relative '../../lib/logger'
require 'sys/filesystem'

RSpec.describe Validator do

  include Validator
  include Sys

  describe "#url_valid?" do

    it "return true when url valid" do
      url = "http://valid.com"
      expect(url_valid? url).to be_truthy
    end

    it "return true when url invalid" do
      url = "valid.com@daf"
      expect(url_valid? url).to be_falsey
    end

    it "return true when url empty" do
      url = ""
      expect(url_valid? url).to be_falsey
    end

    it "return true when url not string" do
      url = []
      expect(url_valid? url).to be_falsey
    end
  end

  describe "#path_valid?" do

    it "return true when path valid" do
      path = "/spec/fixtures/urls.txt"
      expect(path_valid? path).to be_truthy
    end

    it "return true when path invalid" do
      path = "valid.com@daf"
      expect(path_valid? path).to be_falsey
    end

    it "return true when path not string" do
      path = []
      expect(path_valid? path).to be_falsey
    end
  end

  describe "#current_free_space" do

    let(:expected_size) do
      stat = Sys::Filesystem.stat('/')
      stat.blocks_free * stat.block_size
    end

    it "return true when path valid" do
      expect(current_free_space).to eq(expected_size)
    end
  end

  describe "#response_headers_valid?" do

    let(:valid_headers) do
      {
        'content-type' => 'image/jpeg',
        'content-length' => '12345',
        'Etag' => 'abcdef'
      }
    end
    let(:invalid_headers) do
      {
        'content-type' => 'image/jpeg',
        'content-length' => '12345',
        'Etag' => []
      }
    end

    it "return ture when valid headers" do
      expect(response_headers_valid?(valid_headers)).to be_truthy
    end

    it "return false when invalid headers" do
      expect(response_headers_valid?(invalid_headers)).to be_falsey
    end

    it "return false when empty headers" do
      expect(response_headers_valid?({})).to be_falsey
    end

  end

  describe "#space_available?" do

    it "return true when valid" do
      expect(space_available?(100)).to be_truthy
    end

    it "return false when invalid" do
      expect(space_available?(10_000_000_000_000)).to be_falsey
    end
  end

  describe "#content_type_valid?" do

    it "return true when valid" do
      expect(content_type_valid?('image/jpeg')).to be_truthy
    end

    it "return false when invalid" do
      expect(content_type_valid?('invalid')).to be_falsey
    end
  end

  describe "#max_size_valid?" do

    it "return true when valid" do
      expect(max_size_valid?(10_000)).to be_truthy
    end

    it "return false when invalid" do
      expect(max_size_valid?(1000_000_000)).to be_falsey
    end
  end

  describe "#min_size_valid??" do

    it "return true when valid" do
      expect(min_size_valid?(10_000)).to be_truthy
    end

    it "return false when invalid" do
      expect(min_size_valid?(1)).to be_falsey
    end
  end
end
