#-*- coding: utf-8 -*-

require 'dl/import'
require 'raudio/data'
# require 'raudio/codec/xiph/libogg'

module RAudio
  class Codec
    #== libvorbis wrapper
    module LibFishSound
      extend DL::Importer
      begin
        # dlload('libfishsound.so')
        dlload('libfishsound.so')
        AVAILABLE = true
      rescue DL::DLError => e
        STDERR.puts e
        AVAILABLE = false
      end

      RAudio::Data::TypeAlias.each_pair{|k, v| typealias(k, v)}

      # fishsound/constats.h
      # /** Mode of operation (encode or decode) */
      # typedef enum _FishSoundMode {
      #   /** Decode */
      #   FISH_SOUND_DECODE = 0x10,

      #   /** Encode */
      #   FISH_SOUND_ENCODE = 0x20
      # } FishSoundMode;

      FishSoundMode = {
        'FISH_SOUND_DECODE' => 0x10,
        'FISH_SOUND_ENCODE' => 0x20
      }

      # /** Identifiers for supported codecs */
      FishSoundCodecID = {
        'FISH_SOUND_UNKNOWN' => 0x00,
        'FISH_SOUND_VORBIS'  => 0x01,
        'FISH_SOUND_SPEEX'   => 0x02,
        'FISH_SOUND_FLAC'    => 0x03
      }

      # /** Decode callback return values */
      # typedef enum _FishSoundStopCtl {
      #   /** Continue calling decode callbacks */
      #   FISH_SOUND_CONTINUE = 0,
      
      #   /** Stop calling callbacks, but retain buffered data */
      #   FISH_SOUND_STOP_OK  = 1,
      
      #   /** Stop calling callbacks, and purge buffered data */
      #   FISH_SOUND_STOP_ERR = -1
      # } FishSoundStopCtl;

      FishSoundStopCtl = {
        'FISH_SOUND_CONTINUE' => 0,
        'FISH_SOUND_STOP_OK'  => 1,
        'FISH_SOUND_STOP_ERR' => -1
      }

      # /** Command codes */
      # typedef enum _FishSoundCommand {
      #   /** No operation */
      #   FISH_SOUND_COMMAND_NOP                = 0x0000,

      #   /** Retrieve the FishSoundInfo */
      #   FISH_SOUND_GET_INFO                   = 0x1000,

      #   /** Query if multichannel audio should be interpreted as interleaved */
      #   FISH_SOUND_GET_INTERLEAVE             = 0x2000,

      #   /** Set to 1 to interleave, 0 to non-interleave */
      #   FISH_SOUND_SET_INTERLEAVE             = 0x2001,

      #   FISH_SOUND_SET_ENCODE_VBR             = 0x4000,
      
      #   FISH_SOUND_COMMAND_MAX
      # } FishSoundCommand;

      FishSoundCommand = {
        'FISH_SOUND_COMMAND_NOP'        => 0x0000,
        'FISH_SOUND_GET_INFO'           => 0x1000,
        'FISH_SOUND_GET_INTERLEAVE'     => 0x2000,
        'FISH_SOUND_SET_INTERLEAVE'     => 0x2001,
        'FISH_SOUND_SET_ENCODE_VBR'     => 0x4000,
        # FISH_SOUND_COMMAND_MAX                => 
      }

      # /** Error values */
      # typedef enum _FishSoundError {
      #   /** No error */
      #   FISH_SOUND_OK                         = 0,

      #   /** generic error */
      #   FISH_SOUND_ERR_GENERIC                = -1,

      #   /** Not a valid FishSound* handle */
      #   FISH_SOUND_ERR_BAD                    = -2,

      #   /** The requested operation is not suitable for this FishSound* handle */
      #   FISH_SOUND_ERR_INVALID                = -3,

      #   /** Out of memory */
      #   FISH_SOUND_ERR_OUT_OF_MEMORY          = -4,

      #   /** Functionality disabled at build time */
      #   FISH_SOUND_ERR_DISABLED               = -10,

      #   /** Too few bytes passed to fish_sound_identify() */
      #   FISH_SOUND_ERR_SHORT_IDENTIFY         = -20,

      #   /** Comment violates VorbisComment restrictions */
      #   FISH_SOUND_ERR_COMMENT_INVALID        = -21
      # } FishSoundError;

      FishSoundError = {
        'FISH_SOUND_OK'                    => 0,
        'FISH_SOUND_ERR_GENERIC'           => -1,
        'FISH_SOUND_ERR_BAD'               => -2,
        'FISH_SOUND_ERR_INVALID'           => -3,
        'FISH_SOUND_ERR_OUT_OF_MEMORY'     => -4,
        'FISH_SOUND_ERR_DISABLED'          => -10,
        'FISH_SOUND_ERR_SHORT_IDENTIFY'    => -20,
        'FISH_SOUND_ERR_COMMENT_INVALID'   => -21
      }


      # fishsound/fishsound.h
      # /**
      #  * Info about a particular encoder/decoder instance
      #  */
      # typedef struct {
      #   /** Sample rate of audio data in Hz */
      #   int samplerate;

      #   /** Count of channels */
      #   int channels;

      #   /** FISH_SOUND_VORBIS, FISH_SOUND_SPEEX, FISH_SOUND_FLAC etc. */
      #   int format;
      # } FishSoundInfo;

      FishSoundInfo =
        struct(['int samplerate',
                'int channels',
                'int format'])


      # /**
      #  * Info about a particular sound format
      #  */
      # typedef struct {
      #   /** FISH_SOUND_VORBIS, FISH_SOUND_SPEEX, FISH_SOUND_FLAC etc. */
      #   int format;

      #   /** Printable name */
      #   const char * name;     

      #   /** Commonly used file extension */
      #   const char * extension;
      # } FishSoundFormat;

      FishSoundFormat =
        struct(['int format',
                'const char * name',
                'const char * extension'])


      # /**
      #  * An opaque handle to a FishSound. This is returned by fishsound_new()
      #  * and is passed to all other fish_sound_*() functions.
      #  */
      # typedef void * FishSound;


      # /**
      #  * Identify a codec based on the first few bytes of data.
      #  * \param buf A pointer to the first few bytes of the data
      #  * \param bytes The count of bytes available at buf
      #  * \retval FISH_SOUND_xxxxxx FISH_SOUND_VORBIS, FISH_SOUND_SPEEX or
      #  * FISH_SOUND_FLAC if \a buf was identified as the initial bytes of a
      #  * supported codec
      #  * \retval FISH_SOUND_UNKNOWN if the codec could not be identified
      #  * \retval FISH_SOUND_ERR_SHORT_IDENTIFY if \a bytes is less than 8
      #  * \note If \a bytes is exactly 8, then only a weak check is performed,
      #  * which is fast but may return a false positive.
      #  * \note If \a bytes is greater than 8, then a stronger check is performed
      #  * in which an attempt is made to decode \a buf as the initial header of
      #  * each supported codec. This is unlikely to return a false positive but
      #  * is only useful if \a buf is the entire payload of a packet derived from
      #  * a lower layer such as Ogg framing or UDP datagrams.
      #  */
      # int
      # fish_sound_identify (unsigned char * buf, long bytes);
      extern('int fish_sound_identify (unsigned char * buf, long)')

      # /**
      #  * Instantiate a new FishSound* handle
      #  * \param mode FISH_SOUND_DECODE or FISH_SOUND_ENCODE
      #  * \param fsinfo Encoder configuration, may be NULL for FISH_SOUND_DECODE
      #  * \returns A new FishSound* handle, or NULL on error
      #  */
      # FishSound * fish_sound_new (int mode, FishSoundInfo * fsinfo);
      extern('FishSound * fish_sound_new (int, FishSoundInfo * fsinfo)')

      # /**
      #  * Flush any internally buffered data, forcing encode
      #  * \param fsound A FishSound* handle
      #  * \returns 0 on success, -1 on failure
      #  */
      # long fish_sound_flush (FishSound * fsound);
      extern('long fish_sound_flush (FishSound * fsound)')

      # /**
      #  * Reset the codec state of a FishSound object.
      #  *
      #  * When decoding from a seekable file, fish_sound_reset() should be called
      #  * after any seek operations. See also fish_sound_set_frameno().
      #  *
      #  * \param fsound A FishSound* handle
      #  * \returns 0 on success, -1 on failure
      #  */
      # int fish_sound_reset (FishSound * fsound);
      extern('int fish_sound_reset (FishSound * fsound)')

      # /**
      #  * Delete a FishSound object
      #  * \param fsound A FishSound* handle
      #  * \returns 0 on success, -1 on failure
      #  */
      # int fish_sound_delete (FishSound * fsound);
      extern('int fish_sound_delete (FishSound * fsound)')

      # /**
      #  * Command interface
      #  * \param fsound A FishSound* handle
      #  * \param command The command action
      #  * \param data Command data
      #  * \param datasize Size of the data in bytes
      #  * \returns 0 on success, -1 on failure
      #  */
      # int fish_sound_command (FishSound * fsound, int command, void * data,
      # 			int datasize);
      extern('int fish_sound_command (FishSound * fsound, int, void * data, int)')

      # /**
      #  * Query whether a FishSound object is using interleaved PCM
      #  * \param fsound A FishSound* handle
      #  * \retval 0 \a fsound uses non-interleaved PCM
      #  * \retval 1 \a fsound uses interleaved PCM
      #  * \retval -1 Invalid \a fsound, or out of memory.
      #  */
      # int fish_sound_get_interleave (FishSound * fsound);
      extern('int fish_sound_get_interleave (FishSound * fsound)')
      
      # /**
      #  * Query the current frame number of a FishSound object.
      #  *
      #  * For decoding, this is the greatest frame index that has been decoded and
      #  * made available to a FishSoundDecoded callback. This function is safe to
      #  * call from within a FishSoundDecoded callback, and corresponds to the frame
      #  * number of the last frame in the current decoded block.
      #  *
      #  * For encoding, this is the greatest frame index that has been encoded. This
      #  * function is safe to call from within a FishSoundEncoded callback, and
      #  * corresponds to the frame number of the last frame encoded in the current
      #  * block.
      #  *
      #  * \param fsound A FishSound* handle
      #  * \returns The current frame number
      #  * \retval -1 Invalid \a fsound
      #  */
      # long fish_sound_get_frameno (FishSound * fsound);
      extern('long fish_sound_get_frameno (FishSound * fsound)')

      # /**
      #  * Set the current frame number of a FishSound object.
      #  *
      #  * When decoding from a seekable file, fish_sound_set_frameno() should be
      #  * called after any seek operations, otherwise the value returned by
      #  * fish_sound_get_frameno() will simply continue to increment. See also
      #  * fish_sound_reset().
      #  *
      #  * \param fsound A FishSound* handle
      #  * \param frameno The current frame number.
      #  * \retval 0 Success
      #  * \retval -1 Invalid \a fsound
      #  */
      # int fish_sound_set_frameno (FishSound * fsound, long frameno);
      extern('int fish_sound_set_frameno (FishSound * fsound, long)')

      # /**
      #  * Prepare truncation details for the next block of data.
      #  * The semantics of these parameters derives directly from Ogg encapsulation
      #  * of Vorbis, described
      #  * <a href="http://www.xiph.org/ogg/vorbis/doc/Vorbis_I_spec.html#vorbis-over-ogg">here</a>.
      #  *
      #  * When decoding from Ogg, you should call this function with the \a granulepos
      #  * and \a eos of the \a ogg_packet structure. This call should be made before
      #  * passing the packet's data to fish_sound_decode(). Failure to do so may
      #  * result in minor decode errors on the first and/or last packet of the stream.
      #  *
      #  * When encoding into Ogg, you should call this function with the \a granulepos
      #  * and \a eos that will be used for the \a ogg_packet structure. This call
      #  * should be made before passing the block of audio data to
      #  * fish_sound_encode_*(). Failure to do so may result in minor encoding errors
      #  * on the first and/or last packet of the stream.
      #  *
      #  * \param fsound A FishSound* handle
      #  * \param next_granulepos The "granulepos" for the next block to decode.
      #  *        If unknown, set \a next_granulepos to -1. Otherwise,
      #  *        \a next_granulepos specifies the frameno of the final frame in the
      #  *        block. This is authoritative, hence can be used to indicate
      #  *        various forms of truncation at the beginning or end of a stream.
      #  *        Mid-stream, a later-than-expected "granulepos" indicates that some
      #  *        data was missing. 
      #  * \param next_eos A boolean indicating whether the next data block will be
      #  *        the last in the stream.
      #  * \retval 0 Success
      #  * \retval -1 Invalid \a fsound
      #  */
      # int fish_sound_prepare_truncation (FishSound * fsound, long next_granulepos,
      #                                    int next_eos);
      extern('int fish_sound_prepare_truncation (FishSound * fsound, long, int)')

      # fishsound/decode.h
      # /**
      #  * Signature of a callback for libfishsound to call when it has decoded
      #  * PCM audio data, and you want this provided as non-interleaved floats.
      #  * \param fsound The FishSound* handle
      #  * \param pcm The decoded audio
      #  * \param frames The count of frames decoded
      #  * \param user_data Arbitrary user data
      #  * \retval FISH_SOUND_CONTINUE Continue decoding
      #  * \retval FISH_SOUND_STOP_OK Stop decoding immediately and
      #  * return control to the fish_sound_decode() caller
      #  * \retval FISH_SOUND_STOP_ERR Stop decoding immediately, purge buffered
      #  * data, and return control to the fish_sound_decode() caller
      #  */
      # typedef int (*FishSoundDecoded_Float) (FishSound * fsound, float * pcm[],
      # 				       long frames, void * user_data);
      FishSoundDecoded_Float = 
        bind('int * FishSoundDecoded_Float (FishSound *, float *[], long, void *)', :temp)

      # /**
      #  * Signature of a callback for libfishsound to call when it has decoded
      #  * PCM audio data, and you want this provided as interleaved floats.
      #  * \param fsound The FishSound* handle
      #  * \param pcm The decoded audio
      #  * \param frames The count of frames decoded
      #  * \param user_data Arbitrary user data
      #  * \retval FISH_SOUND_CONTINUE Continue decoding
      #  * \retval FISH_SOUND_STOP_OK Stop decoding immediately and
      #  * return control to the fish_sound_decode() caller
      #  * \retval FISH_SOUND_STOP_ERR Stop decoding immediately, purge buffered
      #  * data, and return control to the fish_sound_decode() caller
      #  */
      # typedef int (*FishSoundDecoded_FloatIlv) (FishSound * fsound, float ** pcm,
      # 					  long frames, void * user_data);
      FishSoundDecoded_FloatIlv = 
        bind('int * FishSoundDecoded_FloatIlv (FishSound *, float *[], long, void *)', :temp)
      
      # /**
      #  * Set the callback for libfishsound to call when it has a block of decoded
      #  * PCM audio ready, and you want this provided as non-interleaved floats.
      #  * \param fsound A FishSound* handle (created with mode FISH_SOUND_DECODE)
      #  * \param decoded The callback to call
      #  * \param user_data Arbitrary user data to pass to the callback
      #  * \retval 0 Success
      #  * \retval FISH_SOUND_ERR_BAD Not a valid FishSound* handle
      #  * \retval FISH_SOUND_ERR_OUT_OF_MEMORY Out of memory
      #  */
      # int fish_sound_set_decoded_float (FishSound * fsound,
      # 				  FishSoundDecoded_Float decoded,
      # 				  void * user_data);
      extern('int fish_sound_set_decoded_float (FishSound * fsound,
				  FishSoundDecoded_Float, void * user_data)')

      # /**
      #  * Set the callback for libfishsound to call when it has a block of decoded
      #  * PCM audio ready, and you want this provided as interleaved floats.
      #  * \param fsound A FishSound* handle (created with mode FISH_SOUND_DECODE)
      #  * \param decoded The callback to call
      #  * \param user_data Arbitrary user data to pass to the callback
      #  * \retval 0 Success
      #  * \retval FISH_SOUND_ERR_BAD Not a valid FishSound* handle
      #  * \retval FISH_SOUND_ERR_OUT_OF_MEMORY Out of memory
      #  */
      extern('int fish_sound_set_decoded_float_ilv (FishSound * fsound,
				      FishSoundDecoded_FloatIlv, void * user_data)')

      # /**
      #  * Decode a block of compressed data.
      #  * No internal buffering is done, so a complete compressed audio packet
      #  * must be passed each time.
      #  * \param fsound A FishSound* handle (created with mode FISH_SOUND_DECODE)
      #  * \param buf A buffer containing a compressed audio packet
      #  * \param bytes A count of bytes to decode (i.e. the length of buf)
      #  * \returns The number of bytes consumed
      #  * \retval FISH_SOUND_ERR_STOP_OK Decoding was stopped by a FishSoundDecode*
      #  * callback returning FISH_SOUND_STOP_OK before any input bytes were consumed.
      #  * This will occur when PCM is decoded from previously buffered input, and
      #  * stopping is immediately requested.
      #  * \retval FISH_SOUND_ERR_STOP_ERR Decoding was stopped by a FishSoundDecode*
      #  * callback returning FISH_SOUND_STOP_ERR before any input bytes were consumed.
      #  * This will occur when PCM is decoded from previously buffered input, and
      #  * stopping is immediately requested.
      #  * \retval FISH_SOUND_ERR_BAD Not a valid FishSound* handle
      #  * \retval FISH_SOUND_ERR_OUT_OF_MEMORY Out of memory
      #  */
      extern('long fish_sound_decode (FishSound * fsound, unsigned char * buf, long)')


      # fishsound/encode.h
      # /**
      # * Signature of a callback for libfishsound to call when it has encoded
      # * data.
      # * \param fsound The FishSound* handle
      # * \param buf The encoded data
      # * \param bytes The count of bytes encoded
      # * \param user_data Arbitrary user data
      # * \retval 0 to continue
      # * \retval non-zero to stop encoding immediately and
      # * return control to the fish_sound_encode() caller
      # */
      # typedef int (*FishSoundEncoded) (FishSound * fsound, unsigned char * buf,
      # 				 long bytes, void * user_data);

      # /**
      # * Set the callback for libfishsound to call when it has a block of
      # * encoded data ready
      # * \param fsound A FishSound* handle (created with mode FISH_SOUND_ENCODE)
      # * \param encoded The callback to call
      # * \param user_data Arbitrary user data to pass to the callback
      # * \returns 0 on success, -1 on failure
      # */
      # int fish_sound_set_encoded_callback (FishSound * fsound,
      # 				     FishSoundEncoded encoded,
      # 				     void * user_data);
      extern('int fish_sound_set_encoded_callback (FishSound * fsound,
				     FishSoundEncoded, void * user_data)')

      # /**
      #  * Encode a block of PCM audio given as non-interleaved floats.
      #  * \param fsound A FishSound* handle (created with mode FISH_SOUND_ENCODE)
      #  * \param pcm The audio data to encode
      #  * \param frames A count of frames to encode
      #  * \returns The number of frames encoded
      #  * \note For multichannel audio, the audio data is interpreted according
      #  * to the current PCM style
      #  */
      # long fish_sound_encode_float (FishSound * fsound, float * pcm[], long frames);
      extern('long fish_sound_encode_float (FishSound * fsound, float * pcm[], long)')

      # /**
      #  * Encode a block of audio given as interleaved floats.
      #  * \param fsound A FishSound* handle (created with mode FISH_SOUND_ENCODE)
      #  * \param pcm The audio data to encode
      #  * \param frames A count of frames to encode
      #  * \returns The number of frames encoded
      #  * \note For multichannel audio, the audio data is interpreted according
      #  * to the current PCM style
      #  */
      # long fish_sound_encode_float_ilv (FishSound * fsound, float ** pcm,
      # 				  long frames);
      extern('long fish_sound_encode_float_ilv (FishSound * fsound, float ** pcm, long)')


      # fishsound/comments.h
      # /**
      #  * A comment.
      #  */
      # typedef struct {
      #   /** The name of the comment, eg. "AUTHOR" */
      #   char * name;

      #   /** The value of the comment, as UTF-8 */
      #   char * value;
      # } FishSoundComment;
      FishSoundComment =
        struct(['char * name',
                'char * value'])


      # /**
      #  * Retrieve the vendor string.
      #  * \param fsound A FishSound* handle
      #  * \returns A read-only copy of the vendor string
      #  * \retval NULL No vendor string is associated with \a fsound,
      #  *              or \a fsound is NULL.
      #  */
      # const char *
      # fish_sound_comment_get_vendor (FishSound * fsound);
      extern('const char * fish_sound_comment_get_vendor (FishSound * fsound)')


      # /**
      #  * Retrieve the first comment.
      #  * \param fsound A FishSound* handle
      #  * \returns A read-only copy of the first comment, or NULL if no comments
      #  * exist for this FishSound* object.
      #  */
      # const FishSoundComment *
      # fish_sound_comment_first (FishSound * fsound);
      extern('const FishSoundComment * fish_sound_comment_first (FishSound * fsound)')

      # /**
      #  * Retrieve the next comment.
      #  * \param fsound A FishSound* handle
      #  * \param comment The previous comment.
      #  * \returns A read-only copy of the comment immediately following the given
      #  * comment.
      #  */
      # const FishSoundComment *
      # fish_sound_comment_next (FishSound * fsound, const FishSoundComment * comment);
      extern('const FishSoundComment * fish_sound_comment_next (FishSound * fsound, const FishSoundComment * comment)')

      # /**
      #  * Retrieve the first comment with a given name.
      #  * \param fsound A FishSound* handle
      #  * \param name the name of the comment to retrieve.
      #  * \returns A read-only copy of the first comment matching the given \a name.
      #  * \retval NULL no match was found.
      #  * \note If \a name is NULL, the behaviour is the same as for
      #  *   fish_sound_comment_first()
      #  */
      # const FishSoundComment *
      # fish_sound_comment_first_byname (FishSound * fsound, char * name);
      extern('const FishSoundComment * fish_sound_comment_first_byname (FishSound * fsound, char * name)')

      # /**
      #  * Retrieve the next comment following and with the same name as a given
      #  * comment.
      #  * \param fsound A FishSound* handle
      #  * \param comment A comment
      #  * \returns A read-only copy of the next comment with the same name as
      #  *          \a comment.
      #  * \retval NULL no further comments with the same name exist for
      #  *              this FishSound* object.
      #  */
      # const FishSoundComment *
      # fish_sound_comment_next_byname (FishSound * fsound,
      # 				const FishSoundComment * comment);
      extern('const FishSoundComment * fish_sound_comment_next_byname (FishSound * fsound,
				const FishSoundComment * comment)')

      # /**
      #  * Add a comment
      #  * \param fsound A FishSound* handle (created with mode FISH_SOUND_ENCODE)
      #  * \param comment The comment to add
      #  * \retval 0 Success
      #  * \retval FISH_SOUND_ERR_BAD \a fsound is not a valid FishSound* handle
      #  * \retval FISH_SOUND_ERR_INVALID Operation not suitable for this FishSound
      #  */
      # int
      # fish_sound_comment_add (FishSound * fsound, FishSoundComment * comment);
      extern('int fish_sound_comment_add (FishSound * fsound, FishSoundComment * comment)')

      # /**
      #  * Add a comment by name and value.
      #  * \param fsound A FishSound* handle (created with mode FISH_SOUND_ENCODE)
      #  * \param name The name of the comment to add
      #  * \param value The contents of the comment to add
      #  * \retval 0 Success
      #  * \retval FISH_SOUND_ERR_BAD \a fsound is not a valid FishSound* handle
      #  * \retval FISH_SOUND_ERR_INVALID Operation not suitable for this FishSound
      #  */
      # int
      # fish_sound_comment_add_byname (FishSound * fsound, const char * name,
      # 			       const char * value);
      extern('int fish_sound_comment_add_byname (FishSound * fsound, const char * name,
			       const char * value)')

      # /**
      #  * Remove a comment
      #  * \param fsound A FishSound* handle (created with FISH_SOUND_ENCODE)
      #  * \param comment The comment to remove.
      #  * \retval 1 Success: comment removed
      #  * \retval 0 No-op: comment not found, nothing to remove
      #  * \retval FISH_SOUND_ERR_BAD \a fsound is not a valid FishSound* handle
      #  * \retval FISH_SOUND_ERR_INVALID Operation not suitable for this FishSound
      #  */
      # int
      # fish_sound_comment_remove (FishSound * fsound, FishSoundComment * comment);
      extern('int fish_sound_comment_remove (FishSound * fsound, FishSoundComment * comment)')

      # /**
      #  * Remove all comments with a given name.
      #  * \param fsound A FishSound* handle (created with FISH_SOUND_ENCODE)
      #  * \param name The name of the comments to remove
      #  * \retval ">= 0" The number of comments removed
      #  * \retval FISH_SOUND_ERR_BAD \a fsound is not a valid FishSound* handle
      #  * \retval FISH_SOUND_ERR_INVALID Operation not suitable for this FishSound
      #  */
      # int
      # fish_sound_comment_remove_byname (FishSound * fsound, char * name);
      extern('int fish_sound_comment_remove_byname (FishSound * fsound, char * name)')

      # fishsound/deprecated.h
    end
  end
end
