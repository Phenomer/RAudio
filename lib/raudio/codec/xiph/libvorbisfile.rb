#-*- coding: utf-8 -*-

require 'dl/import'
require 'raudio/data'
require 'raudio/codec/xiph/libogg'
require 'raudio/codec/xiph/libvorbis'

module RAudio
  #= Audio Codec class
  class Codec
    #== libvorbisfile wrapper
    module LibVorbisFile
      extend DL::Importer
      begin
        dlload('libvorbisfile.so')
        AVAILABLE = true
      rescue DL::DLError => e
        STDERR.puts e
        AVAILABLE = false
      end

      RAudio::Data::TypeAlias.each_pair{|k, v| typealias(k, v)}

      # /* The function prototypes for the callbacks are basically the same as for
      #  * the stdio functions fread, fseek, fclose, ftell.
      #  * The one difference is that the FILE * arguments have been replaced with
      #  * a void * - this is to be used as a pointer to whatever internal data these
      #  * functions might need. In the stdio case, it's just a FILE * cast to a void *
      #  *
      #  * If you use other functions, check the docs for these functions and return
      #  * the right values. For seek_func(), you *MUST* return -1 if the stream is
      #  * unseekable
      #  */

      # typedef struct {
      #   size_t (*read_func)  (void *ptr, size_t size, size_t nmemb, void *datasource);
      #   int    (*seek_func)  (void *datasource, ogg_int64_t offset, int whence);
      #   int    (*close_func) (void *datasource);
      #   long   (*tell_func)  (void *datasource);
      # } ov_callbacks;

      Ov_Callbacks =
        struct(['size_t (*read_func)  (void *ptr, size_t size, size_t nmemb, void *datasource)',
                'int    (*seek_func)  (void *datasource, ogg_int64_t offset, int whence)',
                'int    (*close_func) (void *datasource)',
                'long   (*tell_func)  (void *datasource)'])
      Read_Func  = bind('size_t * read_func(void *ptr, size_t, size_t, void *datasource)', :temp)
      Seek_Func  = bind('int    * seek_func(void *datasource, ogg_int64_t, int)', :temp)
      Close_Func = bind('int    * close_func(void *datasource)', :temp)
      Tell_Func  = bind('long   * tell_func(void *database)', :temp)

      # #ifndef OV_EXCLUDE_STATIC_CALLBACKS

      # /* a few sets of convenient callbacks, especially for use under
      #  * Windows where ov_open_callbacks() should always be used instead of
      #  * ov_open() to avoid problems with incompatible crt.o version linking
      #  * issues. */

      # static int _ov_header_fseek_wrap(FILE *f,ogg_int64_t off,int whence){
      #   if(f==NULL)return(-1);

      # #ifdef __MINGW32__
      #   return fseeko64(f,off,whence);
      # #elif defined (_WIN32)
      #   return _fseeki64(f,off,whence);
      # #else
      #   return fseek(f,off,whence);
      # #endif
      # }

      # /* These structs below (OV_CALLBACKS_DEFAULT etc) are defined here as
      #  * static data. That means that every file which includes this header
      #  * will get its own copy of these structs whether it uses them or
      #  * not unless it #defines OV_EXCLUDE_STATIC_CALLBACKS.
      #  * These static symbols are essential on platforms such as Windows on
      #  * which several different versions of stdio support may be linked to
      #  * by different DLLs, and we need to be certain we know which one
      #  * we're using (the same one as the main application).
      #  */

      # static ov_callbacks OV_CALLBACKS_DEFAULT = {
      #   (size_t (*)(void *, size_t, size_t, void *))  fread,
      #   (int (*)(void *, ogg_int64_t, int))           _ov_header_fseek_wrap,
      #   (int (*)(void *))                             fclose,
      #   (long (*)(void *))                            ftell
      # };

      # static ov_callbacks OV_CALLBACKS_NOCLOSE = {
      #   (size_t (*)(void *, size_t, size_t, void *))  fread,
      #   (int (*)(void *, ogg_int64_t, int))           _ov_header_fseek_wrap,
      #   (int (*)(void *))                             NULL,
      #   (long (*)(void *))                            ftell
      # };

      # static ov_callbacks OV_CALLBACKS_STREAMONLY = {
      #   (size_t (*)(void *, size_t, size_t, void *))  fread,
      #   (int (*)(void *, ogg_int64_t, int))           NULL,
      #   (int (*)(void *))                             fclose,
      #   (long (*)(void *))                            NULL
      # };

      # static ov_callbacks OV_CALLBACKS_STREAMONLY_NOCLOSE = {
      #   (size_t (*)(void *, size_t, size_t, void *))  fread,
      #   (int (*)(void *, ogg_int64_t, int))           NULL,
      #   (int (*)(void *))                             NULL,
      #   (long (*)(void *))                            NULL
      # };

      #endif

      #define  NOTOPEN   0
      #define  PARTOPEN  1
      #define  OPENED    2
      #define  STREAMSET 3
      #define  INITSET   4

      NOTOPEN   = 0
      PARTOPEN  = 1
      OPENED    = 2
      STREAMSET = 3
      INITSET   = 4

      # typedef struct OggVorbis_File {
      #   void            *datasource; /* Pointer to a FILE *, etc. */
      #   int              seekable;
      #   ogg_int64_t      offset;
      #   ogg_int64_t      end;
      #   ogg_sync_state   oy;

      #   /* If the FILE handle isn't seekable (eg, a pipe), only the current
      #      stream appears */
      #   int              links;
      #   ogg_int64_t     *offsets;
      #   ogg_int64_t     *dataoffsets;
      #   long            *serialnos;
      #   ogg_int64_t     *pcmlengths; /* overloaded to maintain binary
      #                                   compatibility; x2 size, stores both
      #                                   beginning and end values */
      #   vorbis_info     *vi;
      #   vorbis_comment  *vc;

      #   /* Decoding working state local storage */
      #   ogg_int64_t      pcm_offset;
      #   int              ready_state;
      #   long             current_serialno;
      #   int              current_link;

      #   double           bittrack;
      #   double           samptrack;

      #   ogg_stream_state os; /* take physical pages, weld into a logical
      #                           stream of packets */
      #   vorbis_dsp_state vd; /* central working state for the packet->PCM decoder */
      #   vorbis_block     vb; /* local working space for packet->PCM decode */

      #   ov_callbacks callbacks;

      # } OggVorbis_File;

      OggVorbis_File =
        struct(['void            *datasource',
                'int              seekable',
                'ogg_int64_t      offset',
                'ogg_int64_t      end',

                # 'ogg_sync_state   oy',
                'unsigned char *oy_data',
                'int oy_storage',
                'int oy_fill',
                'int oy_returned',

                'int oy_unsynced',
                'int oy_headerbytes',
                'int oy_bodybytes',
                
                'int              links',
                'ogg_int64_t     *offsets',
                'ogg_int64_t     *dataoffsets',
                'long            *serialnos',
                'ogg_int64_t     *pcmlengths',
                'vorbis_info     *vi',
                'vorbis_comment  *vc',
                'ogg_int64_t      pcm_offset',
                'int              ready_state',
                'long             current_serialno',
                'int              current_link',
                'double           bittrack',
                'double           samptrack',

                # 'ogg_stream_state os',
                'unsigned char   *os_body_data',
                'long    os_body_storage',
                'long    os_body_fill',
                'long    os_body_returned',
                'int     *os_lacing_vals',
                'ogg_int64_t *os_granule_vals',
                'long    os_lacing_storage',
                'long    os_lacing_fill',
                'long    os_lacing_packet',
                'long    os_lacing_returned',
                'unsigned char    os_header[282]',
                'int              os_header_fill',
                'int     os_e_o_s',
                'int     os_b_o_s',
                'long    os_serialno',
                'long    os_pageno',
                'ogg_int64_t  os_packetno',
                'ogg_int64_t   os_granulepos',

                # 'vorbis_dsp_state vd',
                'int vd_analysisp',
                'vorbis_info *vd_vi',
                'float *vd_pcm',
                'float *vd_pcmret',
                'int      vd_pcm_storage',
                'int      vd_pcm_current',
                'int      vd_pcm_returned',
                'int  vd_preextrapolate',
                'int  vd_eofflag',
                'long vd_lW',
                'long vd_W',
                'long vd_nW',
                'long vd_centerW',
                'ogg_int64_t vd_granulepos',
                'ogg_int64_t vd_sequence',
                'ogg_int64_t vd_glue_bits',
                'ogg_int64_t vd_time_bits',
                'ogg_int64_t vd_floor_bits',
                'ogg_int64_t vd_res_bits',
                'void       *vd_backend_state',

                # 'vorbis_block     vb',
                'float  **vb_pcm',

                # vb - 'oggpack_buffer opb',
                'long vb_opb_endbyte',
                'int  vb_opb_endbit',
                'unsigned char *vb_opb_buffer',
                'unsigned char *vb_opb_ptr',
                'long vb_opb_storage',

                'long  vb_lW',
                'long  vb_W',
                'long  vb_nW',
                'int   vb_pcmend',
                'int   vb_mode',
                'int         vb_eofflag',
                'ogg_int64_t vb_granulepos',
                'ogg_int64_t vb_sequence',
                'vorbis_dsp_state *vb_vd',
                'void               *vb_localstore',
                'long                vb_localtop',
                'long                vb_localalloc',
                'long                vb_totaluse',
                'struct alloc_chain *vb_reap',
                'long vb_glue_bits',
                'long vb_time_bits',
                'long vb_floor_bits',
                'long vb_res_bits',
                'void *vb_internal',

                # 'ov_callbacks callbacks'
                'size_t *read_func',
                'int    *seek_func',
                'int    *close_func',
                'long   *tell_func'])


      # extern int ov_clear(OggVorbis_File *vf);
      # extern int ov_fopen(const char *path,OggVorbis_File *vf);
      # extern int ov_open(FILE *f,OggVorbis_File *vf,const char *initial,long ibytes);
      # extern int ov_open_callbacks(void *datasource, OggVorbis_File *vf,
      #                 const char *initial, long ibytes, ov_callbacks callbacks);

      # extern int ov_test(FILE *f,OggVorbis_File *vf,const char *initial,long ibytes);
      # extern int ov_test_callbacks(void *datasource, OggVorbis_File *vf,
      #                 const char *initial, long ibytes, ov_callbacks callbacks);
      # extern int ov_test_open(OggVorbis_File *vf);

      # extern long ov_bitrate(OggVorbis_File *vf,int i);
      # extern long ov_bitrate_instant(OggVorbis_File *vf);
      # extern long ov_streams(OggVorbis_File *vf);
      # extern long ov_seekable(OggVorbis_File *vf);
      # extern long ov_serialnumber(OggVorbis_File *vf,int i);

      # extern ogg_int64_t ov_raw_total(OggVorbis_File *vf,int i);
      # extern ogg_int64_t ov_pcm_total(OggVorbis_File *vf,int i);
      # extern double ov_time_total(OggVorbis_File *vf,int i);

      # extern int ov_raw_seek(OggVorbis_File *vf,ogg_int64_t pos);
      # extern int ov_pcm_seek(OggVorbis_File *vf,ogg_int64_t pos);
      # extern int ov_pcm_seek_page(OggVorbis_File *vf,ogg_int64_t pos);
      # extern int ov_time_seek(OggVorbis_File *vf,double pos);
      # extern int ov_time_seek_page(OggVorbis_File *vf,double pos);

      # extern int ov_raw_seek_lap(OggVorbis_File *vf,ogg_int64_t pos);
      # extern int ov_pcm_seek_lap(OggVorbis_File *vf,ogg_int64_t pos);
      # extern int ov_pcm_seek_page_lap(OggVorbis_File *vf,ogg_int64_t pos);
      # extern int ov_time_seek_lap(OggVorbis_File *vf,double pos);
      # extern int ov_time_seek_page_lap(OggVorbis_File *vf,double pos);

      # extern ogg_int64_t ov_raw_tell(OggVorbis_File *vf);
      # extern ogg_int64_t ov_pcm_tell(OggVorbis_File *vf);
      # extern double ov_time_tell(OggVorbis_File *vf);

      # extern vorbis_info *ov_info(OggVorbis_File *vf,int link);
      # extern vorbis_comment *ov_comment(OggVorbis_File *vf,int link);

      # extern long ov_read_float(OggVorbis_File *vf,float ***pcm_channels,int samples,
      #                           int *bitstream);
      # extern long ov_read_filter(OggVorbis_File *vf,char *buffer,int length,
      #                           int bigendianp,int word,int sgned,int *bitstream,
      #                           void (*filter)(float **pcm,long channels,long samples,void *filter_param),void *filter_param);
      # extern long ov_read(OggVorbis_File *vf,char *buffer,int length,
      #                     int bigendianp,int word,int sgned,int *bitstream);
      # extern int ov_crosslap(OggVorbis_File *vf1,OggVorbis_File *vf2);

      # extern int ov_halfrate(OggVorbis_File *vf,int flag);
      # extern int ov_halfrate_p(OggVorbis_File *vf);


      extern('int ov_clear(OggVorbis_File *vf)')
      extern('int ov_fopen(const char *path,OggVorbis_File *vf)')
      extern('int ov_open(FILE *f,OggVorbis_File *vf,const char *initial,long)')
      # extern('int ov_open_callbacks(void *datasource, OggVorbis_File *vf, const char *initial, long, ov_callbacks)')
      extern('int ov_open_callbacks(void *datasource, OggVorbis_File *vf, const char *initial, long,
              size_t *read_func, int *seek_func, int *closes_func, long *tell_func)')
      extern('int ov_test(FILE *f,OggVorbis_File *vf,const char *initial,long)')
      # extern('int ov_test_callbacks(void *datasource, OggVorbis_File *vf, const char *initial, long, ov_callbacks)')
      extern('int ov_test_callbacks(void *datasource, OggVorbis_File *vf, const char *initial, long,
              size_t *read_func, int *seek_func, int *closes_func, long *tell_func)')
      extern('int ov_test_open(OggVorbis_File *vf)')

      extern('long ov_bitrate(OggVorbis_File *vf,int)')
      extern('long ov_bitrate_instant(OggVorbis_File *vf)')
      extern('long ov_streams(OggVorbis_File *vf)')
      extern('long ov_seekable(OggVorbis_File *vf)')
      extern('long ov_serialnumber(OggVorbis_File *vf,int)')

      extern('ogg_int64_t ov_raw_total(OggVorbis_File *vf,int)')
      extern('ogg_int64_t ov_pcm_total(OggVorbis_File *vf,int)')
      extern('double ov_time_total(OggVorbis_File *vf,int)')

      extern('int ov_raw_seek(OggVorbis_File *vf,ogg_int64_t)')
      extern('int ov_pcm_seek(OggVorbis_File *vf,ogg_int64_t)')
      extern('int ov_pcm_seek_page(OggVorbis_File *vf,ogg_int64_t)')
      extern('int ov_time_seek(OggVorbis_File *vf,double)')
      extern('int ov_time_seek_page(OggVorbis_File *vf,double)')

      extern('int ov_raw_seek_lap(OggVorbis_File *vf,ogg_int64_t)')
      extern('int ov_pcm_seek_lap(OggVorbis_File *vf,ogg_int64_t)')
      extern('int ov_pcm_seek_page_lap(OggVorbis_File *vf,ogg_int64_t)')
      extern('int ov_time_seek_lap(OggVorbis_File *vf,double)')
      extern('int ov_time_seek_page_lap(OggVorbis_File *vf,double)')

      extern('ogg_int64_t ov_raw_tell(OggVorbis_File *vf)')
      extern('ogg_int64_t ov_pcm_tell(OggVorbis_File *vf)')
      extern('double ov_time_tell(OggVorbis_File *vf)')

      extern('vorbis_info *ov_info(OggVorbis_File *vf,int)')
      extern('vorbis_comment *ov_comment(OggVorbis_File *vf,int)')

      extern('long ov_read_float(OggVorbis_File *vf,float ***pcm_channels,int,
                          int *bitstream)')

      Filter = bind('void * filter(float **pcm,long, long, void *filter_param)', :temp)
      extern('long ov_read_filter(OggVorbis_File *vf,char *buffer,int,
                          int,int,int,int *bitstream,
                          void *filter, void *filter_param)')
      extern('long ov_read(OggVorbis_File *vf,char *buffer,int,
                    int,int,int,int *bitstream)')
      extern('int ov_crosslap(OggVorbis_File *vf1,OggVorbis_File *vf2)')

      extern('int ov_halfrate(OggVorbis_File *vf,int)')
      extern('int ov_halfrate_p(OggVorbis_File *vf)')
    end
  end
end
