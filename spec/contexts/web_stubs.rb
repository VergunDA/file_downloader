RSpec.shared_context 'web stubs' do

  let(:valid_headers) do
    ->(etag) {
      headers = {
        'content-type' => "image/jpeg",
        'content-length' => '12345'
      }
      headers['Etag'] = etag == 'stringetag.com' ? etag : etag&.to_json
      headers
    }
  end

  let(:head_response) do
    ->(etag, status) {
      OpenStruct.new({
                       status: status,
                       headers: valid_headers[etag]
                     })
    }
  end

  let(:get_response) do
    ->(etag, status) {
      OpenStruct.new({
                       status: status,
                       headers: valid_headers[etag],
                       body: etag || "body"
                     })
    }
  end

  let(:get_stub) {
    allow(Faraday).to receive(:get) do |args|
      raise Faraday::TimeoutError if args == "https://timeout.com"

      status = args == "https://invalidstatus.com" ?  404 : 200
      etag = args == "https://emptyetag.com" ? nil : args.split('//').last
      get_response[etag, status]
    end
  }

  let(:head_stub) {
    allow(Faraday).to receive(:head) { |args|
      status = args == "https://invalidhead.com" ?  404 : 200
      etag = args == "https://emptyetag.com" ? nil : args.split('//').last
      head_response[etag, status]
    }
  }
end
