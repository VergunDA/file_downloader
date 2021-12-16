require_relative '../../lib/file_downloader'
require 'sys/filesystem'
include Sys

RSpec.describe FileDownloader do

  describe "#current_free_space" do

    let(:expected_size) do
      stat = Filesystem.stat('/')
      stat.blocks_free * stat.block_size
    end

    it "return true when path valid" do
      expect(described_class.send(:current_free_space)).to eq(expected_size)
    end
  end

  describe "#download_from_file" do

    it "return true when path valid" do
      expect(described_class.download_from_file).to be_truthy
    end
  end
end
