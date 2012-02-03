#!/usr/bin/env ruby_head
#-*-coding: utf-8 -*-

$LOAD_PATH.push('../lib')
$PROGRAM_NAME = 'rmp'
require 'raudio/codec/vorbisfile'
require 'raudio/codec/mpg123'
require 'raudio/player/msimplayer'
require 'io/console'

module RAudio
  class Player
    include RAudio
    class MVorbisPlayer < MSimPlayer
      def init_codec
        @init = RAudio::Codec::VorbisFile
      end
    end

    class MMpg123Player < MSimPlayer
      def init_codec
        @init = RAudio::Codec::Mpg123
      end
    end
  end
end

class PlayList
  def initialize
    @lists  = Array.new
    @list_no = 0
    @file_no = 0
    srand()
  end
  attr_reader :list_no, :file_no
  
  def scan_file(*dir)
    dir.each{|d|
      Dir.glob(File.join(d, '*')){|alb|
        list = Array.new
        Dir.glob(File.join(alb, '*.*')){|file|
          if File.extname(file).match(/^\.(mp3|og[g,a])$/i)
            list.push(file)
          end
        }
        @lists.push(list.sort)
      }
    }
    return @lists
  end

  def file
    return @lists[@list_no][@file_no]
  end

  def type
    return :unknown unless File.file?(@lists[@list_no][@file_no])
    case File.extname(@lists[@list_no][@file_no])
    when /^\.mp3$/i
      return :mp3
    when /^\.og[ag]$/i
      return :vorbis
    else
      return :unknown
    end
  end

  def list
    return @lists[@list_no]
  end

  def rewind
    @file_no -= 1
    if @file_no < 0
      @list_no -= 1
      @file_no  = @lists[@list_no].length - 1
      @list_no  = @lists.length - 1 if @list_no < 0 
    end
  end

  def forward
    @file_no += 1
    if @file_no >= @lists[@list_no].length
      @list_no += 1
      @file_no  = 0
      @list_no  = 0 if @list_no >= @lists.length
    end
  end

  def rewind_list
    @file_no  = 0
    @list_no -= 1
    @list_no  = @lists.length - 1 if @list_no < 0
  end

  def forward_list
    @file_no  = 0
    @list_no += 1
    @list_no  = 0 if @list_no >= @lists.length
  end

  def shuffle
    @file_no = rand(@lists[@list_no].length)
  end

  def shuffle!
    @lists[@list_no].shuffle!
    @file_no = rand(@lists[@list_no].length)
  end

  def shuffle_list
    @list_no = rand(@lists.length)
    @file_no = rand(@lists[@list_no].length)
  end

  def shuffle_list!
    @lists[@list_no].shuffle!
    @lists.collect!{|elem| elem.shuffle!}
    @list_no = rand(@lists.length)
    @file_no = rand(@lists[@list_no].length)
  end
end

lists   = PlayList.new
lists.scan_file(ARGV)
volume  = 50
device  = 1 # 0 is default
skip    = false
codec = Hash.new
codec[:vorbis] = RAudio::Player::MVorbisPlayer.new(device)
codec[:vorbis].set_volume(volume)
codec[:mpg123] = RAudio::Player::MMpg123Player.new(device)
codec[:mpg123].set_volume(volume)
c_codec = :vorbis
command = {
  :pause         => ['p', ' '],
  :shuffle       => ['s'],
  :shuffle!      => ['S'],
  :shuffle_list  => ['x'],
  :shuffle_list! => ['X'],
  :head          => ['^'],
  :rewind        => ['r'],
  :rewind_10     => ['R'],
  :forward       => ['f'],
  :forward_10    => ['F'],
  :rewind_list   => ['h'],
  :rewind_file   => ['j'],
  :forward_file  => ['k', "\n", "\r", "\r\n"],
  :forward_list  => ['l'],
  :volume_down   => ['<', ','],
  :volume_up     => ['>', '.'],
  :mute          => ['m'],
  :maximize      => ['M'],
  :info          => ['i'],
  :comment       => ['I'],
  :tell          => ['t'],
  :total         => ['T'],
  :list          => ['a'],
  :quit          => ['q']
}

