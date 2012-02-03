#-*- coding: utf-8 -*-

require 'dl/import'
require 'raudio/data'

module RAudio
  class Codec
    #== libfaad2 wrapper
    module LibFaad2
      extend DL::Importer
      begin
        dlload('libfaad.so')
        AVAILABLE = true
      rescue DL::DLError => e
        STDERR.puts e
        AVAILABLE = false
      end 

      RAudio::Data::TypeAlias.each_pair{|k, v| typealias(k, v)}

      FAAD2_VERSION = '2.7'

      # /* object types for AAC */
      MAIN      =  1
      LC        =  2
      SSR       =  3
      LTP       =  4
      HE_AAC    =  5
      ER_LC     = 17
      ER_LTP    = 19
      LD        = 23
      DRM_ER_LC = 27 # /* special object type for DRM */

      # /* header types */
      RAW       = 0
      ADIF      = 1
      ADTS      = 2
      LATM      = 3

      # /* SBR signalling */
      NO_SBR           = 0
      SBR_UPSAMPLED    = 1
      SBR_DOWNSAMPLED  = 2
      NO_SBR_UPSAMPLED = 3

      # /* library output formats */
      FAAD_FMT_16BIT  = 1
      FAAD_FMT_24BIT  = 2
      FAAD_FMT_32BIT  = 3
      FAAD_FMT_FLOAT  = 4
      FAAD_FMT_FIXED  = FAAD_FMT_FLOAT
      FAAD_FMT_DOUBLE = 5

      # /* Capabilities */
      LC_DEC_CAP           = (1<<0) # /* Can decode LC */
      MAIN_DEC_CAP         = (1<<1) # /* Can decode MAIN */
      LTP_DEC_CAP          = (1<<2) # /* Can decode LTP */
      LD_DEC_CAP           = (1<<3) # /* Can decode LD */
      ERROR_RESILIENCE_CAP = (1<<4) # /* Can decode ER */
      FIXED_POINT_CAP      = (1<<5) # /* Fixed point */

      # /* Channel definitions */
      FRONT_CHANNEL_CENTER = (1)
      FRONT_CHANNEL_LEFT   = (2)
      FRONT_CHANNEL_RIGHT  = (3)
      SIDE_CHANNEL_LEFT    = (4)
      SIDE_CHANNEL_RIGHT   = (5)
      BACK_CHANNEL_LEFT    = (6)
      BACK_CHANNEL_RIGHT   = (7)
      BACK_CHANNEL_CENTER  = (8)
      LFE_CHANNEL          = (9)
      UNKNOWN_CHANNEL      = (0)

      # /* DRM channel definitions */
      DRMCH_MONO           = 1
      DRMCH_STEREO         = 2
      DRMCH_SBR_MONO       = 3
      DRMCH_SBR_STEREO     = 4
      DRMCH_SBR_PS_STEREO  = 5


      # /* A decode call can eat up to FAAD_MIN_STREAMSIZE bytes per decoded channel,
      #    so at least so much bytes per channel should be available in this stream */
      FAAD_MIN_STREAMSIZE = 768 # /* 6144 bits/channel */


      # typedef void *NeAACDecHandle;

      # typedef struct mp4AudioSpecificConfig
      # {
      #     /* Audio Specific Info */
      #     unsigned char objectTypeIndex;
      #     unsigned char samplingFrequencyIndex;
      #     unsigned long samplingFrequency;
      #     unsigned char channelsConfiguration;

      #     /* GA Specific Info */
      #     unsigned char frameLengthFlag;
      #     unsigned char dependsOnCoreCoder;
      #     unsigned short coreCoderDelay;
      #     unsigned char extensionFlag;
      #     unsigned char aacSectionDataResilienceFlag;
      #     unsigned char aacScalefactorDataResilienceFlag;
      #     unsigned char aacSpectralDataResilienceFlag;
      #     unsigned char epConfig;

      #     char sbr_present_flag;
      #     char forceUpSampling;
      #     char downSampledSBR;
      # } mp4AudioSpecificConfig;

      Mp4AudioSpecificConfig = 
        struct(['unsigned char objectTypeIndex',
                'unsigned char samplingFrequencyIndex',
                'unsigned long samplingFrequency',
                'unsigned char channelsConfiguration',
                'unsigned char frameLengthFlag',
                'unsigned char dependsOnCoreCoder',
                'unsigned short coreCoderDelay',
                'unsigned char extensionFlag',
                'unsigned char aacSectionDataResilienceFlag',
                'unsigned char aacScalefactorDataResilienceFlag',
                'unsigned char aacSpectralDataResilienceFlag',
                'unsigned char epConfig',

                'char sbr_present_flag',
                'char forceUpSampling',
                'char downSampledSBR'])



      # typedef struct NeAACDecConfiguration
      # {
      #     unsigned char defObjectType;
      #     unsigned long defSampleRate;
      #     unsigned char outputFormat;
      #     unsigned char downMatrix;
      #     unsigned char useOldADTSFormat;
      #     unsigned char dontUpSampleImplicitSBR;
      # } NeAACDecConfiguration, *NeAACDecConfigurationPtr;

      NeAACDecConfiguration =
        struct(['unsigned char defObjectType',
                'unsigned long defSampleRate',
                'unsigned char outputFormat',
                'unsigned char downMatrix',
                'unsigned char useOldADTSFormat',
                'unsigned char dontUpSampleImplicitSBR'])


      # typedef struct NeAACDecFrameInfo
      # {
      #     unsigned long bytesconsumed;
      #     unsigned long samples;
      #     unsigned char channels;
      #     unsigned char error;
      #     unsigned long samplerate;

      #     /* SBR: 0: off, 1: on; upsample, 2: on; downsampled, 3: off; upsampled */
      #     unsigned char sbr;

      #     /* MPEG-4 ObjectType */
      #     unsigned char object_type;

      #     /* AAC header type; MP4 will be signalled as RAW also */
      #     unsigned char header_type;

      #     /* multichannel configuration */
      #     unsigned char num_front_channels;
      #     unsigned char num_side_channels;
      #     unsigned char num_back_channels;
      #     unsigned char num_lfe_channels;
      #     unsigned char channel_position[64];

      #     /* PS: 0: off, 1: on */
      #     unsigned char ps;
      # } NeAACDecFrameInfo;

      NeAACDecFrameInfo =
        struct(['unsigned long bytesconsumed',
                'unsigned long samples',
                'unsigned char channels',
                'unsigned char error',
                'unsigned long samplerate',
                'unsigned char sbr',
                'unsigned char object_type',
                'unsigned char header_type',
                'unsigned char num_front_channels',
                'unsigned char num_side_channels',
                'unsigned char num_back_channels',
                'unsigned char num_lfe_channels',
                'unsigned char channel_position[64]',
                'unsigned char ps'])


      # char* NEAACDECAPI NeAACDecGetErrorMessage(unsigned char errcode);
      extern('char* NeAACDecGetErrorMessage(unsigned char)')

      # unsigned long NEAACDECAPI NeAACDecGetCapabilities(void);
      extern('unsigned long NeAACDecGetCapabilities(void)')

      # NeAACDecHandle NEAACDECAPI NeAACDecOpen(void);
      extern('NeAACDecHandle NeAACDecOpen(void)')

      # NeAACDecConfigurationPtr NEAACDECAPI NeAACDecGetCurrentConfiguration(NeAACDecHandle hDecoder);
      extern('NeAACDecConfigurationPtr NeAACDecGetCurrentConfiguration(NeAACDecHandle)')

      # unsigned char NEAACDECAPI NeAACDecSetConfiguration(NeAACDecHandle hDecoder,
      #                                                   NeAACDecConfigurationPtr config);
      extern('unsigned char NeAACDecSetConfiguration(NeAACDecHandle, NeAACDecConfigurationPtr)')

      # /* Init the library based on info from the AAC file (ADTS/ADIF) */
      # long NEAACDECAPI NeAACDecInit(NeAACDecHandle hDecoder,
      #                               unsigned char *buffer,
      #                               unsigned long buffer_size,
      #                               unsigned long *samplerate,
      #                               unsigned char *channels);
      extern('long NeAACDecInit(NeAACDecHandle,
                              unsigned char *buffer,
                              unsigned long,
                              unsigned long *samplerate,
                              unsigned char *channels)')

      # /* Init the library using a DecoderSpecificInfo */
      # char NEAACDECAPI NeAACDecInit2(NeAACDecHandle hDecoder,
      #                                unsigned char *pBuffer,
      #                                unsigned long SizeOfDecoderSpecificInfo,
      #                                unsigned long *samplerate,
      #                                unsigned char *channels);

      extern('char NeAACDecInit2(NeAACDecHandle,
                               unsigned char *pBuffer,
                               unsigned long,
                               unsigned long *samplerate,
                               unsigned char *channels)')

      # /* Init the library for DRM */
      # char NEAACDECAPI NeAACDecInitDRM(NeAACDecHandle *hDecoder, unsigned long samplerate,
      #                                  unsigned char channels);
      begin
        extern('char NeAACDecInitDRM(NeAACDecHandle *hDecoder, unsigned long, unsigned char)')
      rescue => err
        STDERR.puts err
      end

      # void NEAACDECAPI NeAACDecPostSeekReset(NeAACDecHandle hDecoder, long frame);
      extern('void NeAACDecPostSeekReset(NeAACDecHandle, long)')

      # void NEAACDECAPI NeAACDecClose(NeAACDecHandle hDecoder);
      extern('void NeAACDecClose(NeAACDecHandle)')

      # void* NEAACDECAPI NeAACDecDecode(NeAACDecHandle hDecoder,
      #                                  NeAACDecFrameInfo *hInfo,
      #                                  unsigned char *buffer,
      #                                  unsigned long buffer_size);
      extern('void* NeAACDecDecode(NeAACDecHandle,
                                 NeAACDecFrameInfo *hInfo,
                                 unsigned char *buffer,
                                 unsigned long)')

      # void* NEAACDECAPI NeAACDecDecode2(NeAACDecHandle hDecoder,
      #                                   NeAACDecFrameInfo *hInfo,
      #                                   unsigned char *buffer,
      #                                   unsigned long buffer_size,
      #                                   void **sample_buffer,
      #                                   unsigned long sample_buffer_size);
      extern('void* NeAACDecDecode2(NeAACDecHandle,
                                  NeAACDecFrameInfo *hInfo,
                                  unsigned char *buffer,
                                  unsigned long,
                                  void **sample_buffer,
                                  unsigned long)')

      # char NEAACDECAPI NeAACDecAudioSpecificConfig(unsigned char *pBuffer,
      #                                              unsigned long buffer_size,
      #                                              mp4AudioSpecificConfig *mp4ASC);
      extern('char NeAACDecAudioSpecificConfig(unsigned char *pBuffer,
                                             unsigned long,
                                             mp4AudioSpecificConfig *mp4ASC)')

    end
  end
end
