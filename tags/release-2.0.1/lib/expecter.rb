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
            # but only if the connection is still open
            if @connection.open?
              expectContinue = true
            end
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
      @channel_open = true
      @session = nil
      @channel = nil
      begin
        @session = Net::SSH.start(host, user, :password => passwd)
      rescue Net::SSH::AuthenticationFailed
        raise 'Authentication Failed'
      end
      @session.open_channel do |ch|
        @channel = ch
        ch.on_eof {|c| @channel_open = false}
        ch.on_close {|c| @channel_open = false}
        @channel.send_channel_request 'shell' do |ch, success|
          if success
            ch.on_data {|c, d| @data += d if d }
            @channel_open = true
          else
            @channel_open = false
          end
        end
      end
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
          @session.loop { @channel_open && @data.empty?}
        end
        @data
      rescue Timeout::Error
        return :TIMEOUT
      rescue TypeError
        # If the channel has closed from the remote end and we haven't
        # received the notification, net-ssh reads a nil but tries to
        # append it to the data string resulting in this error.
        # We treat this situation as if the connection has closed.
        self.close
        return nil
      rescue Exception => e
        puts "[EXCEPTION] #{e}"
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
