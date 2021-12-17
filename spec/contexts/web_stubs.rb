RSpec.shared_context 'web stubs' do

  let(:valid_headers) do
    ->(etag) {
      {
        'content-type' => "image/jpeg",
        'content-length' => '12345',
        'Etag' => etag.to_json
      }
    }
  end

  let(:head_response) do
    ->(etag) {
      OpenStruct.new({
                       status: 200,
                       headers: valid_headers[etag]
                     })
    }
  end

  let(:get_response) do
    ->(etag, status) {
      OpenStruct.new({
                       status: status,
                       headers: valid_headers[etag],
                       body: etag
                     })
    }
  end

  let(:get_stub) {
    allow(Faraday).to receive(:get) do |args|
      raise Faraday::TimeoutError if args == timeout_url

      status = args == invalid_status_url ?  404 : 200
      get_response[args.split('//').last, status]
    end
  }

  let(:head_stub) {
    allow(Faraday).to receive(:head) { |args|
      head_response[args.split('//').last]
    }
  }
end
