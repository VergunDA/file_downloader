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
                       body: etag
                     })
    }
  end

  let(:get_stub) {
    allow(Faraday).to receive(:get) do |args|
      raise Faraday::TimeoutError if args == "https://timeout.com"

      status = args == "https://invalidstatus.com" ?  404 : 200
      get_response[args.split('//').last, status]
    end
  }

  let(:head_stub) {
    allow(Faraday).to receive(:head) { |args|
      status = args == "https://invalidhead.com" ?  404 : 200
      head_response[args.split('//').last, status]
    }
  }
end
