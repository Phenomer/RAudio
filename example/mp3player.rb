#!/usr/bin/env ruby
#-*-coding: utf-8 -*-

$LOAD_PATH.push('../lib')
require 'raudio/player/mp3player'

mp3 = RAudio::Player::Mp3Player.new(1)
ARGV.each{|file|
  if File.file?(file)
    Thread::start{
        co = mp3.comment
	co.each_pair{|k, e|
          printf("%-8s: %s\n", k, e)
        } if co
    }.abort_on_exception = true
    mp3.play(file)
  end
}
