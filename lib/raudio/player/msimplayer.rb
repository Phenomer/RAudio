#-*- coding: utf-8 -*-

require 'raudio/error'
require 'raudio/ao'
require 'raudio/volumemanager'
require 'raudio/codec/raw'
require 'json'

module RAudio
  #= Audio Player class
  class Player
    include RAudio
    #== Simple RAW Audio Player(multi process)
    class MSimPlayer
      def initialize(driver=0)
        @volume = VolumeManager.new
        @ao     = nil
        @init   = nil
        @codec  = nil
        init_codec()
        # @pb     = MSimPlayerBackend.new(@ao, @codec)
        @pb     = MSimPlayerBackend.new(driver, @init)
      end
      # attr_reader :status

      #=== Player Control

      # Play audio file.
      # [Arg1] filepath.
      # [Arg2] AudioInfo(optional).
      # [Return] true.
      def play(file, info = nil)
        return @pb.play(file, @volume, info)
      end

      # Pause player.
      # [Return] bool.
      def pause
        return @pb.control('pause')
      end

      # Restart player.
      # [Return] bool.
      def restart
        return @pb.control('restart')
      end
      
      # Stop player.
      # [Return] bool.
      def stop
        return @pb.control('stop')
      end

      #=== Seek Audio File
      
      # Seek to head
      # [Return] current sec or nil.
      def head
        return @pb.control('head')
      end

      # Rewind
      # [Arg1] rewind sec.
      # [Return] current sec or nil.
      def rewind(sec)
        return @pb.control("rewind #{sec}")
      end

      # Forward
      # [Arg1] forward sec.
      # [Return] current sec or nil.
      def forward(sec)
        return @pb.control("forward #{sec}")
      end

      #=== Volume Control

      # Set audio volume
      # [Arg1] volume value(-100..100).
      # [Return] current volume.
      def set_volume(volume)
        v = @pb.control("set_volume #{volume}")
        return v unless v
        return @volume.set_volume(v.to_i)
      end

      # Mute audio volume.
      # [Return] current volume.
      def mute
        v = @pb.control("set_volume #{VolumeManager::MIN_VOLUME}")
        return v unless v
        return @volume.set_volume(v.to_i)
      end

      # Maximize audio volume.
      # [Return] current volume.
      def maximize
        v = @pb.control("set_volume #{VolumeManager::MAX_VOLUME}")
        return v unless v
        return @volume.set_volume(v.to_i)
      end

      #== Information

      # Get audio file information.
      # [Return] AudioFileInfo structure or nil.
      def info
        return JSON.parse(@pb.control('info'))
      end 

      # Get audio file comments.
      # [Return] AudioFileInfo structure or nil.
      def comment
        return JSON.parse(@pb.control('comment'))
      end 

      # Get current sec.
      # [Return] current sec or nil.
      def tell
        return @pb.control('tell')
      end

      # Get total sec.
      # [Return] total sec or nil.
      def total
        return @pb.control('total')
      end

      def status
        return @pb.control('status')
      end

      # Shutdown audio player.
      # [Return] shutdown status.
      def shutdown
        return @pb.control('shutdown')
        # @ao.shutdown
        # return @codec.shutdown()
      end

      private

      #=== Basic audio codec control methods.
      # Initialize audio codec.
      def init_codec
        @init = RAudio::Codec::Raw
      end
    end


    private
    class MSimPlayerBackend
      def initialize(driver, initcodec)
        @ao      = nil
        @driver  = driver
        @init    = initcodec
        @codec   = nil
        @file    = nil
        @volume  = nil
        @control = nil
        @status  = nil
        @ctrl_r, @ctrl_w = nil, nil
        @stat_r, @stat_w = nil, nil
      end

      def control(command)
        unless @ctrl_w && @stat_r
          return false
          raise Player::PlayerError,
          'Contloller or Player was not open.'
        end
        begin
          @ctrl_w.puts(command)
        rescue Errno::EPIPE => err
          STDERR.printf("Error: %s\n", err)
        end

        begin
          next until line = @stat_r.gets
        rescue IOError => err
          STDERR.printf("Error: %s\n", err)
          return nil
        end
        return line.chomp
      end

      def play(file, volume, info=nil)
        @file   = file
        @volume = volume
        @ctrl_r, @ctrl_w = IO.pipe # Controller - Decoder
        @stat_r, @stat_w = IO.pipe # Decoder - Controller
        pid = fork{
          @ctrl_w.close
          @stat_r.close

          @ao     = Output::AO.new
          @ao.set_driver(@driver)
          @codec  = @init.new
          @codec.open(file)
          @ao.open_live(@codec.info)
          @volume.set_info(@codec.info)
          @control = :play
          @status  = :stop

          # Player
          play_t = Thread.start(){
            Thread.pass
            while check_control() && (buffer = @codec.read)
              snd = @volume.convert(buffer)
              @ao.play(snd, snd.size)
            end
            @status = :stop
          }
          play_t.abort_on_exception = true
          
          # Controller
          ctrl_t = Thread.start(){
            Thread.pass
            while (command = @ctrl_r.gets)
              result = call_command(command.chomp)
              @stat_w.puts(result.to_s.chomp)
            end
          }
          ctrl_t.abort_on_exception = true

          sleep 0.1 while play_t.alive? && ctrl_t.alive? 
          play_t.kill
          ctrl_t.kill
          @file    = nil
          @volume  = nil
          @control = nil
          @status  = nil
          @ao.close()
          @codec.close()
        }
        @ctrl_r.close
        @stat_w.close

        trap(:INT){Process.kill(:INT, pid)}
        Process.waitpid(pid)

        @ctrl_w.close
        @stat_r.close
        @ctrl_r, @ctrl_w = nil, nil
        @stat_r, @stat_w = nil, nil
      end

      private
      def call_shutdown
        return @control = :stop
      end

      # Pause player.
      # [Return] bool.
      def call_pause
        return @control = :pause
      end

      # Restart player.
      # [Return] bool.
      def call_restart
        return @control = :play
      end
      
      # Stop player.
      # [Return] bool.
      def call_stop
        return @control = :stop
      end

      #=== Seek Audio File
      
      # Seek to head
      # [Return] current sec or nil.
      def call_head
        if @codec.closed?
          raise Player::CodecError, \
          'Stream is not open.'
        else
          return @codec.seek(0)
        end
      end

      # Rewind
      # [Arg1] rewind sec.
      # [Return] current sec or nil.
      def call_rewind(sec)
        if @codec.closed?
          raise Player::CodecError, \
          'Stream is not open.'
        else
          return false if (@codec.tell - sec) < 0
          return @codec.seek(@codec.tell - sec)
        end
      end

      # Forward
      # [Arg1] forward sec.
      # [Return] current sec or nil.
      def call_forward(sec)
        if @codec.closed?
          raise Player::CodecError, \
          'Stream is not open.'
        else
          return false if (@codec.tell + sec) >= @codec.total
          return @codec.seek(@codec.tell + sec)
        end
      end

      #=== Volume Control

      # Set audio volume
      # [Arg1] volume value(-100..100).
      # [Return] current volume.
      def call_set_volume(volume)
        return @volume.set_volume(volume)
      end

      # Mute audio volume.
      # [Return] current volume.
      def call_mute
        return @volume.set_volume(VolumeManager::MIN_VOLUME)
      end

      # Maximize audio volume.
      # [Return] current volume.
      def call_maximize
        return @volume.set_volume(VolumeManager::MAX_VOLUME)
      end

      #== Information

      # Get audio file information.
      # [Return] AudioFileInfo structure or nil.
      def call_info
        if @codec.closed?
          raise Player::CodecError, \
          'Stream is not open.'
        else
          i = Hash.new
          @codec.info().each_pair{|k, v|
            i[k] = v
          }
          return i
        end
      end 

      # Get audio file comments.
      # [Return] AudioFileInfo structure or nil.
      def call_comment
        if @codec.closed?
          raise Player::CodecError, \
          'Stream is not open.'
        else
          return @codec.comment()
        end
      end 

      # Get current sec.
      # [Return] current sec or nil.
      def call_tell
        if @codec.closed?
          raise Player::CodecError, \
          'Stream is not open.'
        else
          return @codec.tell()
        end
      end

      # Get total sec.
      # [Return] total sec or nil.
      def call_total
        if @codec.closed?
          raise Player::CodecError, \
          'Stream is not open.'
        else
          return @codec.total()
        end
      end

      def call_command(command)
        return false unless @control && @status
        case command
        when 'pause'
          return call_pause()
        when 'restart'
          return call_restart()
        when 'stop'
          return call_stop()
        when 'head'
          return call_head()
        when /rewind\s+(\d+)/
          return call_rewind($1.to_i)
        when /forward\s+(\d+)/
          return call_forward($1.to_i)
        when /set_volume\s+(\d+)/
          return call_set_volume($1.to_i)
        when 'info'
          return call_info().to_json
        when 'comment'
          return call_comment().to_json
        when 'tell'
          return call_tell()
        when 'total'
          return call_total()
        when 'status'
          return @status
        when 'shutdown'
          return call_shutdown()
        else
          raise Player::PlayerError,
          "Unknown command - #{command}"
        end
      end

      def check_control
        loop {
          case @control
          when :play
            @status = :play
            return true
          when :stop
            @status = :stop
            return false
          when :pause
            @status = :pause
            sleep 0.1
            next
          else
            raise Player::PlayerError, \
            "Unknown command - #{@control}"
          end
        }
      end
    end

  end
end
