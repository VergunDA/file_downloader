require_relative '../../lib/validator'

RSpec.describe Validator do

  include Validator

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
      path = "/rspec/fixtures/valid_file.txt"
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
end
