#-*- coding: utf-8 -*-

require 'raudio/error'
require 'raudio/codec/mpg123/libmpg123'
require 'kconv'

module RAudio
  class Codec
    #== Vorbis decoder class(vorbis)
    class Mpg123
      include RAudio
      include Codec::LibMpg123

      def initialize(bufsize=4096)
        @file    = nil
        @buffer,  @bufsize = nil, 4096
        @mherr,   @done    = Mpg123_Errors['MPG123_OK'], 0
        @channel, @encode, @rate = -1, -1, -1
        err = Codec::LibMpg123.mpg123_init()
        error_check(err)
        @mhptr   = Codec::LibMpg123.mpg123_new(nil, @mherr)
        raise Codec::CodecError, 
        sprintf("Codec error - %s", error_string) if @mhptr.null?
      end

      # Open audio file.
      # [Arg1] filepath.
      # [Arg2] AudioInfo structure.
      # [Return] Open status.
      def open(file, ainfo=nil)
        raise Codec::FileError, \
        "File is already open - #{@file}" if @file
        err = Codec::LibMpg123.mpg123_open(@mhptr, file)
        error_check(err)
        r = DL::CPtr.new(@rate)
        c = DL::CPtr.new(@channel)
        e = DL::CPtr.new(@encode)
        err = Codec::LibMpg123.mpg123_getformat(@mhptr, r.ref,
                                                c.ref, e.ref)
        error_check(err)
        err = Codec::LibMpg123.mpg123_format_none(@mhptr)
        error_check(err)
        @channel = c.ref.to_s(DL::SIZEOF_INT ).unpack('i')[0]
        @encode  = e.ref.to_s(DL::SIZEOF_INT ).unpack('i')[0]
        @rate    = r.ref.to_s(DL::SIZEOF_LONG).unpack('l')[0]
        err = Codec::LibMpg123.mpg123_format(@mhptr, @rate,
                                             @channel, @encode)
        error_check(err)
        err = Codec::LibMpg123.mpg123_scan(@mhptr) # ID3tag scan
        error_check(err)
        @bufsize = Codec::LibMpg123.mpg123_outblock(@mhptr)
        @buffer  = DL.malloc(@bufsize)
        @file = file
        return true
      end

      # Read audio file.
      # [Return] raw audio data or nil(EOF).
      def read
        raise Codec::FileError, 'File is not opened.' if closed?
        # printf("%s%d/%d", "\b" * 10, tell, total)
        # seek(tell() + 1)
        err = Codec::LibMpg123.mpg123_read(@mhptr,
                                           @buffer,
                                           @bufsize,
                                           DL::CPtr.new(@done).ref)
        return nil unless error_check(err)
        buffer = DL::CPtr.new(@buffer).to_str(@bufsize)
        return buffer
      end

      # Seek audio file.
      # [Arg1] seek sec.
      # [Return] true.
      def seek(sec)
        raise Codec::FileError, 'File is not opened.' if closed?
        frame = Codec::LibMpg123.mpg123_timeframe(@mhptr, sec)
        error_check(frame) if frame < 0
        Codec::LibMpg123.mpg123_seek_frame(@mhptr, frame, IO::SEEK_SET)
        return true
      end

      # Get current sec.
      # [Return] current sec.
      def tell
        raise Codec::FileError, 'File is not opened.' if closed?
        return Codec::LibMpg123.mpg123_tellframe(@mhptr) *
          Codec::LibMpg123.mpg123_tpf(@mhptr)
      end
      
      # Get total sec.
      # [Return] total sec.
      def total
        raise Codec::FileError, 'File is not opened.' if closed?
        current = Codec::LibMpg123.mpg123_tell(@mhptr)
        Codec::LibMpg123.mpg123_seek(@mhptr, 0, IO::SEEK_END)
        sec = tell()
        Codec::LibMpg123.mpg123_seek(@mhptr, current, IO::SEEK_SET)
        return sec
      end

      # Get audio file information.
      # [Return] AudioInfo structure.
      def info
        raise Codec::FileError, 'File is not opened.' if closed?
        return Data::AudioInfo.new(16,
                                   @rate,
                                   @channel,
                                   Output::LibAO::AO_FMT_LITTLE, nil)
      end
      
      # Get audio file comments.
      # [Return] comment hash.
      def comment
        raise Codec::FileError, 'File is not opened.' if closed?
        # v1_ptr = DL.malloc(DL::Importer.sizeof(Codec::LibMpg123::Mpg123_ID3v1))
        v2_ptr = DL.malloc(DL::Importer.sizeof(Codec::LibMpg123::Mpg123_ID3v2))
        # v1_p = DL::CPtr.new(v1_ptr)
        v2_p = DL::CPtr.new(v2_ptr)

        # err = Codec::LibMpg123.mpg123_id3(@mhptr, v1_p.ref, v2_p.ref)
        meta = Codec::LibMpg123.mpg123_meta_check(@mhptr)
        case meta
        when MPG123_ID3, MPG123_NEW_ID3
          # STDERR.puts("Meta: ID3")
        when MPG123_ICY, MPG123_NEW_ICY
          # STDERR.puts("Meta: ICY")
          return {}
        else
          # STDERR.printf("Meta: Unknown Metadata %d\n", meta)
          return {}
        end
        err = Codec::LibMpg123.mpg123_id3(@mhptr, nil, v2_p.ref)
        error_check(err)
        # v1 = Codec::LibMpg123::Mpg123_ID3v1.new(v1_p)
        v2 = Codec::LibMpg123::Mpg123_ID3v2.new(v2_p)
        data = {
          'version' => v2.version.to_s,
          'title'   => read_mpg123_string(v2.title),
          'artist'  => read_mpg123_string(v2.artist),
          'album'   => read_mpg123_string(v2.album),
          'year'    => read_mpg123_string(v2.year),
          'genre'   => read_mpg123_string(v2.genre),
          'comment' => read_mpg123_string(v2.comment)
        }
        # DL.free(v1_ptr)
        DL.free(v2_ptr)
        return data
      end

      # Audio file close.
      # [Return] close status.
      def close
        return nil unless @file
        @file = nil
        DL.free(@buffer)
        err = Codec::LibMpg123.mpg123_close(@mh_ptr)
        #error_check(err)
        return err
      end

      def closed?
        return true unless @file
        return false
      end
      
      # Shutdown decoder.
      # [Return] shutdown status.
      def shutdown
        close() if @file
        Codec::LibMpg123.mpg123_delete(@mh_ptr)
        @mh_ptr = nil
        Codec::LibMpg123.mpg123_exit()
      end

      private
      def error_string()
        return Codec::LibMpg123.mpg123_strerror(@mh).to_s
      end

      def read_mpg123_string(ptr)
        return nil if ptr.null?
        str = Codec::LibMpg123::Mpg123_String.new(ptr)
        return str.p.to_str(str.size-1).toutf8
      end

      def error_check(number)
        case number
        when Mpg123_Errors['MPG123_DONE']
          return nil
        when Mpg123_Errors['MPG123_NEW_FORMAT']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_NEW_FORMAT', error_string)
        when Mpg123_Errors['MPG123_NEED_MORE']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_NEED_MORE', error_string)
        when Mpg123_Errors['MPG123_ERR']
          raise Codec::UnknownError,
          sprintf("%s - %s", 'MPG123_ERR', error_string)
        when Mpg123_Errors['MPG123_OK']
          return true
        when Mpg123_Errors['MPG123_BAD_OUTFORMAT']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_BAD_OUTFORMAT', error_string)
        when Mpg123_Errors['MPG123_BAD_CHANNEL']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_BAD_CHANNEL', error_string)
        when Mpg123_Errors['MPG123_BAD_RATE']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_BAD_RATE', error_string)
        when Mpg123_Errors['MPG123_ERR_16TO8TABLE']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_ERR_16TO8TABLE', error_string)
        when Mpg123_Errors['MPG123_BAD_PARAM']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_BAD_PARAM', error_string)
        when Mpg123_Errors['MPG123_BAD_BUFFER']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_BAD_BUFFER', error_string)
        when Mpg123_Errors['MPG123_OUT_OF_MEM']
          raise Codec::CodecError,
          sprintf("%s - %s", 'MPG123_OUT_OF_MEM', error_string)
        when Mpg123_Errors['MPG123_NOT_INITIALIZED']
          raise Codec::CodecError,
          sprintf("%s - %s", 'MPG123_NOT_INITIALIZED', error_string)
        when Mpg123_Errors['MPG123_BAD_DECODER']
          raise Codec::CodecError,
          sprintf("%s - %s", 'MPG123_BAD_DECODER', error_string)
        when Mpg123_Errors['MPG123_BAD_HANDLE']
          raise Codec::CodecError,
          sprintf("%s - %s", 'MPG123_BAD_HANDLE', error_string)
        when Mpg123_Errors['MPG123_NO_BUFFERS']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_NO_BUFFERS', error_string)
        when Mpg123_Errors['MPG123_BAD_RVA']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_BAD_RVA', error_string)
        when Mpg123_Errors['MPG123_NO_GAPLESS']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_NO_GAPLESS', error_string)
        when Mpg123_Errors['MPG123_NO_SPACE']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_NO_SPACE', error_string)
        when Mpg123_Errors['MPG123_BAD_TYPES']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_BAD_TYPES', error_string)
        when Mpg123_Errors['MPG123_BAD_BAND']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_BAD_BAND', error_string)
        when Mpg123_Errors['MPG123_ERR_NULL']
          raise Codec::UnknownError,
          sprintf("%s - %s", 'MPG123_ERR_NULL', error_string)
        when Mpg123_Errors['MPG123_ERR_READER']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_ERR_READER', error_string)
        when Mpg123_Errors['MPG123_NO_SEEK_FROM_END']
          raise Codec::StreamError,
          sprintf("%s - %s",'MPG123_NO_SEEK_FROM_END', error_string)
        when Mpg123_Errors['MPG123_BAD_WHENCE']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_BAD_WHENCE', error_string)
        when Mpg123_Errors['MPG123_NO_TIMEOUT']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_NO_TIMEOUT', error_string)
        when Mpg123_Errors['MPG123_BAD_FILE']
          raise Codec::FileError,
          sprintf("%s - %s", 'MPG123_BAD_FILE', error_string)
        when Mpg123_Errors['MPG123_NO_SEEK']
          raise Codec::FileError,
          sprintf("%s - %s", 'MPG123_NO_SEEK', error_string)
        when Mpg123_Errors['MPG123_NO_READER']
          raise Codec::FileError,
          sprintf("%s - %s", 'MPG123_NO_READER', error_string)
        when Mpg123_Errors['MPG123_BAD_PARS']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_BAD_PARS', error_string)
        when Mpg123_Errors['MPG123_BAD_INDEX_PAR']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_BAD_INDEX_PAR', error_string)
        when Mpg123_Errors['MPG123_OUT_OF_SYNC']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_OUT_OF_SYNC', error_string)
        when Mpg123_Errors['MPG123_RESYNC_FAIL']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_RESYNC_FAIL', error_string)
        when Mpg123_Errors['MPG123_NO_8BIT']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_NO_8BIT', error_string)
        when Mpg123_Errors['MPG123_BAD_ALIGN']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_BAD_ALIGN', error_string)
        when Mpg123_Errors['MPG123_NULL_BUFFER']
          raise Codec::UnknownError,
          sprintf("%s - %s", 'MPG123_NULL_BUFFER', error_string)
        when Mpg123_Errors['MPG123_NO_RELSEEK']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_NO_RELSEEK', error_string)
        when Mpg123_Errors['MPG123_NULL_POINTER']
          raise Codec::UnknownError,
          sprintf("%s - %s", 'MPG123_NULL_POINTER', error_string)
        when Mpg123_Errors['MPG123_BAD_KEY']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_BAD_KEY', error_string)
        when Mpg123_Errors['MPG123_NO_INDEX']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_NO_INDEX', error_string)
        when Mpg123_Errors['MPG123_INDEX_FAIL']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_INDEX_FAIL', error_string)
        when Mpg123_Errors['MPG123_BAD_DECODER_SETUP']
          raise Codec::CodecError,
          sprintf("%s - %s", 'MPG123_BAD_DECODER_SETUP', error_string)
        when Mpg123_Errors['MPG123_MISSING_FEATURE']
          raise Codec::CodecError,
          sprintf("%s - %s", 'MPG123_MISSING_FEATURE', error_string)
        when Mpg123_Errors['MPG123_BAD_VALUE']
          raise Codec::CodecError,
          sprintf("%s - %s", 'MPG123_BAD_VALUE', error_string)
        when Mpg123_Errors['MPG123_LSEEK_FAILED']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_LSEEK_FAILED', error_string)
        when Mpg123_Errors['MPG123_BAD_CUSTOM_IO']
          raise Codec::StreamError,
          sprintf("%s - %s", 'MPG123_BAD_CUSTOM_IO', error_string)
        when Mpg123_Errors['MPG123_LFS_OVERFLOW']
          raise Codec::UnknownError,
          sprintf("%s - %s", 'MPG123_LFS_OVERFLOW', error_string)
        else
          raise Codec::UnknownError, 'Unknown error.'
        end
      end
    end
  end
end
