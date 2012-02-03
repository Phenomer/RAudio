#-*- coding: utf-8 -*-


module RAudio
  class Output
    class DriverError  < StandardError; end
    class DeviceError  < StandardError; end
    class FileError    < StandardError; end
    class UnknownError < StandardError; end
  end

  class Codec
    class CodecError   < StandardError; end
    class FileError    < StandardError; end
    class StreamError  < StandardError; end
    class UnknownError < StandardError; end
  end

  class Player
    class PlayerError  < StandardError; end
    class CodecError   < StandardError; end
    class UnknownError < StandardError; end
  end
end
