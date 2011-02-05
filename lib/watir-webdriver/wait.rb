# encoding: utf-8
module Watir
  module Wait

    class TimeoutError < StandardError
    end

    INTERVAL = 0.5

    class << self
      #
      # Wait until the block evaluates to true or times out.
      #

      def until(timeout = 30, message = nil, &block)
        end_time = ::Time.now + timeout

        until ::Time.now > end_time
          result = yield(self)
          return result if result
          sleep INTERVAL
        end

        raise TimeoutError, message_for(timeout, message)
      end

      #
      # Wait while the block evaluates to true or times out.
      #

      def while(timeout = 30, message = nil, &block)
        end_time = ::Time.now + timeout

        until ::Time.now > end_time
          return unless yield(self)
          sleep INTERVAL
        end

        raise TimeoutError, message_for(timeout, message)
      end

      private

      def message_for(timeout, message)
        err = "timed out after #{timeout} seconds"
        err << ", #{message}" if message

        err
      end
    end # class << self
  end # Wait

  module Waitable
    def wait_until(*args, &blk)
      Wait.until(*args, &blk)
    end

    def wait_while(*args, &blk)
      Wait.while(*args, &blk)
    end
  end

  #
  # Wraps an Element so that any subsequent method calls are
  # put on hold until the element is present (exists and is visible) on the page.
  #

  class WhenPresentDecorator
    def initialize(element, timeout, message = nil)
      @element = element
      @timeout = timeout
      @message = message
    end

    def method_missing(m, *args, &block)
      unless @element.respond_to?(m)
        raise NoMethodError, "undefined method `#{m}' for #{@element.inspect}:#{@element.class}"
      end

      Watir::Wait.until(@timeout, @message) { @element.present? }

      @element.__send__(m, *args, &block)
    end
  end # WhenPresentDecorator

  #
  # Convenience methods for things that eventually become present.
  #
  # Includers should implement a public #present? and a (possibly private) #selector_string method.
  #

  module EventuallyPresent
    #
    # Waits until the element is present.
    #
    # @see Watir::Wait
    #
    # Example:
    #   browser.button(:id, 'foo').when_present.click
    #   browser.div(:id, 'bar').when_present { |div| ... }
    #   browser.p(:id, 'baz').when_present(60).text
    #
    # @param [Integer] timeout seconds to wait before timing out
    #

    def when_present(timeout = 30)
      message = "waiting for #{selector_string} to become present"

      if block_given?
        Watir::Wait.until(timeout, message) { present? }
        yield self
      else
        WhenPresentDecorator.new(self, timeout, message)
      end
    end

    #
    # Waits until the element is present.
    #
    # @param [Integer] timeout seconds to wait before timing out
    #
    # @see Watir::Wait
    # @see Watir::Element#present?
    #

    def wait_until_present(timeout = 30)
      message = "waiting for #{selector_string} to become present"
      Watir::Wait.until(timeout, message) { present? }
    end

    #
    # Waits while the element is present.
    #
    # @param [Integer] timeout seconds to wait before timing out
    #
    # @see Watir::Wait
    # @see Watir::Element#present?
    #

    def wait_while_present(timeout = 30)
      message = "waiting for #{selector_string} to disappear"
      Watir::Wait.while(timeout, message) { present? }
    rescue Selenium::WebDriver::Error::ObsoleteElementError
      # it's not present
    end

  end # EventuallyPresent
end # Watir
