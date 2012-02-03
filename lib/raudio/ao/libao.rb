#-*- coding: utf-8 -*-

require 'dl/import'
require 'raudio/data'

module RAudio
  #= Audio Output class
  class Output
    #== libao wrapper
    module LibAO
      extend DL::Importer
      begin
        dlload('libao.so')
        AVAILABLE = true
      rescue DL::DLError => e
        STDERR.puts e
        AVAILABLE = false
      end

      # /* --- Constants ---*/
      AO_TYPE_LIVE   = 1
      AO_TYPE_FILE   = 2

      AO_ENODRIVER   = 1
      AO_ENOTFILE    = 2
      AO_ENOTLIVE    = 3
      AO_EBADOPTION  = 4
      AO_EOPENDEVICE = 5
      AO_EOPENFILE   = 6
      AO_EFILEEXISTS = 7
      AO_EBADFORMAT  = 8
      
      AO_EFAIL       = 100
      
      AO_FMT_LITTLE  = 1
      AO_FMT_BIG     = 2
      AO_FMT_NATIVE  = 4

      # /* --- Structures --- */
      #
      # typedef struct ao_info {
      # 	int  type; /* live output or file output? */
      # 	char *name; /* full name of driver */
      # 	char *short_name; /* short name of driver */
      #         char *author; /* driver author */
      # 	char *comment; /* driver comment */
      # 	int  preferred_byte_format;
      # 	int  priority;
      # 	char **options;
      # 	int  option_count;
      # } ao_info;
      AO_Info =
        struct(['int  type',
                'char *name',
                'char *short_name',
                'char *author',
                'char *comment',
                'int  preferrd_byte_format',
                'int  priority',
                'char *options',
                'int  option_count'])

      # typedef struct ao_sample_format {
      # 	int  bits; /* bits per sample */
      # 	int  rate; /* samples per second (in a single channel) */
      # 	int  channels; /* number of audio channels */
      # 	int  byte_format; /* Byte ordering in sample, see constants below */
      #         char *matrix; /* input channel location/ordering */
      # } ao_sample_format;
      AO_Sample_Format =
        struct(['int  bits',
                'int  rate',
                'int  channels',
                'int  byte_format',
                'char *matrix'])

      # typedef struct ao_option {
      # 	char *key;
      # 	char *value;
      # 	struct ao_option *next;
      # } ao_option;
      AO_Option =
        struct(['char   *key',
                'char   *value',
                'struct ao_option *next'])

      # typedef struct ao_functions ao_functions;
      typealias('ao_functions', RAudio::Data::TypeAlias['ao_functions'])
      # typedef struct ao_device ao_device;
      typealias('ao_device', RAudio::Data::TypeAlias['ao_device'])
      typealias('uint_32', RAudio::Data::TypeAlias['uint_32'])


      # /* --- Functions --- */

      # /* library setup/teardown */
      # void ao_initialize(void);
      extern('void ao_initialize(void)')

      # void ao_shutdown(void);
      extern('void ao_shutdown(void)')

      # /* device setup/playback/teardown */
      # int   ao_append_global_option(const char *key,
      #                               const char *value);
      extern('int ao_append_global_option(const char *, const char *)')

      # int          ao_append_option(ao_option **options,
      #                               const char *key,
      #                               const char *value);
      extern('int ao_append_option(ao_option **, const char *, const char *)')

      # void          ao_free_options(ao_option *options);
      extern('void ao_free_options(ao_option *)')

      # ao_device*       ao_open_live(int driver_id,
      #                               ao_sample_format *format,
      #                               ao_option *option);
      extern('ao_device * ao_open_live(int, ao_sample_format *, ao_option *)')

      # ao_device*       ao_open_file(int driver_id,
      #                               const char *filename,
      #                               int overwrite,
      #                               ao_sample_format *format,
      #                               ao_option *option);
      extern('ao_device* ao_open_file(int, const char *, int, ao_sample_format *, ao_option *)')

      # int                   ao_play(ao_device *device,
      #                               char *output_samples,
      #                               uint_32 num_bytes);
      extern('int ao_play(ao_device *, char *, uint_32)')

      # int                  ao_close(ao_device *device);
      extern('int ao_close(ao_device *)')

      # /* driver information */
      # int              ao_driver_id(const char *short_name);
      extern('int ao_driver_id(const char *)')

      # int      ao_default_driver_id(void);
      extern('int ao_default_driver_id(void)')

      # ao_info       *ao_driver_info(int driver_id);
      extern('ao_info *ao_driver_info(int)')

      # ao_info **ao_driver_info_list(int *driver_count);
      extern('ao_info **ao_driver_info_list(int *)')

      # char       *ao_file_extension(int driver_id);
      # extern('char *ao_file_extension(int)')

      # /* miscellaneous */
      # int          ao_is_big_endian(void);
      extern('int ao_is_big_endian(void)')


      # # ao/plugin.h
      # # int ao_plugin_test();
      #  extern('int ao_plugin_test()')

      # # ao_info *ao_plugin_driver_info();
      #  extern('ao_info *ao_plugin_driver_info()')

      # # int ao_plugin_device_init(ao_device *device);
      # extern('int ao_plugin_device_init(ao_device *)')

      # # int ao_plugin_set_option(ao_device *device, const char *key, const char *value);
      # extern('int ao_plugin_set_option(ao_device *, const char *, const char *)')

      # # int ao_plugin_open(ao_device *device, ao_sample_format *format);
      # extern('int ao_plugin_open(ao_device *, ao_sample_format *)')

      # # int ao_plugin_play(ao_device *device, const char *output_samples, 
      # #                  uint_32 num_bytes);
      # extern('int ao_plugin_play(ao_device *, const char *, uint_32)')

      # # int ao_plugin_close(ao_device *device);
      # extern('int ao_plugin_close(ao_device *)')

      # # void ao_plugin_device_clear(ao_device *device);
      # extern('void ao_plugin_device_clear(ao_device *)')

      # # char *ao_plugin_file_extension();
      # # extern('char *ao_plugin_file_extension()')
    end
  end
end
