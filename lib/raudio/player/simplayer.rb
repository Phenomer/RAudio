#-*- coding: utf-8 -*-

require 'raudio/error'
require 'raudio/ao'
require 'raudio/volumemanager'
require 'raudio/codec/raw'

module RAudio
  #= Audio Player class
  class Player
    include RAudio

    #== Simple RAW Audio Player
    class SimPlayer
      def initialize(driver=0)
        @current_sec = 0
        @volume      = VolumeManager.new()
        @ao          = Output::AO.new
        @ao.set_driver(driver)
        @control     = :play
        @status      = :stop
        init_codec()
        @codec       = @init.new
      end
      attr_reader :status

      #=== Player Control

      # Play audio file.
      # [Arg1] filepath.
      # [Arg2] AudioInfo(optional).
      # [Return] true.
      def play(file, info = nil)
        @codec.open(file)
        @ao.open_live(@codec.info)
        @volume.set_info(@codec.info)
        @control = :play
        while check_control() && (buffer = @codec.read)
          snd = @volume.convert(buffer)
          @ao.play(snd, snd.size)
        end
        @ao.close()
        @codec.close()
      end

      # Play audio file(multi process)
      # [Arg1] filepath.
      # [Arg2] AudioInfo(optional).
      # [Return] true.
      def play_mp(file, info = nil)
        r, w = IO.pipe()
        @codec.open(file)
        @volume.set_info(@codec.info)
        @control = :play
        play_pid   = fork{
          w.close()
          @ao.open_live(@codec.info)
          until r.eof?
            snd = r.read(4096)
            @ao.play(snd, snd.bytesize)
          end
          @ao.close()
          r.close()
          exit 0
        }
        
        while check_control() && (buffer = @codec.read)
          w.write(@volume.convert(buffer))
        end
        w.close()
        Process.waitpid(play_pid)
        @codec.close()
      end

      # Pause player.
      # [Return] bool.
      def pause
        @control = :pause
      end

      # Restart player.
      # [Return] bool.
      def restart
        @control = :play
      end
      
      # Stop player.
      # [Return] bool.
      def stop
        @control = :stop
      end

      #=== Seek Audio File
      
      # Seek to head
      # [Return] current sec or nil.
      def head
        if @codec.closed?
          raise Player::CodecError, \
          'Stream is not open.'
        else
          @codec.seek(0)
        end
      end

      # Rewind
      # [Arg1] rewind sec.
      # [Return] current sec or nil.
      def rewind(sec)
        if @codec.closed?
          raise Player::CodecError, \
          'Stream is not open.'
        else
          @codec.seek(@codec.tell - sec)
        end
      end

      # Forward
      # [Arg1] forward sec.
      # [Return] current sec or nil.
      def forward(sec)
        if @codec.closed?
          raise Player::CodecError, \
          'Stream is not open.'
        else
          @codec.seek(@codec.tell + sec)
        end
      end

      #=== Volume Control

      # Set audio volume
      # [Arg1] volume value(-100..100).
      # [Return] current volume.
      def set_volume(volume)
        @volume.set_volume(volume)
      end

      # Mute audio volume.
      # [Return] current volume.
      def mute
        @volume.set_volume(VolumeManager::MIN_VOLUME)
      end

      # Maximize audio volume.
      # [Return] current volume.
      def maximize
        @volume.set_volume(VolumeManager::MAX_VOLUME)
      end

      #== Information

      # Get audio file information.
      # [Return] AudioFileInfo structure or nil.
      def info
        if @codec.closed?
          raise Player::CodecError, \
          'Stream is not open.'
        else
          return @codec.info()
        end
      end 

      # Get audio file comments.
      # [Return] AudioFileInfo structure or nil.
      def comment
        if @codec.closed?
          raise Player::CodecError, \
          'Stream is not open.'
        else
          return @codec.comment()
        end
      end 

      # Get current sec.
      # [Return] current sec or nil.
      def tell
        if @codec.closed?
          raise Player::CodecError, \
          'Stream is not open.'
        else
          return @codec.tell()
        end
      end

      # Get total sec.
      # [Return] total sec or nil.
      def total
        if @codec.closed?
          raise Player::CodecError, \
          'Stream is not open.'
        else
          return @codec.total()
        end
      end

      # Shutdown audio player.
      # [Return] shutdown status.
      def shutdown
        @ao.shutdown
        return @codec.shutdown()
      end

      private
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

      #=== Basic audio codec control methods.
      # Initialize audio codec.
      def init_codec
        @init = RAudio::Codec::Raw
      end
    end
  end
end
