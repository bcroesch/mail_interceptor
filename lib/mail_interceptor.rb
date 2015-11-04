require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/array'
require "mail_interceptor/version"

module MailInterceptor
  class Interceptor
    attr_accessor :deliver_emails_to, :forward_emails_to, :env

    def initialize options = {}
      @deliver_emails_to = Array.wrap options[:deliver_emails_to]
      @env               = options.fetch :env, InterceptorEnv.new
    end

    def delivering_email message
      message.to = normalize_recipients(message.to).flatten.uniq unless message.to.nil?
      message.cc = normalize_recipients(message.cc).flatten.uniq unless message.cc.nil?
      message.bcc = normalize_recipients(message.bcc).flatten.uniq unless message.bcc.nil?
      
      mail.perform_deliveries = false if message.to.empty? && message.cc.empty? && message.bcc.empty?
    end

    private

    def normalize_recipients recipients
      return Array.wrap(recipients) unless env.intercept?

      recipients.map do |recipient|
        if deliver_emails_to.find { |regex| Regexp.new(regex, Regexp::IGNORECASE).match(recipient) }
          recipient
        else
          nil
        end
      end
    end

    def forward_emails_to_empty?
      Array.wrap(forward_emails_to).reject(&:blank?).empty?
    end
  end

  class InterceptorEnv
    def name
      Rails.env.upcase
    end

    def intercept?
      !Rails.env.production?
    end
  end
end
