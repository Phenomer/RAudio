#-*- coding: utf-8 -*-

require 'raudio/codec/sndfile'
require 'raudio/player/simplayer'

module RAudio
  class Player
    #== SndFile Player
    # SimPlayer based sndfile audio player.
    class SndPlayer < SimPlayer
      def init_codec
        @init = RAudio::Codec::SndFile.new
      end
    end
  end
end
