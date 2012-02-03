#-*- coding: utf-8 -*-

require 'raudio/codec/vorbisfile'
require 'raudio/player/simplayer'

module RAudio
  class Player
    #== Vorbis Player
    # SimPlayer based vorbis audio player.
    class VorbisPlayer < SimPlayer
      def init_codec
        @init = RAudio::Codec::VorbisFile.new
      end
    end
  end
end