ctl_t = Thread.start(){
  loop do
    begin
    printf("%s%s@%s|%03d/%03d> ", "\b" * 80,
           ENV['USER'], $PROGRAM_NAME,
           codec[c_codec].tell.to_i,
           codec[c_codec].total.to_i)
    c = IO.console.getch()
    puts("\r\n")
    case c
    when *command[:pause]
      if codec[c_codec].status == 'play'
        result = codec[c_codec].pause()
      else
        retult = codec[c_codec].restart()
      end
    when *command[:shuffle]
      lists.shuffle
      skip   = true
      result = codec[c_codec].stop()
      printf("Play: %03d - %03d - %s\r\n",
             lists.list_no, lists.file_no, lists.file)
    when *command[:shuffle!]
      lists.shuffle!
      skip   = true
      result = codec[c_codec].stop()
      printf("Play: %03d - %03d - %s\r\n",
             lists.list_no, lists.file_no, lists.file)
    when *command[:shuffle_list]
      lists.shuffle_list
      skip   = true
      result = codec[c_codec].stop()
      printf("Play: %03d - %03d - %s\r\n",
             lists.list_no, lists.file_no, lists.file)
    when *command[:shuffle_list!]
      lists.shuffle_list!
      skip   = true
      result = codec[c_codec].stop()
      printf("Play: %03d - %03d - %s\r\n",
             lists.list_no, lists.file_no, lists.file)
    when *command[:head]
      result = codec[c_codec].head()
    when *command[:rewind]
      result = codec[c_codec].rewind(5)
    when *command[:rewind_10]
      result = codec[c_codec].rewind(10)
    when *command[:forward]
      result = codec[c_codec].forward(5)
    when *command[:forward_10]
      result = codec[c_codec].forward(10)
    when *command[:rewind_list]
      lists.rewind_list
      skip   = true
      result = codec[c_codec].stop()
      printf("Play: %03d - %03d - %s\r\n",
             lists.list_no, lists.file_no, lists.file)
    when *command[:rewind_file]
      lists.rewind
      skip   = true
      result = codec[c_codec].stop()
      printf("Play: %03d - %03d - %s\r\n",
             lists.list_no, lists.file_no, lists.file)
    when *command[:forward_file]
      lists.forward
      skip   = true
      result = codec[c_codec].stop()
      printf("Play: %03d - %03d - %s\r\n",
             lists.list_no, lists.file_no, lists.file)
    when *command[:forward_list]
      lists.forward_list
      skip    = true
      result = codec[c_codec].stop()
      printf("Play: %03d - %03d - %s\r\n",
             lists.list_no, lists.file_no, lists.file)
    when *command[:volume_down]
      volume -= 5
      volume  = 0 if volume < 0
      result  = codec[c_codec].set_volume(volume)
      printf("Volume: %s\n", result)
    when *command[:volume_up]
      volume += 5
      volume  = 100 if volume > 100
      result  = codec[c_codec].set_volume(volume)
      printf("Volume: %s\n", result)
    when *command[:mute]
      result = codec[c_codec].mute()
      printf("Volume: %s\n", result)
    when *command[:maximize]
      result = codec[c_codec].maximize()
      printf("Volume: %s\n", result)
    when *command[:info]
      result = codec[c_codec].info()
      printf("%03d - %03d - %s\r\n",
             lists.list_no, lists.file_no, lists.file)
      result.each_pair{|k, v|
        printf(" %-12s %s\r\n", k, v)} if result
    when *command[:comment]
      result = codec[c_codec].comment()
      printf("%03d - %03d - %s\r\n",
             lists.list_no, lists.file_no, lists.file)
      result.each_pair{|k, v|
        printf(" %-12s %s\r\n", k, v)} if result
    when *command[:tell]
      result = codec[c_codec].tell()
      printf("Tell: %d\r\n", result.to_i)
    when *command[:total]
      result = codec[c_codec].total()
      printf("Total: %d\r\n", result.to_i)
    when *command[:list]
      lists.list.each_index{|i|
        printf("%03d %s\r\n", i, lists.list[i])}
    when *command[:quit]
      codec[c_codec].stop
      break
    else
      printf("Unknown connand: [%s]\r\n", c)
      next
    end
    printf("=>%s\r\n", result)
    rescue RAudio::Player::PlayerError => err
      printf("Error: %s\r\n", err.to_s)
    end
  end
}
codec.each_pair{|name, codec|
  codec.shutdown()
}
ctl_t.abort_on_exception = true


loop {
  case lists.type
  when :vorbis
    c_codec = :vorbis
  when :mp3
    c_codec = :mpg123
  else
    printf("Unsupported file - %s\r\n", file)
    lists.forward
    next
  end
  codec[c_codec].play(lists.file)
  break unless ctl_t.alive?
  if skip
    skip = false
    next
  else
    lists.forward
  end
}

