module Expect
  require 'timeout'

  class Expecter
    attr_accessor :timeout
    def initialize
      @connection = nil
      @timeout = 2
    end
    def spawn(process)
    end
    def connect(host, user, passwd)
    end
    def ssh_connect(host, user, passwd)
      @connection = SshConnection.new(host, user, passwd)
    end
    def expect(expectArray)
      return [nil, nil, nil] unless @connection
      data = ''
      result = ['', '', true]
      begin
        expectContinue = false
        newdata = @connection.expect(@timeout)
        case newdata
        when nil
          result[2] = nil
        when :TIMEOUT
          result[2] = :TIMEOUT
        else
          data += newdata
          m = expectArray.detect {|item| item[0] == :DEFAULT || data.match(/#{item[0]}/i)}
          if m
            result[0] = data
            data = ''
            result[1] = m[0]
            result[2] = m[1]
            case m[1]
            when nil
            when :CLOSE
              close()
            else
              send m[1] if m[1]
            end
            expectContinue = true if m[2]
          else
            # Didn't match any expect items so continue reading
            expectContinue = true
          end
        end
      end while (expectContinue)
      result
    end
    def send(data)
      return nil unless @connection
      @connection.send data
    end
    def close
      return nil unless @connection
      @connection.close
      @connection = nil
    end
    def open?
      return true if @connection && @connection.open?
      return false
    end
  end

  class Process
  end

  class Connection
  end

  class SshConnection
    require 'rubygems'
    require 'net/ssh'
    def initialize(host, user, passwd)
      @data = ''
      @out_buf = ''
      @channel_open = false
      begin
        @session = Net::SSH.start(host, user, passwd)
      rescue Net::SSH::AuthenticationFailed
        raise 'Authentication Failed'
      end
      @channel = @session.open_channel
      @channel.on_success {|c| @channel_open = true}
      @channel.on_data {|c, d| @data += d if d}
      @channel.on_eof {|c| @channel_open = false}
      @channel.on_close {|c| @channel_open = false}
      @channel.on_confirm_open {@channel.send_request 'shell', nil, true}
    end
    def send(data)
      @out_buf += data unless data.empty?
      if @channel_open
        @channel.send_data @out_buf
        @out_buf = ''
      end
    end
    def expect(timeout)
      return nil unless @session
      @data = ''
      begin
        Timeout::timeout(timeout) do |t|
        @session.loop {@channel && @data.empty?}
      end
      @data
      rescue Timeout::Error
        return :TIMEOUT
      end
    end
    def close
      @session.close if @session
      @session = nil
      @channel = nil
      @channel_open = false
    end
    def open?
      return @session && @channel_open
    end
  end
end
