module Sogou
  class Crawler
    # Set of all URIs which have been crawled
    attr_accessor :crawled
    # Queue of URIs to be crawled. Array which acts as a FIFO queue.
    attr_accessor :queue
    # Hash of options
    attr_accessor :options

    # Accepts the following options:
    # * timeout -- Time limit for the crawl operation, after which a Timeout::Error exception is raised.
    # * external -- Boolean; whether or not the crawler will go outside the original URI's host.
    # * exclude -- A URI will be excluded if it includes any of the strings within this array.
    # * useragent -- User Agent string to be transmitted in the header of all requests
    def initialize(options={})
      @crawled = Set.new
      @queue = []
      @options = {
        :timeout => 1.0/0, #Infinity
        :external => false,
        :exclude => [],
        :useragent => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36", #模拟chrom浏览器 agent
      }.merge(options)

    end

    # Given a URI object, the crawler will explore every linked page recursively using the Breadth First Search algorithm.
    # Whenever it downloads a page, it notifies observers with an HTTPResponse subclass object and the downloaded URI object.
    def crawl(start_uri)
      @queue << start_uri

      timeout(@options[:timeout]) {
        while(uri = @queue.shift)

          Net::HTTP.start(uri.host, uri.port) do |http|

            headers = {
              'User-Agent' => @options[:useragent]
            }

            head = http.head(uri.path, headers)
            next if head.content_type != "text/html" # If the page retrieved is not an HTML document, we'll choke on it anyway. Skip it

            resp = http.get(uri.path, headers)

            html = Nokogiri.parse(resp.body)
            a_tags = html.search("a")
            @queue = @queue + a_tags.collect do |t|
              begin
                next_uri = uri + t.attribute("href").to_s.strip
              rescue
                nil
              end
            end
            @queue = @queue.compact.uniq
          end
          @crawled << uri
        end
      }
    end
  end
end
