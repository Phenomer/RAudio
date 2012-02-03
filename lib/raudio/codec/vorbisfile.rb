#-*- coding: utf-8 -*-

require 'raudio/error'
# require 'raudio/codec/xiph/libvorbis'
require 'raudio/codec/xiph/libvorbisfile'

module RAudio
  class Codec
    #== Vorbis decoder class(vorbis)
    class VorbisFile
      include RAudio
      include Codec::LibVorbis
      include Codec::LibVorbisFile

      def initialize(bufsize=4096)
        @bufsize = 4096
        @bufptr  = DL.malloc(@bufsize)
        @vfptr   = DL.malloc(DL::Importer.sizeof(OggVorbis_File))
        @vfile   = OggVorbis_File.new(@vfptr)
        @file    = nil
      end

      # Open audio file.
      # [Arg1] filepath.
      # [Arg2] AudioInfo structure.
      # [Return] Open status.
      def open(file, ainfo=nil)
        raise Codec::FileError, \
        "File is already open - #{@file}" if @file
        @file = file
        case Codec::LibVorbisFile.ov_fopen(@file, @vfile)
        when 0
          return true
        when OV_EREAD
          raise Codec::FileError, \
          'A read from media returned an error.'
        when OV_ENOTVORBIS
          raise Codec::StreamError, \
          'Bitstream does not contain any Vorbis data.'
        when OV_EVERSION
          raise Codec::StremError, \
          'Vorbis version mismatch.'
        when OV_EBADHEADER
          raise Codec::StreamError, \
          'Invalid Vorbis bitstream header.'
        when OB_EFAULT
          raise Codec::CodecError, \
          'Internal logic fault; indicates a bug or heap/stack corruption.'
        else
          raise Codec::UnknownError, \
          'Unknown error.'
        end
      end

      # Read audio file.
      # [Return] raw audio data or nil(EOF).
      def read
        raise Codec::FileError, 'File is not opened.' if closed?
        endian = 0 # endian(little: 0, big: 1)
        ws     = 2 # wordsize(8-bit: 1, 16-bit: 2)
        sign   = 1 # 0: unsigned, 1: signed)
        bs     = 0 # current logical bitstream
        stat = Codec::LibVorbisFile.ov_read(@vfile, @bufptr, @bufsize,
                                            endian, ws, sign, bs)
        return DL::CPtr.new(@bufptr).to_str(stat) if stat > 0
        case stat
        when 0
          return nil
        when OV_HOLE
          raise Codec::StreamError, \
          'There was an interruption in the data.'
        when OV_EBADLINK
          raise Codec::StreamError, \
          'That an invalid stream section was supplied to libvorbisfile,' +
            ' or the requested link is corrupt.'
        when OV_EINVAL
          raise Codec::StreamError, \
          'The initial file headers couldn\'t be read or are corrupt,' +
            ' or that the initial open call for vf failed.'
        else
          raise Codec::UnknownError,
          'Unknown error.'
        end
      end

      # Seek audio file.
      # [Arg1] seek sec.
      # [Return] true.
      def seek(sec)
        raise Codec::FileError, 'File is not opened.' if closed?
        stat = Codec::LibVorbisFile.ov_time_seek(@vfile, sec)
        case stat
        when 0
          return true
        when OV_ENOSEEK
          raise Codec::StreamError, \
          'Bitstream is not seekable.'
        when OV_EINVAL
          raise Codec::CodecError, \
          'OV_EINVAL - Invalid argument value; possibly called ' + 
            'with an OggVorbis_File structure that isn\'t open.'
        when OV_EREAD
          raise Codec::StremError, \
          'A read from media returned an error.'
        when OV_EFAULT
          raise Codec::CodecError, \
          'Internal logic fault; indicates a bug or heap/stack corruption.'
        when OV_EBADLINK
          raise Codec::StreamError, \
          'Invalid stream section supplied to libvorbisfile,' +
            'or the requested link is corrupt.'
        else
          raise Codec::UnknownError, \
          'Unknown error.'
        end
      end

      # Get current sec.
      # [Return] current sec.
      def tell
        raise Codec::FileError, 'File is not opened.' if closed?
        stat = Codec::LibVorbisFile.ov_time_tell(@vfile)
        if stat >= 0
          return stat
        elsif stat == OV_EINVAL
          raise Codec::CodecError, 'Argument was invalid.'
        else
          raise Codec::UnknownError, 'Unknown error.'
        end
      end
      
      # Get total sec.
      # [Return] total sec.
      def total
        raise Codec::FileError, 'File is not opened.' if closed?
        stat = Codec::LibVorbisFile.ov_time_total(@vfile, -1)
        if stat >= 0
          return stat
        elsif stat == OV_EINVAL
          raise Codec::StreamError, \
          'Argument was invalid. In this case, the requested' +
            ' bitstream did not exist or the bitstream is nonseekable.'
        else
          raise Codec::UnknownError,\
          'Unknown error.'
        end
      end

      # Get audio file information.
      # [Return] AudioInfo structure.
      def info
        raise Codec::FileError, 'File is not opened.' if closed?
        link = -1
        info    = Codec::LibVorbisFile.ov_info(@vfile, link)
        if info.nil?
          raise Codec::UnknownError, 'Unknown error.'
        end
        info_r    = LibVorbis::Vorbis_Info.new(info)
        # data = {
        #   'version'         => info_r.version,
        #   'channels'        => info_r.channels,
        #   'rate'            => info_r.rate,
        #   'bitrate_upper'   => info_r.bitrate_upper,
        #   'bitrate_nominal' => info_r.bitrate_nominal,
        #   'bitrate_lower'   => info_r.bitrate_lower,
        #   'bitrate_window'  => info_r.bitrate_window
        # }
        return Data::AudioInfo.new(16, # 8bit...?
                                   info_r.rate,
                                   info_r.channels,
                                   Output::LibAO::AO_FMT_LITTLE, nil)
      end
 
      # Get audio file comments.
      # [Return] comment hash.
      def comment
        raise Codec::FileError, 'File is not opened.' if closed?

        # Link to the desired logical bitstream. 
        # For nonseekable files, this argument is ignored.
        # To retrieve the vorbis_info struct for the current bitstream,
        #  this parameter should be set to -1.
        link = -1
        comment = Codec::LibVorbisFile.ov_comment(@vfile, link)
        if comment.nil?
          raise Codec::UnknownError, 'Unknown error.'
        end
        comment_r = LibVorbis::Vorbis_Comment.new(comment)
        data = {
          'vendor'          => comment_r.vendor.to_s,
          'comments'        => comment_r.comments,
          'comment_list'    => Array.new
        }
        uc_offset, cl_offset = 0, 0
        comment_r.comments.times{
          length = (comment_r.comment_lengths + cl_offset).ptr.to_i
          data['comment_list'].push((comment_r.user_comments +
                                     uc_offset).ptr.to_str(length))
          uc_offset += DL::SIZEOF_VOIDP
          cl_offset += DL::SIZEOF_VOIDP
        }
        return data
      end

      # Audio file close.
      # [Return] close status.
      def close
        return nil unless @file
        @file = nil
        stat = Codec::LibVorbisFile.ov_clear(@vfile)
        raise Codec::UnknownError, 'Unknown error.' if stat != 0
        return stat
      end

      def closed?
        return true unless @file
        return false
      end
      
      # Shutdown decoder.
      # [Return] shutdown status.
      def shutdown
        close() if @file
        @vfile = nil
        DL.free(@bufptr)
        DL.free(@vfptr)
      end

      private
    end
  end
end
