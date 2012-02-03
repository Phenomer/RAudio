#-*- coding: utf-8 -*-

require 'raudio/codec/fishsound'
require 'raudio/player/simplayer'

module RAudio
  class Player
    #== FishSound Player
    # SimPlayer based fishsound audio player.
    class FishSoundPlayer < SimPlayer
      def init_codec
        @init = RAudio::Codec::FishSound.new
      end
    end
  end
end
