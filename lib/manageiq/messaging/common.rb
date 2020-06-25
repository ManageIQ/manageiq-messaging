module ManageIQ
  module Messaging
    module Common
      private

      def encode_body(headers, body)
        return body if body.kind_of?(String)
        headers[:encoding] = encoding
        case encoding
        when "json"
          JSON.generate(body)
        when "yaml"
          body.to_yaml
        else
          raise "unknown message encoding: #{encoding}"
        end
      end

      def decode_body(headers, raw_body)
        return raw_body unless headers.kind_of?(Hash)
        case headers["encoding"]
        when "json"
          JSON.parse(raw_body)
        when "yaml"
          YAML.safe_load(raw_body)
        else
          raw_body
        end
      rescue => e # JSON or YAML parsing error
        logger.error("Error decoding message body: #{e.message}")
        logger.error(e.backtrace.join("\n"))
        raw_body
      end

      def payload_log(payload)
        payload.to_s[0..100]
      end

      def auto_ack?(options)
        options.key?(:auto_ack) ? options[:auto_ack] : true
      end
    end
  end
end
