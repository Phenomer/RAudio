#-*- coding: utf-8 -*-

require 'raudio/codec/mpg123'
require 'raudio/player/simplayer'

module RAudio
  class Player
    #== Mp3 Player
    # SimPlayer based mp3 audio player.
    class Mp3Player < SimPlayer
      def init_codec
        @init = RAudio::Codec::Mpg123.new
      end
    end
  end
end
