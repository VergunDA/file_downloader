require_relative '../../lib/file_downloader'

RSpec.describe FileDownloader do

  let(:root) { Bundler.root.to_s }

  describe "#download_from_file" do

    let(:etag) { "\"etag\"" }
    let(:file_type) { 'jpeg' }
    let(:valid_headers) do
      {
        'content-type' => "image/#{file_type}",
        'content-length' => '12345',
        'Etag' => etag
      }
    end
    let(:head_response) do
      OpenStruct.new({
                       status: 200,
                       headers: valid_headers
                     })
    end
    let(:get_response) do
      OpenStruct.new({
                       status: 200,
                       headers: valid_headers,
                       body: "body"
                     })
    end

    before do
      allow(Faraday).to receive(:get).and_return(get_response)
      allow(Faraday).to receive(:head).and_return(head_response)
    end

    context "when arg empty" do

      before do
        described_class.download_from_file
      end

      it "set default value to downloads_path" do
        expect(described_class.downloads_path).to eq(Constants::Defaults::DOWNLOADS_PATH)
      end

      it "set default value to file_path" do
        expect(described_class.send(:file_path)).to be_nil
      end
    end

    context "when custom args" do

      let(:urls) { %w[http://valid.url invalid_url] }
      let(:file_name) { "#{JSON.parse(etag)}.#{file_type}" }
      let(:file_path) { root + "#{downloads_path}/#{file_name}" }
      let(:path) { "/spec/fixtures/tmp/file.txt" }
      let(:downloads_path) { "/spec/fixtures/tmp" }

      before do
        File.open(root + path, 'w+') { |file| file.write urls.join(' ') }
        File.delete(file_path) if File.exist?(file_path)
        described_class.download_from_file(path, downloads_path)
      end

      after do
        File.delete(file_path) if File.exist?(file_path)
      end

      it "return creates file" do
        expect(File.exist?(file_path)).to be_truthy
      end
    end
  end

  describe "#read_file" do
    let(:urls) { %w[http://valid.url invalid_url] }
    let(:path) { "/spec/fixtures/tmp/file.txt" }

    before do
      described_class.send(:init_file_path, path)
      File.open(root + path, 'w+') { |file| file.write urls.join(' ') }
    end

    it "return valid urls" do
      expect(described_class.send(:read_file)).to eq([urls.first])
    end

    it "return add invalid url error" do
      described_class.send(:read_file)
      expect(described_class.send(:logger).errors).to include(I18n.t('invalid_url', url: urls.last))
    end
  end

  describe "#process_valid_url" do

    it "do not call download file when file can't download" do
      allow(described_class).to receive(:can_download?).and_return(false)
      allow(described_class).to receive(:download_file)
      described_class.send(:process_valid_url, 'url')
      expect(described_class).not_to receive(:download_file)
    end

    it "do call download file when file can download" do
      allow(described_class).to receive(:can_download?).and_return(true)
      allow(described_class).to receive(:download_file)
      described_class.send(:process_valid_url, 'url')
      expect(described_class).to have_received(:download_file).once
    end
  end

  describe "#can_download?" do

    it "do not call meta_data_valid? when file can't download" do
      allow(described_class).to receive(:fetch_file_metadata).and_return(false)
      allow(described_class).to receive(:meta_data_valid?)
      described_class.send(:can_download?, 'url')
      expect(described_class).not_to receive(:meta_data_valid?)
    end

    it "do call meta_data_valid? when file can download" do
      allow(described_class).to receive(:fetch_file_metadata).and_return(true)
      allow(described_class).to receive(:meta_data_valid?)
      described_class.send(:process_valid_url, 'url')
      expect(described_class).to have_received(:meta_data_valid?).once
    end
  end

  describe "#fetch_file_metadata?" do

    let(:success_response) { OpenStruct.new(status: 200, headers: { name: 'value' }) }
    let(:bad_response) { OpenStruct.new(status: 404, headers: { name: 'value' }) }

    it "return headers when success_response" do
      allow(Faraday).to receive(:head).and_return(success_response)
      expect(described_class.send(:fetch_file_metadata, 'url')).to eq(success_response.headers)
    end

    it "return nil when bad_response" do
      allow(Faraday).to receive(:head).and_return(bad_response)
      expect(described_class.send(:fetch_file_metadata, 'url')).to be_nil
    end

    it "add error message to logger" do
      allow(Faraday).to receive(:head).and_return(bad_response)
      described_class.send(:fetch_file_metadata, 'url')
      expect(described_class.send(:logger).errors).to include(I18n.t(:file_is_unavailable, url: 'url'))
    end
  end

  describe "#download_file" do

    let(:success_response) { OpenStruct.new(status: 200, headers: { name: 'value' }) }
    let(:bad_response) { OpenStruct.new(status: 404, headers: { name: 'value' }) }

    it "call save file once when success response" do
      allow(Faraday).to receive(:get).and_return(success_response)
      allow(described_class).to receive(:save_file)
      described_class.send(:download_file, 'url')
      expect(described_class).to have_received(:save_file).once
    end

    it "return nil when bad_response" do
      allow(Faraday).to receive(:get).and_return(bad_response)
      expect(described_class.send(:download_file, 'url')).to be_nil
    end

    it "do not call save_file" do
      allow(Faraday).to receive(:get).and_return(bad_response)
      allow(described_class).to receive(:save_file)
      described_class.send(:download_file, 'url')
      expect(described_class).not_to receive(:save_file)
    end

    it "add error message to logger" do
      allow(Faraday).to receive(:get).and_return(bad_response)
      described_class.send(:download_file, 'url')
      expect(described_class.send(:logger).errors).to include(I18n.t(:file_is_unavailable, url: 'url'))
    end
  end

  describe "#file_name" do

    let(:etag) { "\"etag\"" }
    let(:content_type) { 'image/jpeg' }

    it "return expected when valid etag and content_type" do
      expected = JSON.parse(etag) + '.' + content_type.scan(Constants::Defaults::FILE_TYPES).first
      expect(described_class.send(:file_name, etag, content_type)).to eq(expected)
    end

    it "return expected when valid JSON::ParseError" do
      expected = JSON.parse(etag) + '.' + content_type.scan(Constants::Defaults::FILE_TYPES).first
      expect(described_class.send(:file_name, 'etag', content_type)).to eq(expected)
    end
  end

  describe "#meta_data_valid??" do

    let(:meta_data) do
      {
        'content-type' => 'image/jpeg',
        'content-length' => '12345',
        'Etag' => 'abcdef'
      }
    end
    let(:url) { "http://valid.url" }

    it "return true when valid" do
      expect(described_class.send(:meta_data_valid?, meta_data, url)).to be_truthy
    end

    context "when headers invalid" do

      let(:meta_data) { {} }

      it "return false when headers invalid" do
        expect(described_class.send(:meta_data_valid?, meta_data, url)).to be_falsey
      end

      it "puts correct message into logger when headers invalid" do
        described_class.send(:meta_data_valid?, meta_data, url)
        expect(described_class.send(:logger).errors).to include(I18n.t(:headers_invalid, url: url))
      end
    end

    context "when content type invalid" do

      let(:meta_data) do
        {
          'content-type' => 'xxx/adult-videos',
          'content-length' => '12345',
          'Etag' => 'abcdef'
        }
      end

      it "return false when headers invalid" do
        expect(described_class.send(:meta_data_valid?, meta_data, url)).to be_falsey
      end

      it "puts correct message into logger when headers invalid" do
        described_class.send(:meta_data_valid?, meta_data, url)
        expect(described_class.send(:logger).errors).to include(I18n.t(:invalid_content_type, url: url))
      end
    end

    context "when file too large" do

      let(:meta_data) do
        {
          'content-type' => 'image/jpeg',
          'content-length' => '123456789123456789123456789123456789',
          'Etag' => 'abcdef'
        }
      end

      it "return false when headers invalid" do
        expect(described_class.send(:meta_data_valid?, meta_data, url)).to be_falsey
      end

      it "puts correct message into logger when headers invalid" do
        described_class.send(:meta_data_valid?, meta_data, url)
        expect(described_class.send(:logger).errors).to include(I18n.t(:file_too_large, url: url))
      end
    end

    context "when file too small" do

      let(:meta_data) do
        {
          'content-type' => 'image/jpeg',
          'content-length' => '1',
          'Etag' => 'abcdef'
        }
      end

      it "return false when headers invalid" do
        expect(described_class.send(:meta_data_valid?, meta_data, url)).to be_falsey
      end

      it "puts correct message into logger when headers invalid" do
        described_class.send(:meta_data_valid?, meta_data, url)
        expect(described_class.send(:logger).errors).to include(I18n.t(:file_too_small, url: url))
      end
    end

    context "when out_of space" do

      let(:meta_data) do
        {
          'content-type' => 'image/jpeg',
          'content-length' => '99999',
          'Etag' => 'abcdef'
        }
      end

      before { allow(described_class).to receive(:current_free_space).and_return(1) }

      it "return false when headers invalid" do
        expect(described_class.send(:meta_data_valid?, meta_data, url)).to be_falsey
      end

      it "puts correct message into logger when headers invalid" do
        described_class.send(:meta_data_valid?, meta_data, url)
        expect(described_class.send(:logger).errors).to include(I18n.t(:out_of_space, url: url))
      end
    end
  end

  describe "#init_paths" do

    let(:path) { "/spec/fixtures/tmp/file.txt" }
    let(:downloads_path) { "/spec/fixtures/tmp" }


    before do
      allow(described_class).to receive(:init_file_path)
      allow(described_class).to receive(:init_download_path)
      described_class.send(:init_paths, path, downloads_path)
    end

    it "calls init_file_path once" do
      expect(described_class).to have_received(:init_download_path).once
    end

    it "calls init_download_path once" do
      expect(described_class).to have_received(:init_download_path).once
    end

  end

  describe "#init_file_path" do

    let(:path) { "/spec/fixtures/tmp/file.txt" }

    it "don't init @file_path when nil" do
      described_class.send(:init_file_path, nil)
      expect(described_class.send(:init_file_path, nil)).to be_nil
    end

    it "don't init @file_path when file invalid_path" do
      described_class.send(:init_file_path,'invalid path')
      expect(described_class.send(:file_path)).to be_nil
    end

    it "init @file path when valid in directory" do
      expected = root + path
      expect(described_class.send(:init_file_path, path)).to eq(expected)
    end

    it "init @file path when valid out of directory" do
      expected = root + path
      expect(described_class.send(:init_file_path, root + path)).to eq(expected)
    end
  end

  describe "#init_downloads_path" do

    let(:path) { "/spec/fixtures/tmp" }

    it "don't init @downloads_path when nil" do
      described_class.send(:init_download_path, nil)
      expect(described_class.send(:downloads_path)).to eq(Constants::Defaults::DOWNLOADS_PATH)
    end

    it "don't init @downloads_path when file invalid_path" do
      described_class.send(:init_download_path,'invalid path')
      expect(described_class.send(:downloads_path)).to be_nil
    end

    it "init @downloads_path when valid in directory" do
      expected = root + path
      expect(described_class.send(:init_download_path, path)).to eq(expected)
    end

    it "init @downloads_path when valid out of directory" do
      expected = root + path
      expect(described_class.send(:init_download_path, root + path)).to eq(expected)
    end
  end
end
