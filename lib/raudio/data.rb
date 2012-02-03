#-*- coding: utf-8 -*-

module RAudio
  #= Audio data structure module
  module Data
    TypeAlias     = {
      # Defaults
      'int16_t'  => 'short',
      'int32_t'  => 'int',
      'int64_t'  => 'long',
      'uint16_t' => 'unsigned short',
      'uint32_t' => 'unsigned int',
      'uint64_t' => 'unsigned long',

      'size_t'   => 'long',
      'time_t'   => 'long',
      'off_t'    => 'long',
      'uint_32'  => 'unsigned int',

      # libao - ao/ao.h
      'ao_functions' => 'void',
      'ao_device'    => 'void',

      # libogg - ogg/config_types.h
      'ogg_int16_t'  => 'int16_t',
      'ogg_int32_t'  => 'int32_t',
      'ogg_int64_t'  => 'int64_t',
      'ogg_uint16_t' => 'uint16_t',
      'ogg_uint32_t' => 'uint32_t',

      # liboggz - oggz/oggz_constants.h
      'OggzStreamContent' => 'int',

      # liboggz - oggz/oggz_table.h
      'OggzTable'    => 'void',
      'OGGZ'         => 'void',
      'oggz_off_t'   => 'off_t',

      # liboggz - oggz/oggz_read.h
      'OggzReadPacket' => 'int *', # callback
      'OggzReadPage'   => 'int *', # callback
      'OggzMetric'     => 'ogg_int64_t *', # callback
      'OggzOrder'      => 'int *', # callback

      # liboggz - oggz_write.h
      'OggzWriteHungry' => 'int *',  # callback

      # liboggz - oggz_io.h
      'OggzIORead'  => 'size_t *', # callback
      'OggzIOWrite' => 'size_t *', # callback
      'OggzIOSeek'  => 'int *',    # callback
      'OggzIOTell'  => 'long *',   # callback
      'OggzIOFlush' => 'int *',    # callback

      # libvorbisfile - vorbisfile.h
      # 'ov_callbacks' => '', struct...

      # libfishsound - fishsound.h
      'FishSound' => 'void',

      # libfishsound - decode.h
      'FishSoundDecoded_Float'    => 'int *', # callback
      'FishSoundDecoded_FloatIlv' => 'int *', # callback

      # libfishsound - encode.h
      'FishSoundEncoded' => 'int *',  # callback

      # libsndfile - sndfile.h
      'SNDFILE'            => 'void',
      'sf_count_t'         => 'int64_t',
      'sf_vio_get_filelen' => 'sf_count_t *', # callback
      'sf_vio_seek'        => 'sf_count_t *', # callback
      'sf_vio_read'        => 'sf_count_t *', # callback
      'sf_vio_write'       => 'sf_count_t *', # callback
      'sf_vio_tell'        => 'sf_count_t *', # callback

      # libfaad2 - libfaad2.h
      'NeAACDecHandle'           => 'void *',
      'NeAACDecConfigurationPtr' => 'void *',

      # libmpg123 - libmpg123.h
      'enum mpg123_parms'         => 'int',
      'enum mpg123_feature_set'   => 'int',
      'enum mpg123_channels'      => 'int',
      'enum mpg123_vbr'           => 'int',
      'enum mpg123_version'       => 'int',
      'enum mpg123_mode'          => 'int',
      'enum mpg123_flags'         => 'int',
      'enum mpg123_state'         => 'int',
      'enum mpg123_text_encoding' => 'int',
      'r_read'                    => 'ssize_t *', # callback
      'r_lseek'                   => 'off_t *', # callback
    }

    if defined?(OSTYPE_32BIT)
      TypeAlias['int64_t']  = 'long long'
      TypeAlias['uint64_t'] = 'unsigned long long'
    end

    AudioInfo     = Struct.new(:bits, :rate, :channels,
                               :byte_format, :matrix)
    AudioTag      = Struct.new(:artist, :album, :number, :title,
                               :genre,  :date,  :comment)
    AudioFileInfo = Struct.new(:path, :size, :total, :ainfo, :atag)
  end
end
