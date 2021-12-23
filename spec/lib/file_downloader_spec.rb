require_relative '../../lib/file_downloader'
require_relative '../spec_helpers'

RSpec.describe FileDownloader do

  describe "#download_from_file" do

    include_context 'web stubs'

    let(:root) { Bundler.root.to_s }
    let(:valid_url) { 'https://valid.com' }
    let(:timeout_url) { 'https://timeout.com' }
    let(:invalid_url) { 'invalid.com' }
    let(:invalid_status_url) { 'https://invalidstatus.com' }
    let(:invalid_head_url) { 'https://invalidhead.com' }
    let(:empty_etag_url) { 'https://emptyetag.com' }
    let(:string_etag_url) { 'https://stringetag.com' }
    let(:already_exists_url) { 'https://alreadyexists.com ' }
    let(:urls) { [invalid_url, timeout_url, valid_url, invalid_status_url, invalid_head_url, empty_etag_url, string_etag_url, already_exists_url] }
    let(:path) { "/spec/fixtures/urls.txt" }
    let(:downloads_path) { root + '/spec/fixtures/tmp' }
    let(:expected_path) do
      ->(url) {
        name = url == empty_etag_url ? 'image_1' : url.split('//').last
        "#{downloads_path}/#{name}.jpeg"
      }
    end
    let(:downloaded_file) { File.open("#{downloads_path}/alreadyexists.com.jpeg", 'w+') { |file| file.write "alreadyexists" } }
    let(:logger) { Logger.new }

    before do
      get_stub
      head_stub
    end

    context "when valid args" do

      before do
        downloaded_file
        allow(described_class).to receive(:logger) { logger }
        allow(Time).to receive(:now).and_return(1)
        described_class.download_from_file(path, downloads_path)
      end

      after do
        Dir.foreach(downloads_path) do |f|
          fn = File.join(downloads_path, f)
          File.delete(fn) if f != '.' && f != '..'
        end
      end

      it "creates file from valid_url" do
        expect(File.exist?(expected_path[valid_url])).to be_truthy
      end

      it "add correct data to file" do
        name = valid_url.split('//').last
        expect(File.read(expected_path[valid_url])).to eq(name)
      end

      it "creates file from empty etag url" do
        expect(File.exist?(expected_path[empty_etag_url])).to be_truthy
      end

      it "add correct data to empty etag file" do
        expect(File.read(expected_path[empty_etag_url])).to eq('body')
      end

      it "creates file from string etag url" do
        expect(File.exist?(expected_path[string_etag_url])).to be_truthy
      end

      it "add correct data to file string etag url" do
        name = string_etag_url.split('//').last
        expect(File.read(expected_path[string_etag_url])).to eq(name)
      end

      it "do not create files from invalid url" do
        expect(File.exist?(expected_path[invalid_url])).to be_falsey
      end

      it "do not create files from timeout url" do
        expect(File.exist?(expected_path[timeout_url])).to be_falsey
      end

      it "do not create files from invalid status url" do
        expect(File.exist?(expected_path[invalid_status_url])).to be_falsey
      end

      it "add timeout error to log" do
        expect(logger.errors).to include(I18n.t(:timeout_error, url: timeout_url))
      end

      it "add invalid url error to log" do
        expect(logger.errors).to include(I18n.t(:invalid_url, url: invalid_url))
      end

      it "add invalid status url error to log" do
        expect(logger.errors).to include(I18n.t(:file_is_unavailable, url: invalid_status_url))
      end
    end

    context "when invalid parameters" do

      let(:invalid_path) { "invalid_path" }
      let(:downloads_path) { root + '/spec/fixtures/tmp' }

      it "puts expected message when invalid file path" do
        expected = "#{I18n.t(:start)}\n#{I18n.t(:invalid_path, value: invalid_path)}\n"
        expect {
          described_class.download_from_file(invalid_path, downloads_path)
        }.to output(expected).to_stdout
      end

      it "puts expected message when invalid download path" do
        expected = "#{I18n.t(:start)}\n#{I18n.t(:invalid_download_path, value: invalid_path)}\n"
        File.open(root + path, 'w+') { |file| file.write urls.join(' ') }
        expect {
          described_class.download_from_file(path, invalid_path)
        }.to output(expected).to_stdout
      end
    end

    context "when valid urls count grater than batch size" do

      let(:urls) { Array.new(10) { |i| "http://valid#{i}.com" } }
      let(:path) { "/spec/fixtures/10_valid_urls.txt" }

      before do
        described_class.download_from_file(path, downloads_path)
      end

      after do
        Dir.foreach(downloads_path) do |f|
          fn = File.join(downloads_path, f)
          File.delete(fn) if f != '.' && f != '..'
        end
      end

      it "creates files from valid_urls" do
        urls.each { |url|
          expected_path = "#{downloads_path}/#{url.split('//').last}.jpeg"
          expect(File.exist?(expected_path)).to be_truthy
        }
      end

      it "creates files with correct data" do
        urls.each { |url|
          name = url.split('//').last
          expected_path = "#{downloads_path}/#{name}.jpeg"
          expect(File.read(expected_path)).to eq(name)
        }
      end
    end
  end
end
