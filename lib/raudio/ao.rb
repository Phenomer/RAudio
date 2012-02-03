#-*- coding: utf-8 -*-

require 'raudio/error'
require 'raudio/ao/libao'

module RAudio
  #== Audio output class
  class Output
    # == Audio output class from libao
    class AO
      include RAudio
      include RAudio::Output::LibAO

      def initialize
        Output::LibAO.ao_initialize()
        @format = Output::LibAO::AO_Sample_Format.malloc
        @driver, @device = nil, nil
        set_default_driver()
      end

      # Set default driver.
      # [Return] setup status.
      def set_default_driver
        @driver = Output::LibAO.ao_default_driver_id()
        return @driver if @driver >= 0
        raise Output::DeviceError, 'Available devices not found.'
      end

      # Set Driver.
      # [Arg1] Driver ID.
      # [Return] Driver ID.
      def set_driver(driver_id)
        return @driver = driver_id
      end

      # Open audio device.
      # [Arg1] AudioInfo structure.
      # [Arg2] Hash for AO option(optional).
      # [Return] open status.
      def open_live(format, *option)
        @format.bits        = format.bits
        @format.rate        = format.rate
        @format.channels    = format.channels
        @format.byte_format = format.byte_format
        @format.matrix      = format.matrix
        @device = Output::LibAO.ao_open_live(@driver, @format, nil)
        return @device unless @device.null?
        @device = nil
        case DL::CFunc.last_error
        when AO_ENODRIVER
          raise Output::DriverError, \
          'No driver corresponds to Driver_ID.'
        when AO_ENOTLIVE
          raise Output::DriverError, \
          'This driver is not a live output device.'
        when AO_EBADOPTION
          raise Output::DriverError, \
          'A valid option key has an invalid value.'
        when AO_EOPENDEVICE
          raise Output::DeviceError, \
          'Cannot open the device'
        else # AO_EFAIL
          raise Output::UnknownError, 'Unknown error.'
        end
      end

      # Open audio file.
      # [Arg1] Output file path.
      # [Arg2] Allow overwrite(true of false).
      # [Arg3] AudioInfo structure.
      # [Arg4] Hash for AO option(optional).
      # [Return] open status.
      def open_file(path, overwrite, format, *option)
        ow = 0
        ow = 1 if overwrite
        @format.bits        = format.bits
        @format.rate        = format.rate
        @format.channels    = format.channels
        @format.byte_format = format.byte_format
        @format.matrix      = format.matrix
        @device = Output::LibAO.ao_open_file(@driver, path, ow, @format, option)
        return true unless @device.null?
        @device = nil
        case DL::CFunc.last_error
        when AO_ENODRIVER
          raise Output::DeviceError, \
          'No driver corresponds to Driver_ID.'
        when AO_ENOTFILE
          raise Output::DeviceError, \
          'This driver is not a file output driver.'
        when AO_EBADOPTION
          raise Output::DeviceError, \
          'A valid option key has an invalid value.'
        when AO_EOPENFILE
          raise Output::DeviceError, \
          'Cannot open the file.'
        when AO_EFILEEXISTS
          raise Output::FileError, \
          'File already exists.'
        else # AO_EFAIL
          raise Output::UnknownError, \
          'Unknown error.'
        end
      end

      # Play from buffer.
      # [Arg1] raw audio buffer.
      # [Arg1] buffer size.
      # [Return] play status.
      def play(buffer, size)
        raise Output::DeviceError, 'Device not configured.' unless @device
        size = Output::LibAO.ao_play(@device, buffer, size)
        raise Output::DeviceError, 'Device should be closed.' if size == 0
        return size
      end

      # Close audio device.
      # [Return] close status.
      def close
        stat = Output::LibAO.ao_close(@device)
        @device = nil
        case stat
        when 0
          raise Output::DeviceError, 'Device was being closed.' 
        when 1
          return true
        end
      end

      def closed?
        return true if @device
        return false
      end

      # Shutdown AO.
      # [Return] shutdown status.
      def shutdown
        close() if @device
        Output::LibAO.ao_shutdown()
      end

      # Test if this computer uses big-endian byte ordering.
      # [Return] true or false.
      def big_endian?
        return true if Output::LibAO.ao_is_big_endian() == 0
        return false
      end

      # Get driver information.
      # [Arg1] driver id(default: current driver)
      # [Return] driver information.
      def driver_info(driver=@driver)
        binfo = RAudio::Output::LibAO.ao_driver_info(driver)
        raise Output::DriverError, \
        'Driver_ID does not correspond to an actual driver.' if binfo.null?
        ainfo = RAudio::Output::LibAO::AO_Info.new(binfo)
        rinfo = {
          'type'         => ainfo.type.to_i,
          'name'         => ainfo.name.to_s,
          'short_name'   => ainfo.short_name.to_s,
          'author'       => ainfo.author.to_s,
          'comment'      => ainfo.comment.to_s,
          'priority'     => ainfo.priority.to_i,
          'option_count' => ainfo.option_count.to_i,
          'options'      => Array.new,
          'preferrd_byte_format' => ainfo.preferrd_byte_format.to_i
        }
        offset = 0
        rinfo['option_count'].times{
          rinfo['options'].push((ainfo.options + offset).ptr.to_s)
          offset += DL::SIZEOF_VOIDP
        }
        return rinfo
      end

      # # Get driver ID list.
      # # [Return] driver information.
      # def driver_id_list
      # end
      private
    end
  end
end
