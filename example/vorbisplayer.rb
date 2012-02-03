#!/usr/bin/env ruby
#-*-coding: utf-8 -*-

$LOAD_PATH.push('../lib')
require 'raudio/player/vorbisplayer'
require 'io/console'

volume  = 50
device  = 1 # 0 is default
current = 0
srand()
vp = RAudio::Player::VorbisPlayer.new(device)
vp.set_volume(volume)

ctl_t = Thread::start(vp, volume){|vp, volume|
  IO.console.noecho{|io|
    loop do
      begin
        case c = io.getch()
        when 'p', ' '
          if vp.status == :play
            p vp.pause()
          else
            p vp.restart()
          end
        when 's'
          current = rand(ARGV.length)
          p vp.stop()
        when 'h'
          p vp.head()
        when 'r'
          p vp.rewind(5)
        when 'f'
          p vp.forward(5)
        when 'R'
          p vp.stop()
          current -= 2
        when 'F'
          p vp.stop()
        when '<'
          volume -= 5
          volume = 0 if volume < 0
          p vp.set_volume(volume)
        when '>'
          volume += 5
          volume = 100 if volume > 100
          p vp.set_volume(volume)
        when 'm'
          p vp.mute()
        when 'M'
          p vp.maximize()
        when 'i'
          printf("%s\r\n", vp.info().inspect())
        when 'I'
          printf("%s\r\n", vp.comment())
        when 't'
          p vp.tell()
        when 'T'
          p vp.total()
        when 'q'
          break
        else
          printf("Unknown connand: %s\r\n", c)
        end
      rescue => err
        printf("Err: %s\n", err.to_s)
      end
    end
  }
  vp.shutdown()
  exit 0
}
ctl_t.abort_on_exception = true

loop {
  file = ARGV[current]
  if File.file?(file)
    printf("Play: %03d - %s\r\n", current, file)
    vp.play_mp(file)
  end
  current += 1
  current  = 0 if current >= ARGV.length
}
ctl_t.join()
