#!/usr/bin/env ruby
#-*-coding: utf-8 -*-

$LOAD_PATH.push('../lib')
require 'raudio/player/vorbisplayer'
require 'io/console'
require 'webrick'
require 'json'

volume  = 50
device  = 1 # 0 is default
current = 0
srand()
vp = RAudio::Player::VorbisPlayer.new(device)
vp.set_volume(volume)

index  = File.open('./wvcontent/index.html', 'r').read
jquery = File.open('./wvcontent/jquery.js',  'r').read
mainjs = File.open('./wvcontent/main.js',  'r').read

sv = WEBrick::HTTPServer.new(:Port=> 3939)
sv.mount_proc('/index'){|req, res|
  res.content_type = 'text/html'
  res.body = index # File.open('./wvcontent/index.html', 'r').read
}

sv.mount_proc('/jquery.js'){|req, res|
  res.content_type = 'text/javascript'
  res.body = jquery # File.open('./wvcontent/jquery.js',  'r').read
}

sv.mount_proc('/main.js'){|req, res|
  res.content_type = 'text/javascript'
  res.body = mainjs # File.open('./wvcontent/main.js',  'r').read
}

sv.mount_proc('/pause'){|req, res|
  res.content_type = 'text/plain'
  if vp.status == :play
    res.body = vp.pause().to_s
  else
    res.body = vp.restart().to_s
  end
}

sv.mount_proc('/shuffle'){|req, res|
  res.content_type = 'text/plain'
  current = rand(ARGV.length)
  res.body = vp.stop().to_s
}

sv.mount_proc('/head'){|req, res|
  res.content_type = 'text/plain'
  res.body = vp.head().to_s
}

sv.mount_proc('/rewind'){|req, res|
  res.content_type = 'text/plain'
  res.body = vp.rewind(5).to_s
}


sv.mount_proc('/forward'){|req, res|
  res.content_type = 'text/plain'
  res.body = vp.forward(5).to_s
}

sv.mount_proc('/rewind_track'){|req, res|
  res.content_type = 'text/plain'
  current -= 2
  res.body = vp.stop().to_s
}

sv.mount_proc('/forward_track'){|req, res|
  res.content_type = 'text/plain'
  res.body = vp.stop().to_s
}

sv.mount_proc('/down_volume'){|req, res|
  res.content_type = 'text/plain'
  volume -= 5
  volume = 0 if volume < 0
  res.body = vp.set_volume(volume).to_s
}

sv.mount_proc('/up_volume'){|req, res|
  res.content_type = 'text/plain'
  volume += 5
  volume = 100 if volume > 100
  res.body = vp.set_volume(volume).to_s
}

sv.mount_proc('/mute'){|req, res|
  res.content_type = 'text/plain'
  res.body = vp.mute().to_s
}

sv.mount_proc('/maximize'){|req, res|
  res.content_type = 'text/plain'
  res.body = vp.maximize().to_s
}

sv.mount_proc('/file'){|req, res|
  res.content_type = 'text/plain'
  res.body = ARGV[current]
}

sv.mount_proc('/info'){|req, res|
  res.content_type = 'text/json'
  res.body = vp.info().to_json().to_s
}

sv.mount_proc('/comment'){|req, res|
  res.content_type = 'text/json'
  res.body = vp.comment().to_json().to_s
}

sv.mount_proc('/tell'){|req, res|
  res.content_type = 'text/plain'
  res.body = vp.tell().to_s
}

sv.mount_proc('/total'){|req, res|
  res.content_type = 'text/plain'
  res.body = vp.total().to_s
}

play_thread = Thread::start{
  loop {
    file = ARGV[current]
    if File.file?(file)
      printf("Play: %03d - %s\r\n", current, file)
      vp.play(file)
    end
    current += 1
    current  = 0 if current >= ARGV.length
  }
}
play_thread.abort_on_exception = true
play_thread.priority = -20
trap(:INT){
  sv.stop()
  vp.stop()
  vp.shutdown()
}
sv.start()
