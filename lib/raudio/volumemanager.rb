#-*- coding: utf-8 -*-

begin
  require 'narray'
rescue => err
  STDERR.puts('Volume Controller is not supported.')
end

require 'raudio/ao/libao'

module RAudio
  #= Audio volume management class
  class VolumeManager
    include RAudio
    MAX_VOLUME = 100
    MIN_VOLUME = 0
    def initialize(volume=100)
      @volume  = volume
    end
    attr_reader :volume
    
    def set_volume(volume)
      return false if volume < MIN_VOLUME || volume > MAX_VOLUME
      return @volume = volume
    end

    def set_info(info)
      return @info = info
    end

    # set audio volume for buffer.
    def convert(buffer)
      return buffer unless defined?(NArray)
      return buffer if @volume == MAX_VOLUME
      byte = @info.bits / 8
      buffer = NArray.to_na(buffer, NArray::SINT,
                            @info.channels,
                            buffer.bytesize/@info.channels/byte)
      if Output::LibAO.ao_is_big_endian() == 1
       return (buffer.swap_byte / 100 * @volume).swap_byte.to_s
      else
        return (buffer / 100 * @volume).to_s
      end
    end
  end
end
