#-*- coding: utf-8 -*-

require 'raudio/error'
# require 'raudio/codec/xiph/libvorbis'
require 'raudio/codec/xiph/libvorbisfile'

module RAudio
  class Codec
    #== Raw audio class
    class Raw
      include RAudio

      def initialize(bufsize=4096)
        @info    = nil
        @file    = nil
        @filep   = nil
        @bufsize = 4096
      end

      # Open audio file.
      # [Arg1] filepath.
      # [Arg2] AudioInfo structure.
      # [Return] Open status.
      def open(file, ainfo=nil)
        raise Codec::FileError, \
        "File is already open - #{@file}" if @file
        @file, @info = file, ainfo
        @filep = File.open(file, 'r')
      end

      # Read audio file.
      # [Return] data length or nil(EOF).
      def read
        return @filep.read(@bufsize)
      end

      # Seek audio file.
      # [Arg1] seek sec.
      # [Return] true.
      def seek(sec)
        return true if @filep.seek(sec_to_byte(sec), IO::SEEK_SET) == 0
      end

      # Get current sec.
      # [Return] current sec.
      def tell
        return byte_to_sec(@filep.tell)
      end
      
      # Get total sec.
      # [Return] total sec or nil.
      def total
        return byte_to_sec(@filep.size)
      end

      # Get audio file information.
      # [Return] AudioInfo structure or nil.
      def info
        return @info
      end

      # Get audio file comments.
      # [Return] Comment hash or nil.
      def comment
        return {}
      end

      # Audio file close.
      # [Return] close status.
      def close
        @file = nil
        return @filep.close
      end

      def closed?
        return false if @file
        return true
      end
      
      # Shutdown decoder.
      # [Return] shutdown status.
      def shutdown
        return true
      end

      private
      #  convert sec to byte
      def sec_to_byte(sec)
        return @info.bits * @info.rate * @info.channels / 8 * sec
      end

      def byte_to_sec(byte)
        return byte / (@info.bits * @info.rate * @info.channels / 8)
      end
    end
  end
end
