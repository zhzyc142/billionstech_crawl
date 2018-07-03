require 'set'
require 'net/http'
require 'nokogiri'
require 'faraday'
require 'timeout'
require 'pry'
require 'uuidtools'
module BillionstechCrawl
  module Sogou
    class Crawler
      # Set of all URIs which have been crawled
      attr_accessor :crawled
      # Queue of URIs to be crawled. Array which acts as a FIFO queue.
      attr_accessor :queue
      # Hash of options
      attr_accessor :options

      #faraday
      attr_accessor :conn


      # Accepts the following options:
      # * timeout -- Time limit for the crawl operation, after which a Timeout::Error exception is raised.
      # * external -- Boolean; whether or not the crawler will go outside the original URI's host.
      # * exclude -- A URI will be excluded if it includes any of the strings within this array.
      # * useragent -- User Agent string to be transmitted in the header of all requests
      # * out_put_path
      def initialize(options={})
        @crawled = Set.new
        @queue = []
        @options = {
        }.merge(options)
        @conn = Faraday.new(headers:  {
          "Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
          "Accept-Encoding"=>"gzip, deflate",
          "Accept-Language"=>"zh-CN,zh;q=0.9,en;q=0.8",
          "Cache-Control"=>"max-age=0",
          "Connection"=>"keep-alive",
          "Cookie"=>"CXID=EEEB6E21E1B4C6C5B9B6F0547210FE72; SUID=6F0C767B5B68860A5B286934000A9550; SUV=00C027296FC53E785B28B973F2EAE371; ad=Blllllllll2b3p61lllllV71OPGlllllWTYGbZllllYlllll4Vxlw@@@@@@@@@@@; IPLOC=CN1100; ABTEST=8|1530514805|v1; weixinIndexVisited=1; JSESSIONID=aaaAVJE7sNPHf4cO4hgrw; sct=1; PHPSESSID=m7ml54s1tmr08rvgf9fnjfkr60; SUIR=2A7E111A61640E9FDE2E56F061EB9FFC; SNUID=E2B4DBD2AAACD9AA4C7C4EEFAA91693C",
          "Host"=>"weixin.sogou.com",
          "Upgrade-Insecure-Requests"=>"1",
          "User-Agent"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36",
          "Pragma"=>"no-cache"}.merge(options))
      end

      # Given a URI object, the crawler will explore every linked page recursively using the Breadth First Search algorithm.
      # Whenever it downloads a page, it notifies observers with an HTTPResponse subclass object and the downloaded URI object.
      def crawl(start_url)
        @queue << start_url

        # Timeout.timeout(@options[:timeout]) {
          while(url = @queue.shift)
            unless @crawled.include? url

              p url
              file_name = UUIDTools::UUID.sha1_create(UUIDTools::UUID_URL_NAMESPACE, url).to_s + ".html"
              file_path = @options["out_put_path"] + "/out/" + file_name
              system("curl '#{url}' -o #{file_path}")
              # @conn.headers["Host"] = "weixin.sogou.com"
              # resp = @conn.get(url)
              html = Nokogiri.parse(File.open(file_path))
              document_list(html)
              a_tags = html.search("#pagebar_container a")
              # @queue = @queue + a_tags.collect do |t|
              #   begin
              #     next_url = "http://weixin.sogou.com/weixin" + t.attribute("href").to_s.strip
              #     @crawled.include?(next_url) ? nil : next_url
              #   rescue
              #     nil
              #   end
              # end
              # @queue = @queue.compact.uniq
              @crawled << url
            end
          end
        # }
      end

      def document_list html
        html.search(".news-list .img-box a").each do |t|
          p t.attribute("href").to_s
          url = (t.attribute("href").to_s).strip
          unless @crawled.include? url
            file_name = UUIDTools::UUID.sha1_create(UUIDTools::UUID_URL_NAMESPACE, url).to_s + ".html"
            file_path = @options["out_put_path"] + "/out/"
            p url
            system("wget -O #{file_path + file_name} '#{url}'")

            translate_src_to_local(file_path + file_name)
            # system("curl '#{url}' -o #{file_path} --cookie \"rewardsn=; wxtokenkey=777\" ")
            @crawled << url
          end
        end
      end

      def translate_src_to_local data_file_path
        str = File.read(data_file_path)
        str.scan(/data-src=\"[\w\?\=\:\/.]*"/).each do |key|
          url = key[10..-2] # 去除 data-src=\" \"
          file_name = UUIDTools::UUID.sha1_create(UUIDTools::UUID_URL_NAMESPACE, url).to_s
          file_path = @options["out_put_path"] + "/out/resource/"
          FileUtils.mkdir(file_path) unless File.exist?(file_path)
          system("wget -O #{file_path + file_name} '#{url}'")
          str.gsub!(key, "data-src=\"/out/resource/#{file_name}\"")
        end
        # str = str.gsub("\n", "").gsub("\r", "")
        # # str = str.gsub(/(?i)(<script)[\s\S]*?((<\/script>))/, "")
        # str = str.gsub(/<script(?!.*(document.write).*)<\/script>/, "")
        html = Nokogiri.parse(str)
        html.search("img").each do |x|
          if x.attributes["data-src"]
            if x.attributes["class"]
              x.attributes["class"].value = "lazyload " + x.attributes["class"].value
            else
              x["class"] = "lazyload"
            end
          end
        end
        f = File.open(data_file_path, "w")
        f.write(html.to_html)
        f.write('<script src="/out/lazysizes.js" async=""></script>')
        f.close
      end
    end
  end
end
