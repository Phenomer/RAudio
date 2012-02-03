#-*- coding: utf-8 -*-

require 'raudio/codec/faad2'
require 'raudio/player/simplayer'

module RAudio
  class Player
    #== Aac Player
    # SimPlayer based aac audio player.
    class AacPlayer < SimPlayer
      def init_codec
        @init = RAudio::Codec::Faad2.new
      end
    end
  end
end
