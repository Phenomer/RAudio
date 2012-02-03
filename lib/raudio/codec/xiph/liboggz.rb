#-*- coding: utf-8 -*-

require 'dl/import'
require 'raudio/data'
require 'raudio/codec/xiph/libogg'

module RAudio
  class Codec
    module LibOggz
      extend DL::Importer
      begin
        dlload('liboggz.so')
        AVAILABLE = true
      rescue DL::DLError => e
        STDERR.puts e
        AVAILABLE = false
      end 

      RAudio::Data::TypeAlias.each_pair{|k, v| typealias(k, v)}

      # oggz/oggz_constants.h

      # /** \file
      #  * General constants used by liboggz.
      #  */

      # /**
      #  * Flags to oggz_new(), oggz_open(), and oggz_openfd().
      #  * Can be or'ed together in the following combinations:
      #  * - OGGZ_READ | OGGZ_AUTO
      #  * - OGGZ_WRITE | OGGZ_NONSTRICT | OGGZ_PREFIX | OGGZ_SUFFIX
      #  */
      # enum OggzFlags {
      #   /** Read only */
      #   OGGZ_READ         = 0x00,

      #   /** Write only */
      #   OGGZ_WRITE        = 0x01,

      #   /** Disable strict adherence to mapping constraints, eg for
      #    * handling an incomplete stream */
      #   OGGZ_NONSTRICT    = 0x10,

      #   /**
      #    * Scan for known headers while reading, and automatically set
      #    * metrics appropriately. Opening a file for reading with
      #    * \a flags = OGGZ_READ | OGGZ_AUTO will allow seeking on Speex,
      #    * Vorbis, FLAC, Theora, CMML and all Annodex streams in units of
      #    * milliseconds, once all bos pages have been delivered. */
      #   OGGZ_AUTO         = 0x20,

      #   /**
      #    * Write Prefix: Assume that we are only writing the prefix of an
      #    * Ogg stream, ie. disable checking for conformance with end-of-stream
      #    * constraints.
      #    */
      #   OGGZ_PREFIX       = 0x40,

      #   /**
      #    * Write Suffix: Assume that we are only writing the suffix of an
      #    * Ogg stream, ie. disable checking for conformance with
      #    * beginning-of-stream constraints.
      #    */
      #   OGGZ_SUFFIX       = 0x80

      # };

      OggzFlags = {
        'OGGZ_READ'         => 0x00,
        'OGGZ_WRITE'        => 0x01,
        'OGGZ_NONSTRICT'    => 0x10,
        'OGGZ_AUTO'         => 0x20,
        'OGGZ_PREFIX'       => 0x40,
        'OGGZ_SUFFIX'       => 0x80
      }

      # enum OggzStopCtl {
      #   /** Continue calling read callbacks */
      #   OGGZ_CONTINUE     = 0,

      #   /** Stop calling callbacks, but retain buffered packet data */
      #   OGGZ_STOP_OK      = 1,

      #   /** Stop calling callbacks, and purge buffered packet data */
      #   OGGZ_STOP_ERR     = -1
      # };

      OggzStopCtl = {
        'OGGZ_CONTINUE'     => 0,
        'OGGZ_STOP_OK'      => 1,
        'OGGZ_STOP_ERR'     => -1
      }

      # /**
      #  * Flush options for oggz_write_feed; can be or'ed together
      #  */
      # enum OggzFlushOpts {
      #   /** Flush all streams before beginning this packet */
      #   OGGZ_FLUSH_BEFORE = 0x01,

      #   /** Flush after this packet */
      #   OGGZ_FLUSH_AFTER  = 0x02
      # };
      OggzFlushOpts = {
        'OGGZ_FLUSH_BEFORE' => 0x01,
        'OGGZ_FLUSH_AFTER'  => 0x02
      }

      # /**
      #  * Definition of stream content types
      #  */
      # typedef enum OggzStreamContent {
      #   OGGZ_CONTENT_THEORA = 0,
      #   OGGZ_CONTENT_VORBIS,
      #   OGGZ_CONTENT_SPEEX,
      #   OGGZ_CONTENT_PCM,
      #   OGGZ_CONTENT_CMML,
      #   OGGZ_CONTENT_ANX2,
      #   OGGZ_CONTENT_SKELETON,
      #   OGGZ_CONTENT_FLAC0,
      #   OGGZ_CONTENT_FLAC,
      #   OGGZ_CONTENT_ANXDATA,
      #   OGGZ_CONTENT_CELT,
      #   OGGZ_CONTENT_KATE,
      #   OGGZ_CONTENT_DIRAC,
      #   OGGZ_CONTENT_UNKNOWN
      # } OggzStreamContent;

      OggzStreamContent = {
        'OGGZ_CONTENT_THEORA'  =>  0,
        'OGGZ_CONTENT_VORBIS'  =>  1,
        'OGGZ_CONTENT_SPEEX'   =>  2,
        'OGGZ_CONTENT_PCM'     =>  3,
        'OGGZCONTENT_CMML'     =>  4,
        'OGGZCONTENT_ANX2'     =>  5,
        'OGGZCONTENT_SKELETON' =>  6,
        'OGGZCONTENT_FLAC0'    =>  7,
        'OGGZCONTENT_FLAC'     =>  8,
        'OGGZCONTENT_ANXDATA'  =>  9,
        'OGGZCONTENT_CELT'     => 10,
        'OGGZCONTENT_KATE'     => 11,
        'OGGZCONTENT_DIRAC'    => 12,
        'OGGZ_CONTENT_UNKNOWN' => 13
      }

      # /**
      #  * Definitions of error return values
      #  */
      # enum OggzError {
      #   /** No error */
      #   OGGZ_ERR_OK                           = 0,

      #   /** generic error */
      #   OGGZ_ERR_GENERIC                      = -1,

      #   /** oggz is not a valid OGGZ */
      #   OGGZ_ERR_BAD_OGGZ                     = -2,

      #   /** The requested operation is not suitable for this OGGZ */
      #   OGGZ_ERR_INVALID                      = -3,

      #   /** oggz contains no logical bitstreams */
      #   OGGZ_ERR_NO_STREAMS                   = -4,

      #   /** Operation is inappropriate for oggz in current bos state */
      #   OGGZ_ERR_BOS                          = -5,

      #   /** Operation is inappropriate for oggz in current eos state */
      #   OGGZ_ERR_EOS                          = -6,

      #   /** Operation requires a valid metric, but none has been set */
      #   OGGZ_ERR_BAD_METRIC                   = -7,

      #   /** System specific error; check errno for details */
      #   OGGZ_ERR_SYSTEM                       = -10,

      #   /** Functionality disabled at build time */
      #   OGGZ_ERR_DISABLED                     = -11,

      #   /** Seeking operation is not possible for this OGGZ */
      #   OGGZ_ERR_NOSEEK                       = -13,

      #   /** Reading was stopped by an OggzReadCallback returning OGGZ_STOP_OK
      #    * or writing was stopped by an  OggzWriteHungry callback returning
      #    * OGGZ_STOP_OK */
      #   OGGZ_ERR_STOP_OK                      = -14,

      #   /** Reading was stopped by an OggzReadCallback returning OGGZ_STOP_ERR
      #    * or writing was stopped by an OggzWriteHungry callback returning
      #    * OGGZ_STOP_ERR */
      #   OGGZ_ERR_STOP_ERR                     = -15,

      #   /** no data available from IO, try again */
      #   OGGZ_ERR_IO_AGAIN                     = -16,

      #   /** Hole (sequence number gap) detected in input data */
      #   OGGZ_ERR_HOLE_IN_DATA                 = -17,

      #   /** Out of memory */
      #   OGGZ_ERR_OUT_OF_MEMORY                = -18,

      #   /** The requested serialno does not exist in this OGGZ */
      #   OGGZ_ERR_BAD_SERIALNO                 = -20,

      #   /** Packet disallowed due to invalid byte length */
      #   OGGZ_ERR_BAD_BYTES                    = -21,

      #   /** Packet disallowed due to invalid b_o_s (beginning of stream) flag */
      #   OGGZ_ERR_BAD_B_O_S                    = -22,

      #   /** Packet disallowed due to invalid e_o_s (end of stream) flag */
      #   OGGZ_ERR_BAD_E_O_S                    = -23,

      #   /** Packet disallowed due to invalid granulepos */
      #   OGGZ_ERR_BAD_GRANULEPOS               = -24,

      #   /** Packet disallowed due to invalid packetno */
      #   OGGZ_ERR_BAD_PACKETNO                 = -25,

      #   /** Comment violates VorbisComment restrictions */
      #   /* 129 == 0x81 is the frame marker for Theora's comments page ;-) */
      #   OGGZ_ERR_COMMENT_INVALID              = -129,

      #   /** Guard provided by user has non-zero value */
      #   OGGZ_ERR_BAD_GUARD                    = -210,

      #   /** Attempt to call oggz_write() or oggz_write_output() from within
      #    * a hungry() callback */
      #   OGGZ_ERR_RECURSIVE_WRITE              = -266
      # };

      OggzError = {
        'OGGZERR_OK'                       => 0,
        'OGGZERR_GENERIC'                  => -1,
        'OGGZERR_BAD_OGGZ'                 => -2,
        'OGGZERR_INVALID'                  => -3,
        'OGGZERR_NO_STREAMS'               => -4,
        'OGGZERR_BOS'                      => -5,
        'OGGZERR_EOS'                      => -6,
        'OGGZERR_BAD_METRIC'               => -7,
        'OGGZERR_SYSTEM'                   => -10,
        'OGGZERR_DISABLED'                 => -11,
        'OGGZERR_NOSEEK'                   => -13,
        'OGGZERR_STOP_OK'                  => -14,
        'OGGZERR_STOP_ERR'                 => -15,
        'OGGZERR_IO_AGAIN'                 => -16,
        'OGGZERR_HOLE_IN_DATA'             => -17,
        'OGGZERR_OUT_OF_MEMORY'            => -18,
        'OGGZERR_BAD_SERIALNO'             => -20,
        'OGGZERR_BAD_BYTES'                => -21,
        'OGGZERR_BAD_B_O_S'                => -22,
        'OGGZERR_BAD_E_O_S'                => -23,
        'OGGZERR_BAD_GRANULEPOS'           => -24,
        'OGGZERR_BAD_PACKETNO'             => -25,
        'OGGZERR_COMMENT_INVALID'          => -129,
        'OGGZERR_BAD_GUARD'                => -210,
        'OGGZERR_RECURSIVE_WRITE'          => -266
      };

      # oggz/oggz_table.h
      # /** \file
      #  * A lookup table.
      #  *
      #  * OggzTable is provided for convenience to allow the storage of
      #  * serialno-specific data.
      #  */

      # /**
      #  * A table of key-value pairs.
      #  */
      # typedef void OggzTable;

      # /**
      #  * Instantiate a new OggzTable
      #  * \returns A new OggzTable
      #  * \retval NULL Could not allocate memory for table
      #  */
      # OggzTable *
      # oggz_table_new (void);
      extern('OggzTable * oggz_table_new (void)')

      # /**
      #  * Delete an OggzTable
      #  * \param table An OggzTable
      #  */
      # void
      # oggz_table_delete (OggzTable * table);
      extern('void oggz_table_delete (OggzTable * table)')

      # /**
      #  * Insert an element into a table. If a previous value existed for this key,
      #  * it is overwritten with the new data element.
      #  * \param table An OggzTable
      #  * \param key Key to access this data element
      #  * \param data The new element to add
      #  * \retval data If the element was successfully added
      #  * \retval NULL If adding the element failed due to a realloc() error
      #  */
      # void *
      # oggz_table_insert (OggzTable * table, long key, void * data);
      extern('void * oggz_table_insert (OggzTable * table, long, void * data)')

      # /**
      #  * Remove the element of an OggzTable indexed by a given key
      #  * \param table An OggzTable
      #  * \param key a key
      #  * \retval 0 Success
      #  * \retval -1 Not found
      #  */
      # int
      # oggz_table_remove (OggzTable * table, long key);
      extern('int oggz_table_remove (OggzTable * table, long)')

      # /**
      #  * Retrieve the element of an OggzTable indexed by a given key
      #  * \param table An OggzTable
      #  * \param key a key
      #  * \returns The element indexed by \a key
      #  * \retval NULL \a table is undefined, or no element is indexed by \a key
      #  */
      # void *
      # oggz_table_lookup (OggzTable * table, long key);
      extern('void * oggz_table_lookup (OggzTable * table, long)')

      # /**
      #  * Query the number of elements in an OggzTable
      #  * \param table An OggzTable
      #  * \returns the number of elements in \a table
      #  */
      # int
      # oggz_table_size (OggzTable * table);
      extern('int oggz_table_size (OggzTable * table)')

      # /**
      #  * Retrieve the nth element of an OggzTable, and optionally its key
      #  * \param table An OggzTable
      #  * \param n An index into the \a table
      #  * \param key Return pointer for key corresponding to nth data element
      #  *        of \a table. Ignored if NULL.
      #  * \returns The nth data element of \a table
      #  * \retval NULL \a table is undefined, or \a n is out of range
      #  */
      # void *
      # oggz_table_nth (OggzTable * table, int n, long * key);
      extern('void * oggz_table_nth (OggzTable * table, int, long * key)')


      # oggz/oggz.h
      # /**
      #  * An opaque handle to an Ogg file. This is returned by oggz_open() or
      #  * oggz_new(), and is passed to all other oggz_* functions.
      #  */
      # typedef void OGGZ;

      # /**
      #  * Create a new OGGZ object
      #  * \param flags OGGZ_READ or OGGZ_WRITE
      #  * \returns A new OGGZ object
      #  * \retval NULL on system error; check errno for details
      #  */
      # OGGZ * oggz_new (int flags);
      extern('OGGZ * oggz_new (int)')

      # /**
      #  * Open an Ogg file, creating an OGGZ handle for it
      #  * \param filename The file to open
      #  * \param flags OGGZ_READ or OGGZ_WRITE
      #  * \return A new OGGZ handle
      #  * \retval NULL System error; check errno for details
      #  */
      # OGGZ * oggz_open (const char * filename, int flags);
      extern('OGGZ * oggz_open (const char * filename, int)')
      # /**
      #  * Create an OGGZ handle associated with a stdio stream
      #  * \param file An open FILE handle
      #  * \param flags OGGZ_READ or OGGZ_WRITE
      #  * \returns A new OGGZ handle
      #  * \retval NULL System error; check errno for details
      #  */
      # OGGZ * oggz_open_stdio (FILE * file, int flags);
      extern('OGGZ * oggz_open_stdio (FILE * file, int)')

      # /**
      #  * Ensure any associated io streams are flushed.
      #  * \param oggz An OGGZ handle
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_SYSTEM System error; check errno for details
      #  */
      # int oggz_flush (OGGZ * oggz);
      extern('int oggz_flush (OGGZ * oggz)')

      # /**
      #  * Run an OGGZ until completion, or error.
      #  * This is a convenience function which repeatedly calls oggz_read() or
      #  * oggz_write() as appropriate.
      #  * For an OGGZ opened for reading, an OggzReadPacket or OggzReadPage callback
      #  * should have been set before calling this function.
      #  * For an OGGZ opened for writing, either an OggzHungry callback should have
      #  * been set before calling this function, or you can use this function to
      #  * write out all unwritten Ogg pages which are pending.
      #  * \param oggz An OGGZ handle previously opened for either reading or writing
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_SYSTEM System error; check errno for details
      #  * \retval OGGZ_ERR_STOP_OK Operation was stopped by a user callback
      #  * returning OGGZ_STOP_OK
      #  * \retval OGGZ_ERR_STOP_ERR Operation was stopped by a user callback
      #  * returning OGGZ_STOP_ERR
      #  * \retval OGGZ_ERR_RECURSIVE_WRITE Attempt to initiate writing from
      #  * within an OggzHungry callback
      #  */
      # long oggz_run (OGGZ * oggz);
      extern('long oggz_run (OGGZ * oggz)')

      # /**
      #  * Set the blocksize to use internally for oggz_run()
      #  * \param oggz An OGGZ handle previously opened for either reading or writing
      #  * \param blocksize The blocksize to use within oggz_run()
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Invalid blocksize (\a run_blocksize <= 0)
      #  */
      # int oggz_run_set_blocksize (OGGZ * oggz, long blocksize);
      extern('int oggz_run_set_blocksize (OGGZ * oggz, long)')

      # /**
      #  * Close an OGGZ handle
      #  * \param oggz An OGGZ handle
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_SYSTEM System error; check errno for details
      #  */
      # int oggz_close (OGGZ * oggz);
      extern('int oggz_close (OGGZ * oggz)')

      # /**
      #  * Determine if a given logical bitstream is at bos (beginning of stream).
      #  * \param oggz An OGGZ handle
      #  * \param serialno Identify a logical bitstream within \a oggz, or -1 to
      #  * query if all logical bitstreams in \a oggz are at bos
      #  * \retval 1 The given stream is at bos
      #  * \retval 0 The given stream is not at bos
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  * logical bitstream in \a oggz.
      #  */
      # int oggz_get_bos (OGGZ * oggz, long serialno);
      extern('int oggz_get_bos (OGGZ * oggz, long)')

      # /**
      #  * Determine if a given logical bitstream is at eos (end of stream).
      #  * \param oggz An OGGZ handle
      #  * \param serialno Identify a logical bitstream within \a oggz, or -1 to
      #  * query if all logical bitstreams in \a oggz are at eos
      #  * \retval 1 The given stream is at eos
      #  * \retval 0 The given stream is not at eos
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  * logical bitstream in \a oggz.
      #  */
      # int oggz_get_eos (OGGZ * oggz, long serialno);
      extern('int oggz_get_eos (OGGZ * oggz, long)')

      # /**
      #  * Query the number of tracks (logical bitstreams). When reading, this
      #  * number is incremented every time a new track is found, so the returned
      #  * value is only correct once the OGGZ is no longer at bos (beginning of
      #  * stream): see oggz_get_bos() for determining this.
      #  * \param oggz An OGGZ handle
      #  * \return The number of tracks in OGGZ
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  * logical bitstream in \a oggz.
      #  */
      # int oggz_get_numtracks (OGGZ * oggz);
      extern('int oggz_get_numtracks (OGGZ * oggz)')
      
      # /**
      #  * Request a new serialno, as required for a new stream, ensuring the serialno
      #  * is not yet used for any other streams managed by this OGGZ.
      #  * \param oggz An OGGZ handle
      #  * \returns A new serialno, not already occuring in any logical bitstreams
      #  * in \a oggz.
      #  */
      # long oggz_serialno_new (OGGZ * oggz);
      extern('long oggz_serialno_new (OGGZ * oggz)')

      # /**
      #  * Return human-readable string representation of a content type
      #  *
      #  * \retval string the name of the content type
      #  * \retval NULL \a content invalid
      #  */
      # const char *
      # oggz_content_type (OggzStreamContent content);

        extern('const char * oggz_content_type (OggzStreamContent)')

      # oggz/oggz_off_t.h
      # /**
      #  * This typedef was determined on the system on which the documentation
      #  * was generated.
      #  *
      #  * To query this on your system, do eg.
      #  *
      #  <pre>
      #    echo "gcc -E oggz.h | grep oggz_off_t
      #  </pre>
      #  * 
      #  */
      # 
      # #include <sys/types.h>
      # typedef off_t oggz_off_t;

      PRI_OGGZ_OFF_T = "ll"
      
      # oggz/oggz_packet.h
      # /************************************************************
      #  * OggzPacket
      #  */

      # /**
      #  * The position of an oggz_packet.
      #  */
      # typedef struct {
      #   /**
      #    * Granulepos calculated by inspection of codec data.
      #    * -1 if unknown
      #    */
      #   ogg_int64_t calc_granulepos;

      #   /**
      #    * Byte offset of the start of the page on which this
      #    * packet begins.
      #    */
      #   oggz_off_t begin_page_offset;

      #   /**
      #    * Byte offset of the start of the page on which this
      #    * packet ends.
      #    */
      #   oggz_off_t end_page_offset;

      #   /** Number of pages this packet spans. */
      #   int pages;

      #   /**
      #    * Index into begin_page's lacing values
      #    * for the segment that begins this packet.
      #    * NB. if begin_page is continued then the first
      #    * of these packets will not be reported by
      #    * ogg_sync_packetout() after a seek.
      #    * -1 if unknown.
      #    */
      #   int begin_segment_index;
      # } oggz_position;
      
      Oggz_Position = 
        struct(['ogg_int64_t calc_granulepos',
                'oggz_off_t begin_page_offset',
                'oggz_off_t end_page_offset',
                'int pages',
                'int begin_segment_index'])

      # /**
      #  * An ogg_packet and its position in the stream.
      #  */
      # typedef struct {
      #   /** The ogg_packet structure, defined in <ogg/ogg.h> */
      #   ogg_packet op;

      #   /** Its position */
      #   oggz_position pos;
      # } oggz_packet;

      # Ogg_Packet = 
      #   struct(['unsigned char *packet',
      #           'long  bytes',
      #           'long  b_o_s',
      #           'long  e_o_s',

      #           'ogg_int64_t  granulepos',
      #           'ogg_int64_t  packetno'])
      # Oggz_Position = 
      #   struct(['ogg_int64_t calc_granulepos',
      #           'oggz_off_t begin_page_offset',
      #           'oggz_off_t end_page_offset',
      #           'int pages',
      #           'int begin_segment_index'])

      # Oggz_Packet = 
      #   struct(['ogg_packet op',
      #           'oggz_position pos'])

      Oggz_Packet = 
        struct([ # 'ogg_packet op',
                'unsigned char *packet',
                'long  bytes',
                'long  b_o_s',
                'long  e_o_s',
                'ogg_int64_t  granulepos',
                'ogg_int64_t  packetno',
                # 'oggz_position pos',
                'ogg_int64_t calc_granulepos',
                'oggz_off_t begin_page_offset',
                'oggz_off_t end_page_offset',
                'int pages',
                'int begin_segment_index'])

      # oggz/oggz_read.h
      # /**
      #  * This is the signature of a callback which you must provide for Oggz
      #  * to call whenever it finds a new packet in the Ogg stream associated
      #  * with \a oggz.
      #  *
      #  * \param oggz The OGGZ handle
      #  * \param packet The packet, including its position in the stream.
      #  * \param serialno Identify the logical bistream in \a oggz that contains
      #  *                 \a packet
      #  * \param user_data A generic pointer you have provided earlier
      #  * \returns 0 to continue, non-zero to instruct Oggz to stop.
      #  *
      #  * \note It is possible to provide different callbacks per logical
      #  * bitstream -- see oggz_set_read_callback() for more information.
      #  */
      # typedef int (*OggzReadPacket) (OGGZ * oggz, oggz_packet * packet, long serialno,
      #                                void * user_data);
      OggzReadPacket = 
        bind('int * OggzReadPacket (OGGZ * oggz, oggz_packet * packet, long,
                                       void * user_data)', :temp)

      # /**
      #  * Set a callback for Oggz to call when a new Ogg packet is found in the
      #  * stream.
      #  *
      #  * \param oggz An OGGZ handle previously opened for reading
      #  * \param serialno Identify the logical bitstream in \a oggz to attach
      #  * this callback to, or -1 to attach this callback to all unattached
      #  * logical bitstreams in \a oggz.
      #  * \param read_packet Your callback function
      #  * \param user_data Arbitrary data you wish to pass to your callback
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  * logical bitstream in \a oggz.
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_OUT_OF_MEMORY Out of memory
      #  *
      #  * \note Values of \a serialno other than -1 allows you to specify different
      #  * callback functions for each logical bitstream.
      #  *
      #  * \note It is safe to call this callback from within an OggzReadPacket
      #  * function, in order to specify that subsequent packets should be handled
      #  * by a different OggzReadPacket function.
      #  */
      # int oggz_set_read_callback (OGGZ * oggz, long serialno,
      # 			    OggzReadPacket read_packet, void * user_data);
      extern('int oggz_set_read_callback (OGGZ * oggz, long, OggzReadPacket, void * user_data)')

      # /**
      #  * This is the signature of a callback which you must provide for Oggz
      #  * to call whenever it finds a new page in the Ogg stream associated
      #  * with \a oggz.
      #  *
      #  * \param oggz The OGGZ handle
      #  * \param op The full ogg_page (see <ogg/ogg.h>)
      #  * \param user_data A generic pointer you have provided earlier
      #  * \returns 0 to continue, non-zero to instruct Oggz to stop.
      #  */
      # typedef int (*OggzReadPage) (OGGZ * oggz, const ogg_page * og,
      #                              long serialno, void * user_data);
      OggzReadPage = 
        bind('int * OggzReadPage (OGGZ * oggz, const ogg_page * og,
                                     long, void * user_data)', :temp)

      # /**
      #  * Set a callback for Oggz to call when a new Ogg page is found in the
      #  * stream.
      #  *
      #  * \param oggz An OGGZ handle previously opened for reading
      #  * \param serialno Identify the logical bitstream in \a oggz to attach
      #  * this callback to, or -1 to attach this callback to all unattached
      #  * logical bitstreams in \a oggz.
      #  * \param read_page Your OggzReadPage callback function
      #  * \param user_data Arbitrary data you wish to pass to your callback
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_OUT_OF_MEMORY Out of memory
      #  *
      #  * \note Values of \a serialno other than -1 allows you to specify different
      #  * callback functions for each logical bitstream.
      #  *
      #  * \note It is safe to call this callback from within an OggzReadPage
      #  * function, in order to specify that subsequent pages should be handled
      #  * by a different OggzReadPage function.
      #  */
      # int oggz_set_read_page (OGGZ * oggz, long serialno,
      # 			OggzReadPage read_page, void * user_data);
      extern('int oggz_set_read_page (OGGZ * oggz, long,
			OggzReadPage, void * user_data)')


      # /**
      #  * Read n bytes into \a oggz, calling any read callbacks on the fly.
      #  * \param oggz An OGGZ handle previously opened for reading
      #  * \param n A count of bytes to ingest
      #  * \retval ">  0" The number of bytes successfully ingested.
      #  * \retval 0 End of file
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_SYSTEM System error; check errno for details
      #  * \retval OGGZ_ERR_STOP_OK Reading was stopped by a user callback
      #  * returning OGGZ_STOP_OK
      #  * \retval OGGZ_ERR_STOP_ERR Reading was stopped by a user callback
      #  * returning OGGZ_STOP_ERR
      #  * \retval OGGZ_ERR_HOLE_IN_DATA Hole (sequence number gap) detected in input data
      #  * \retval OGGZ_ERR_OUT_OF_MEMORY Out of memory
      #  */
      # long oggz_read (OGGZ * oggz, long n);
      extern('long oggz_read (OGGZ * oggz, long)')

      # /**
      #  * Input data into \a oggz.
      #  * \param oggz An OGGZ handle previously opened for reading
      #  * \param buf A memory buffer
      #  * \param n A count of bytes to input
      #  * \retval ">  0" The number of bytes successfully ingested.
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_STOP_OK Reading was stopped by a user callback
      #  * returning OGGZ_STOP_OK
      #  * \retval OGGZ_ERR_STOP_ERR Reading was stopped by a user callback
      #  * returning OGGZ_STOP_ERR
      #  * \retval OGGZ_ERR_HOLE_IN_DATA Hole (sequence number gap) detected in input data
      #  * \retval OGGZ_ERR_OUT_OF_MEMORY Out of memory
      #  */
      # long oggz_read_input (OGGZ * oggz, unsigned char * buf, long n);
      extern('long oggz_read_input (OGGZ * oggz, unsigned char * buf, long)')

      # /** \}
      #  */

      # /**
      #  * Erase any input buffered in Oggz. This discards any input read from the
      #  * underlying IO system but not yet delivered as ogg_packets.
      #  *
      #  * \param oggz An OGGZ handle
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_SYSTEM Error seeking on underlying IO.
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  */
      # int oggz_purge (OGGZ * oggz);
      extern('int oggz_purge (OGGZ * oggz)')

      # /**
      #  * Determine the content type of the oggz stream referred to by \a serialno
      #  *
      #  * \param oggz An OGGZ handle
      #  * \param serialno An ogg stream serialno
      #  * \retval OGGZ_CONTENT_THEORA..OGGZ_CONTENT_UNKNOWN content successfully 
      #  *          identified
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not refer to an existing
      #  *          stream
      #  */
      # OggzStreamContent oggz_stream_get_content (OGGZ * oggz, long serialno);
      extern('OggzStreamContent oggz_stream_get_content (OGGZ * oggz, long)')

      # /**
      #  * Return human-readable string representation of content type of oggz stream
      #  * referred to by \a serialno
      #  *
      #  * \param oggz An OGGZ handle
      #  * \param serialno An ogg stream serialno
      #  * \retval string the name of the content type
      #  * \retval NULL \a oggz or \a serialno invalid
      #  */
      # const char * oggz_stream_get_content_type (OGGZ *oggz, long serialno);
      extern('const char * oggz_stream_get_content_type (OGGZ *oggz, long)')

      # /**
      #  * Determine the number of headers of the oggz stream referred to by
      #  * \a serialno
      #  *
      #  * \param oggz An OGGZ handle
      #  * \param serialno An ogg stream serialno
      #  * \retval OGGZ_CONTENT_THEORA..OGGZ_CONTENT_UNKNOWN content successfully 
      #  *          identified
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not refer to an existing
      #  *          stream
      #  */
      # int oggz_stream_get_numheaders (OGGZ * oggz, long serialno);
      extern('int oggz_stream_get_numheaders (OGGZ * oggz, long)')


      # oggz/oggz_stream.h
      # /**
      #  * Determine the content type of the oggz stream referred to by \a serialno
      #  *
      #  * \param oggz An OGGZ handle
      #  * \param serialno An ogg stream serialno
      #  * \retval OGGZ_CONTENT_THEORA..OGGZ_CONTENT_UNKNOWN content successfully 
      #  *          identified
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not refer to an existing
      #  *          stream
      #  */
      # OggzStreamContent oggz_stream_get_content (OGGZ * oggz, long serialno);
      extern('OggzStreamContent oggz_stream_get_content (OGGZ * oggz, long)')

      # /**
      #  * Return human-readable string representation of content type of oggz stream
      #  * referred to by \a serialno
      #  *
      #  * \param oggz An OGGZ handle
      #  * \param serialno An ogg stream serialno
      #  * \retval string the name of the content type
      #  * \retval NULL \a oggz or \a serialno invalid
      #  */
      # const char * oggz_stream_get_content_type (OGGZ *oggz, long serialno);
      extern('const char * oggz_stream_get_content_type (OGGZ *oggz, long)')

      # /**
      #  * Determine the number of headers of the oggz stream referred to by
      #  * \a serialno
      #  *
      #  * \param oggz An OGGZ handle
      #  * \param serialno An ogg stream serialno
      #  * \retval OGGZ_CONTENT_THEORA..OGGZ_CONTENT_UNKNOWN content successfully 
      #  *          identified
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not refer to an existing
      #  *          stream
      #  */
      # int oggz_stream_get_numheaders (OGGZ * oggz, long serialno);
      extern('int oggz_stream_get_numheaders (OGGZ * oggz, long)')


      # oggz/oggz_seek.h
      # /**
      #  * Query the current offset in milliseconds, or custom units as
      #  * specified by a Metric function you have provided.
      #  * \param oggz An OGGZ handle
      #  * \returns the offset in milliseconds, or custom units
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  */
      # ogg_int64_t oggz_tell_units (OGGZ * oggz);
      extern('ogg_int64_t oggz_tell_units (OGGZ * oggz)')

      # /**
      #  * Seek to an offset in milliseconds, or custom units as specified
      #  * by a Metric function you have provided.
      #  * \param oggz An OGGZ handle
      #  * \param units A number of milliseconds, or custom units
      #  * \param whence As defined in <stdio.h>: SEEK_SET, SEEK_CUR or SEEK_END
      #  * \returns the new file offset, or -1 on failure.
      #  */
      # ogg_int64_t oggz_seek_units (OGGZ * oggz, ogg_int64_t units, int whence);
      extern('ogg_int64_t oggz_seek_units (OGGZ * oggz, ogg_int64_t, int)')

      # /**
      #  * Provide the exact stored granulepos (from the page header) if relevant to
      #  * the current packet, or a constructed granulepos if the stored granulepos
      #  * does not belong to this packet, or -1 if this codec does not have support
      #  * for granulepos interpolation
      #  * \param oggz An OGGZ handle
      #  * \returns the granulepos of the \a current packet (if available)
      #  */
      # ogg_int64_t
      # oggz_tell_granulepos (OGGZ * oggz);
      extern('ogg_int64_t oggz_tell_granulepos (OGGZ * oggz)')

      # /**
      #  * Query the file offset in bytes corresponding to the data read.
      #  * \param oggz An OGGZ handle
      #  * \returns The current offset of oggz.
      #  *
      #  * \note When reading, the value returned by oggz_tell() reflects the
      #  * data offset of the start of the most recent packet processed, so that
      #  * when called from an OggzReadPacket callback it reflects the byte
      #  * offset of the start of the packet. As Oggz may have internally read
      #  * ahead, this may differ from the current offset of the associated file
      #  * descriptor.
      #  */
      # oggz_off_t oggz_tell (OGGZ * oggz);
      extern('oggz_off_t oggz_tell (OGGZ * oggz)')

      # /**
      #  * Seek to a specific byte offset
      #  * \param oggz An OGGZ handle
      #  * \param offset a byte offset
      #  * \param whence As defined in <stdio.h>: SEEK_SET, SEEK_CUR or SEEK_END
      #  * \returns the new file offset, or -1 on failure.
      #  */
      # oggz_off_t oggz_seek (OGGZ * oggz, oggz_off_t offset, int whence);
      extern('oggz_off_t oggz_seek (OGGZ * oggz, oggz_off_t, int)')

      # #ifdef _UNIMPLEMENTED
      # long oggz_seek_packets (OGGZ * oggz, long serialno, long packets, int whence);
      # extern('long oggz_seek_packets (OGGZ * oggz, long, long, int)')
      # #endif


      # /**
      #  * Retrieve the preroll of a logical bitstream.
      #  * \param oggz An OGGZ handle
      #  * \param serialno Identify the logical bitstream in \a oggz
      #  * \returns The preroll of the specified logical bitstream.
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  * logical bitstream in \a oggz.
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  */
      # int oggz_get_preroll (OGGZ * oggz, long serialno);
      extern('int oggz_get_preroll (OGGZ * oggz, long)')

      # /**
      #  * Specify the preroll of a logical bitstream.
      #  * \param oggz An OGGZ handle
      #  * \param serialno Identify the logical bitstream in \a oggz to attach
      #  * this preroll to.
      #  * \param preroll The preroll
      #  * \returns 0 Success
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  * logical bitstream in \a oggz.
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  */
      # int oggz_set_preroll (OGGZ * oggz, long serialno, int preroll);
      extern('int oggz_set_preroll (OGGZ * oggz, long, int)')

      # /**
      #  * Retrieve the granuleshift of a logical bitstream.
      #  * \param oggz An OGGZ handle
      #  * \param serialno Identify the logical bitstream in \a oggz
      #  * \returns The granuleshift of the specified logical bitstream.
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  * logical bitstream in \a oggz.
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  */
      # int oggz_get_granuleshift (OGGZ * oggz, long serialno);

      # /**
      #  * Specify the granuleshift of a logical bitstream.
      #  * \param oggz An OGGZ handle
      #  * \param serialno Identify the logical bitstream in \a oggz to attach
      #  * this granuleshift metric to. A value of -1 indicates that the metric should
      #  * be attached to all unattached logical bitstreams in \a oggz.
      #  * \param granuleshift The granuleshift
      #  * \returns 0 Success
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  * logical bitstream in \a oggz.
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  */
      # int oggz_set_granuleshift (OGGZ * oggz, long serialno, int granuleshift);
      extern('int oggz_set_granuleshift (OGGZ * oggz, long, int)')

      # /**
      #  * Retrieve the granulerate of a logical bitstream.
      #  * \param oggz An OGGZ handle
      #  * \param serialno Identify the logical bitstream in \a oggz
      #  * \param granulerate_n Return location for the granulerate numerator
      #  * \param granulerate_d Return location for the granulerate denominator
      #  * \returns 0 Success
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  * logical bitstream in \a oggz.
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  *
      #  */
      # int oggz_get_granulerate (OGGZ * oggz, long serialno,
      # 			  ogg_int64_t * granulerate_n,
      # 			  ogg_int64_t * granulerate_d);
      extern('int oggz_get_granulerate (OGGZ * oggz, long,
			  ogg_int64_t * granulerate_n,
			  ogg_int64_t * granulerate_d)')

      # /**
      #  * Specify the granulerate of a logical bitstream.
      #  * \param oggz An OGGZ handle
      #  * \param serialno Identify the logical bitstream in \a oggz to attach
      #  * this linear metric to. A value of -1 indicates that the metric should
      #  * be attached to all unattached logical bitstreams in \a oggz.
      #  * \param granule_rate_numerator The numerator of the granule rate
      #  * \param granule_rate_denominator The denominator of the granule rate
      #  * \returns 0 Success
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  * logical bitstream in \a oggz.
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  */
      # int oggz_set_granulerate (OGGZ * oggz, long serialno,
      # 			  ogg_int64_t granule_rate_numerator,
      # 			  ogg_int64_t granule_rate_denominator);
      extern('int oggz_set_granulerate (OGGZ * oggz, long,
			  ogg_int64_t, ogg_int64_t)')

      # /**
      #  * This is the signature of a function to correlate Ogg streams.
      #  * If every position in an Ogg stream can be described by a metric (eg. time)
      #  * then define this function that returns some arbitrary unit value.
      #  * This is the normal use of Oggz for media streams. The meaning of units is
      #  * arbitrary, but must be consistent across all logical bitstreams; for
      #  * example a conversion of the time offset of a given packet into nanoseconds
      #  * or a similar stream-specific subdivision may be appropriate.
      #  *
      #  * \param oggz An OGGZ handle
      #  * \param serialno Identifies a logical bitstream within \a oggz
      #  * \param granulepos A granulepos within the logical bitstream identified
      #  *                   by \a serialno
      #  * \param user_data Arbitrary data you wish to pass to your callback
      #  * \returns A conversion of the (serialno, granulepos) pair into a measure
      #  * in units which is consistent across all logical bitstreams within \a oggz
      #  */
      # typedef ogg_int64_t (*OggzMetric) (OGGZ * oggz, long serialno,
      # 				   ogg_int64_t granulepos, void * user_data);

      # /**
      #  * Set the OggzMetric to use for an OGGZ handle
      #  *
      #  * \param oggz An OGGZ handle
      #  * \param serialno Identify the logical bitstream in \a oggz to attach
      #  *                 this metric to. A value of -1 indicates that this metric
      #  *                 should be attached to all unattached logical bitstreams
      #  *                 in \a oggz.
      #  * \param metric An OggzMetric callback
      #  * \param user_data arbitrary data to pass to the metric callback
      #  *
      #  * \returns 0 Success
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  *                               logical bitstream in \a oggz, and is not -1
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  *
      #  * \note Specifying values of \a serialno other than -1 allows you to pass
      #  *       logical bitstream specific user_data to the same metric.
      #  * \note Alternatively, you may use a different \a metric for each
      #  *       \a serialno, but all metrics used must return mutually consistent
      #  *       unit measurements.
      #  */
      # int oggz_set_metric (OGGZ * oggz, long serialno, OggzMetric metric,
      # 		     void * user_data);
      extern('int oggz_set_metric (OGGZ * oggz, long, OggzMetric,
		     void * user_data)')


      # #ifdef _UNIMPLEMENTED
      # /** \defgroup order OggzOrder
      #  *
      #  * - A mechanism to aid seeking across non-metric spaces for which a partial
      #  *   order exists (ie. data that is not synchronised by a measure such as time,
      #  *   but is nevertheless somehow seekably structured), is also planned.
      #  *
      #  * \subsection OggzOrder
      #  *
      #  * Suppose there is a partial order < and a corresponding equivalence
      #  * relation = defined on the space of packets in the Ogg stream of 'OGGZ'.
      #  * An OggzOrder simply provides a comparison in terms of '<' and '=' for
      #  * ogg_packets against a target.
      #  *
      #  * To use OggzOrder:
      #  *
      #  * - Implement an OggzOrder callback
      #  * - Set the OggzOrder callback for an OGGZ handle with oggz_set_order()
      #  * - To seek, use oggz_seek_byorder(). Oggz will use a combination bisection
      #  *   search and scan of the Ogg bitstream, using the OggzOrder callback to
      #  *   match against the desired 'target'.
      #  *
      #  * Otherwise, for more general ogg streams for which a partial order can be
      #  * defined, define a function matching this specification.
      #  *
      #  * Parameters:
      #  *
      #  *     OGGZ: the OGGZ object
      #  *     op:  an ogg packet in the stream
      #  *     target: a user defined object
      #  *
      #  * Return values:
      #  *
      #  *    -1 , if 'op' would occur before the position represented by 'target'
      #  *     0 , if the position of 'op' is equivalent to that of 'target'
      #  *     1 , if 'op' would occur after the position represented by 'target'
      #  *     2 , if the relationship between 'op' and 'target' is undefined.
      #  *
      #  * Symbolically:
      #  *
      #  * Suppose there is a partial order < and a corresponding equivalence
      #  * relation = defined on the space of packets in the Ogg stream of 'OGGZ'.
      #  * Let p represent the position of the packet 'op', and t be the position
      #  * represented by 'target'.
      #  *
      #  * Then a function implementing OggzPacketOrder should return as follows:
      #  *
      #  *    -1 , p < t
      #  *     0 , p = t
      #  *     1 , t < p
      #  *     2 , otherwise
      #  *
      #  * Hacker's hint: if there are no circumstances in which you would return
      #  * a value of 2, there is a linear order; it may be possible to define a
      #  * Metric rather than an Order.
      #  *
      #  */
      # typedef int (*OggzOrder) (OGGZ * oggz, ogg_packet * op, void * target,
      # 			 void * user_data);
      OggzOrder = bind('int * OggzOrder(OGGZ * oggz, ogg_packet * op, void * target, void * user_data)', :temp)

      # /**
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  *                               logical bitstream in \a oggz, and is not -1
      #  */
      # int oggz_set_order (OGGZ * oggz, long serialno, OggzOrder order,
      # 		    void * user_data);

      begin
        extern('int oggz_set_order (OGGZ * oggz, long, OggzOrder,
		    void * user_data)')
      rescue => err
        STDERR.puts err
      end
      # long oggz_seek_byorder (OGGZ * oggz, void * target);
      begin
        extern('long oggz_seek_byorder (OGGZ * oggz, void * target)')
      rescue => err
        STDERR.puts err
      end

      # #endif /* _UNIMPLEMENTED */

      # /**
      #  * Tell Oggz to remember the given offset as the start of data.
      #  * This informs the seeking mechanism that when seeking back to unit 0,
      #  * go to the given offset, not to the start of the file, which is usually
      #  * codec headers.
      #  * The usual usage is:
      # <pre>
      #     oggz_set_data_start (oggz, oggz_tell (oggz));
      # </pre>
      #  * \param oggz An OGGZ handle previously opened for reading
      #  * \param offset The offset of the start of data
      #  * \returns 0 on success, -1 on failure.
      #  */
      # int oggz_set_data_start (OGGZ * oggz, oggz_off_t offset);
      extern('int oggz_set_data_start (OGGZ * oggz, oggz_off_t)')

      # /** \}
      #  */

      # /**
      #  * Seeks Oggz to time unit_target, but with the bounds of the offset range
      #  * [offset_begin, offset_end]. This is useful when seeking in network streams
      #  * where only parts of a media are buffered, and retrieving unbuffered
      #  * parts is expensive.
      #  * \param oggz An OGGZ handle previously opened for reading
      #  * \param unit_target The seek target, in milliseconds, or custom units
      #  * \param offset_begin Start of offset range to seek inside, in bytes
      #  * \param offset_end End of offset range to seek inside, in bytes,
      #           pass -1 for end of media
      #  * \returns The new position, in milliseconds or custom units
      #  * \retval -1 on failure (unit_target is not within range)
      #  */
      # ogg_int64_t
      # oggz_bounded_seek_set (OGGZ * oggz,
      #                        ogg_int64_t unit_target,
      #                        ogg_int64_t offset_begin,
      #                        ogg_int64_t offset_end);
      begin
        extern('ogg_int64_t oggz_bounded_seek_set (OGGZ * oggz,
                       ogg_int64_t, ogg_int64_t, ogg_int64_t)')
      rescue => err
        STDERR.puts err
      end



      # oggz/oggz_write.h
      # /**
      #  * This is the signature of a callback which Oggz will call when \a oggz
      #  * is \link hungry hungry \endlink.
      #  *
      #  * \param oggz The OGGZ handle
      #  * \param empty A value of 1 indicates that the packet queue is currently
      #  *        empty. A value of 0 indicates that the packet queue is not empty.
      #  * \param user_data A generic pointer you have provided earlier
      #  * \retval 0 Continue
      #  * \retval non-zero Instruct Oggz to stop.
      #  */
      # typedef int (*OggzWriteHungry) (OGGZ * oggz, int empty, void * user_data);

      # /**
      #  * Set a callback for Oggz to call when \a oggz
      #  * is \link hungry hungry \endlink.
      #  *
      #  * \param oggz An OGGZ handle previously opened for writing
      #  * \param hungry Your callback function
      #  * \param only_when_empty When to call: a value of 0 indicates that
      #  * Oggz should call \a hungry() after each and every packet is written;
      #  * a value of 1 indicates that Oggz should call \a hungry() only when
      #  * its packet queue is empty
      #  * \param user_data Arbitrary data you wish to pass to your callback
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \note Passing a value of 0 for \a only_when_empty allows you to feed
      #  * new packets into \a oggz's packet queue on the fly.
      #  */
      # int oggz_write_set_hungry_callback (OGGZ * oggz,
      # 				    OggzWriteHungry hungry,
      # 				    int only_when_empty,
      # 				    void * user_data);
      extern('int oggz_write_set_hungry_callback (OGGZ * oggz,
				    OggzWriteHungry, int, void * user_data)')

      # /**
      #  * Add a packet to \a oggz's packet queue.
      #  * \param oggz An OGGZ handle previously opened for writing
      #  * \param op An ogg_packet with all fields filled in
      #  * \param serialno Identify the logical bitstream in \a oggz to add the
      #  * packet to
      #  * \param flush Bitmask of OGGZ_FLUSH_BEFORE, OGGZ_FLUSH_AFTER
      #  * \param guard A guard for nocopy, NULL otherwise
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD_GUARD \a guard specified has non-zero initialization
      #  * \retval OGGZ_ERR_BOS Packet would be bos packet of a new logical bitstream,
      #  *         but oggz has already written one or more non-bos packets in
      #  *         other logical bitstreams,
      #  *         and \a oggz is not flagged OGGZ_NONSTRICT
      #  * \retval OGGZ_ERR_EOS The logical bitstream identified by \a serialno is
      #  *         already at eos,
      #  *         and \a oggz is not flagged OGGZ_NONSTRICT
      #  * \retval OGGZ_ERR_BAD_BYTES \a op->bytes is invalid,
      #  *         and \a oggz is not flagged OGGZ_NONSTRICT
      #  * \retval OGGZ_ERR_BAD_B_O_S \a op->b_o_s is invalid,
      #  *         and \a oggz is not flagged OGGZ_NONSTRICT
      #  * \retval OGGZ_ERR_BAD_GRANULEPOS \a op->granulepos is less than that of
      #  *         an earlier packet within this logical bitstream,
      #  *         and \a oggz is not flagged OGGZ_NONSTRICT
      #  * \retval OGGZ_ERR_BAD_PACKETNO \a op->packetno is less than that of an
      #  *         earlier packet within this logical bitstream,
      #  *         and \a oggz is not flagged OGGZ_NONSTRICT
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  *         logical bitstream in \a oggz,
      #  *         and \a oggz is not flagged OGGZ_NONSTRICT
      #  *         or \a serialno is equal to -1, or \a serialno does not fit in
      #  *         32 bits, ie. within the range (-(2^31), (2^31)-1)
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_OUT_OF_MEMORY Unable to allocate memory to queue packet
      #  *
      #  * \note If \a op->b_o_s is initialized to \a -1 before calling
      #  *       oggz_write_feed(), Oggz will fill it in with the appropriate
      #  *       value; ie. 1 for the first packet of a new stream, and 0 otherwise.
      #  */
      # int oggz_write_feed (OGGZ * oggz, ogg_packet * op, long serialno, int flush,
      # 		     int * guard);
      extern('int oggz_write_feed (OGGZ * oggz, ogg_packet * op, long, int, int * guard)')

      # /**
      #  * Output data from an OGGZ handle. Oggz will call your write callback
      #  * as needed.
      #  *
      #  * \param oggz An OGGZ handle previously opened for writing
      #  * \param buf A memory buffer
      #  * \param n A count of bytes to output
      #  * \retval "> 0" The number of bytes successfully output
      #  * \retval 0 End of stream
      #  * \retval OGGZ_ERR_RECURSIVE_WRITE Attempt to initiate writing from
      #  * within an OggzHungry callback
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_STOP_OK Writing was stopped by an OggzHungry callback
      #  * returning OGGZ_STOP_OK
      #  * \retval OGGZ_ERR_STOP_ERR Reading was stopped by an OggzHungry callback
      #  * returning OGGZ_STOP_ERR
      #  */
      # long oggz_write_output (OGGZ * oggz, unsigned char * buf, long n);
      extern('long oggz_write_output (OGGZ * oggz, unsigned char * buf, long)')

      # /**
      #  * Write n bytes from an OGGZ handle. Oggz will call your write callback
      #  * as needed.
      #  *
      #  * \param oggz An OGGZ handle previously opened for writing
      #  * \param n A count of bytes to be written
      #  * \retval "> 0" The number of bytes successfully output
      #  * \retval 0 End of stream
      #  * \retval OGGZ_ERR_RECURSIVE_WRITE Attempt to initiate writing from
      #  * within an OggzHungry callback
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_STOP_OK Writing was stopped by an OggzHungry callback
      #  * returning OGGZ_STOP_OK
      #  * \retval OGGZ_ERR_STOP_ERR Reading was stopped by an OggzHungry callback
      #  * returning OGGZ_STOP_ERR
      #  */
      # long oggz_write (OGGZ * oggz, long n);
      extern('long oggz_write (OGGZ * oggz, long)')

      # /**
      #  * Query the number of bytes in the next page to be written.
      #  *
      #  * \param oggz An OGGZ handle previously opened for writing
      #  * \retval ">= 0" The number of bytes in the next page
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  */
      # long oggz_write_get_next_page_size (OGGZ * oggz);
      extern('long oggz_write_get_next_page_size (OGGZ * oggz)')


      # oggz/oggz_io.h
      # /**
      #  * This is the signature of a function which you provide for Oggz
      #  * to call when it needs to acquire raw input data.
      #  *
      #  * \param user_handle A generic pointer you have provided earlier
      #  * \param n The length in bytes that Oggz wants to read
      #  * \param buf The buffer that you read data into
      #  * \retval ">  0" The number of bytes successfully read into the buffer
      #  * \retval 0 to indicate that there is no more data to read (End of file)
      #  * \retval "<  0" An error condition
      #  */
      # typedef size_t (*OggzIORead) (void * user_handle, void * buf, size_t n);

      # /**
      #  * This is the signature of a function which you provide for Oggz
      #  * to call when it needs to output raw data.
      #  *
      #  * \param user_handle A generic pointer you have provided earlier
      #  * \param n The length in bytes of the data
      #  * \param buf A buffer containing data to write
      #  * \retval ">= 0" The number of bytes successfully written (may be less than
      #  * \a n if a write error has occurred)
      #  * \retval "<  0" An error condition
      #  */
      # typedef size_t (*OggzIOWrite) (void * user_handle, void * buf, size_t n);

      # /**
      #  * This is the signature of a function which you provide for Oggz
      #  * to call when it needs to seek on the raw input or output data.
      #  *
      #  * \param user_handle A generic pointer you have provided earlier
      #  * \param offset The offset in bytes to seek to
      #  * \param whence SEEK_SET, SEEK_CUR or SEEK_END (as for stdio.h)
      #  * \retval ">= 0" The offset seeked to
      #  * \retval "<  0" An error condition
      #  *
      #  * \note If you provide an OggzIOSeek function, you MUST also provide
      #  * an OggzIOTell function, or else all your seeks will fail.
      #  */
      # typedef int (*OggzIOSeek) (void * user_handle, long offset, int whence);

      # /**
      #  * This is the signature of a function which you provide for Oggz
      #  * to call when it needs to determine the current offset of the raw
      #  * input or output data.
      #  *
      #  * \param user_handle A generic pointer you have provided earlier
      #  * \retval ">= 0" The offset
      #  * \retval "<  0" An error condition
      #  */
      # typedef long (*OggzIOTell) (void * user_handle);

      # /**
      #  * This is the signature of a function which you provide for Oggz
      #  * to call when it needs to flush the output data. The behaviour
      #  * of this function is similar to that of fflush() in stdio.
      #  *
      #  * \param user_handle A generic pointer you have provided earlier
      #  * \retval 0 Success
      #  * \retval "<  0" An error condition
      #  */
      # typedef int (*OggzIOFlush) (void * user_handle);


      # /**
      #  * Set a function for Oggz to call when it needs to read input data.
      #  *
      #  * \param oggz An OGGZ handle
      #  * \param read Your reading function
      #  * \param user_handle Any arbitrary data you wish to pass to the function
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ; \a oggz not
      #  * open for reading.
      #  * \retval OGGZ_ERR_OUT_OF_MEMORY Out of memory
      #  */
      # int oggz_io_set_read (OGGZ * oggz, OggzIORead read, void * user_handle);
      extern('int oggz_io_set_read (OGGZ * oggz, OggzIORead, void * user_handle)')

      # /**
      #  * Retrieve the user_handle associated with the function you have provided
      #  * for reading input data.
      #  *
      #  * \param oggz An OGGZ handle
      #  * \returns the associated user_handle
      #  */
      # void * oggz_io_get_read_user_handle (OGGZ * oggz);
      extern('void * oggz_io_get_read_user_handle (OGGZ * oggz)')

      # /**
      #  * Set a function for Oggz to call when it needs to write output data.
      #  *
      #  * \param oggz An OGGZ handle
      #  * \param write Your writing function
      #  * \param user_handle Any arbitrary data you wish to pass to the function
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ; \a oggz not
      #  * open for writing.
      #  * \retval OGGZ_ERR_OUT_OF_MEMORY Out of memory
      #  */
      # int oggz_io_set_write (OGGZ * oggz, OggzIOWrite write, void * user_handle);
      extern('int oggz_io_set_write (OGGZ * oggz, OggzIOWrite, void * user_handle)')

      # /**
      #  * Retrieve the user_handle associated with the function you have provided
      #  * for writing output data.
      #  *
      #  * \param oggz An OGGZ handle
      #  * \returns the associated user_handle
      #  */
      # void * oggz_io_get_write_user_handle (OGGZ * oggz);
      extern('void * oggz_io_get_write_user_handle (OGGZ * oggz)')

      # /**
      #  * Set a function for Oggz to call when it needs to seek on its raw data.
      #  *
      #  * \param oggz An OGGZ handle
      #  * \param seek Your seeking function
      #  * \param user_handle Any arbitrary data you wish to pass to the function
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_OUT_OF_MEMORY Out of memory
      #  *
      #  * \note If you provide an OggzIOSeek function, you MUST also provide
      #  * an OggzIOTell function, or else all your seeks will fail.
      #  */
      # int oggz_io_set_seek (OGGZ * oggz, OggzIOSeek seek, void * user_handle);
      extern('int oggz_io_set_seek (OGGZ * oggz, OggzIOSeek, void * user_handle)')

      # /**
      #  * Retrieve the user_handle associated with the function you have provided
      #  * for seeking on input or output data.
      #  *
      #  * \param oggz An OGGZ handle
      #  * \returns the associated user_handle
      #  */
      # void * oggz_io_get_seek_user_handle (OGGZ * oggz);
      extern('void * oggz_io_get_seek_user_handle (OGGZ * oggz)')

      # /**
      #  * Set a function for Oggz to call when it needs to determine the offset
      #  * within its input data (if OGGZ_READ) or output data (if OGGZ_WRITE).
      #  *
      #  * \param oggz An OGGZ handle
      #  * \param tell Your tell function
      #  * \param user_handle Any arbitrary data you wish to pass to the function
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_OUT_OF_MEMORY Out of memory
      #  */
      # int oggz_io_set_tell (OGGZ * oggz, OggzIOTell tell, void * user_handle);
      extern('int oggz_io_set_tell (OGGZ * oggz, OggzIOTell, void * user_handle)')

      # /**
      #  * Retrieve the user_handle associated with the function you have provided
      #  * for determining the current offset in input or output data.
      #  *
      #  * \param oggz An OGGZ handle
      #  * \returns the associated user_handle
      #  */
      # void * oggz_io_get_tell_user_handle (OGGZ * oggz);
      extern('void * oggz_io_get_tell_user_handle (OGGZ * oggz)')

      # /**
      #  * Set a function for Oggz to call when it needs to flush its output. The
      #  * meaning of this is similar to that of fflush() in stdio.
      #  *
      #  * \param oggz An OGGZ handle
      #  * \param flush Your flushing function
      #  * \param user_handle Any arbitrary data you wish to pass to the function
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD_OGGZ \a oggz does not refer to an existing OGGZ
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ; \a oggz not
      #  * open for writing.
      #  * \retval OGGZ_ERR_OUT_OF_MEMORY Out of memory
      #  */
      # int oggz_io_set_flush (OGGZ * oggz, OggzIOFlush flush, void * user_handle);
      extern('int oggz_io_set_flush (OGGZ * oggz, OggzIOFlush, void * user_handle)')

      # /**
      #  * Retrieve the user_handle associated with the function you have provided
      #  * for flushing output.
      #  *
      #  * \param oggz An OGGZ handle
      #  * \returns the associated user_handle
      #  */
      # void * oggz_io_get_flush_user_handle (OGGZ * oggz);
      extern('void * oggz_io_get_flush_user_handle (OGGZ * oggz)')


      # oggz/oggz_comments.h
      # /**
      #  * A comment.
      #  */
      # typedef struct {
      #   /** The name of the comment, eg. "AUTHOR" */
      #   char * name;

      #   /** The value of the comment, as UTF-8 */
      #   char * value;
      # } OggzComment;

      OggzComment = 
        struct(['char * name',
                'char * value'])
      # /**
      # * Retrieve the vendor string.
      # * \param oggz A OGGZ* handle
      # * \param serialno Identify a logical bitstream within \a oggz
      # * \returns A read-only copy of the vendor string.
      # * \retval NULL No vendor string is associated with \a oggz,
      # *              or \a oggz is NULL, or \a serialno does not identify an
      # *              existing logical bitstream in \a oggz.
      # */
      # const char *
      # oggz_comment_get_vendor (OGGZ * oggz, long serialno);
      extern('const char * oggz_comment_get_vendor (OGGZ * oggz, long)')

      # /**
      #  * Set the vendor string
      #  * \param oggz A OGGZ* handle
      #  * \param serialno Identify a logical bitstream within \a oggz
      #  * \param vendor_string The contents of the vendor string to add
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD \a oggz is not a valid OGGZ* handle
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_OUT_OF_MEMORY Out of memory
      #  * \note The vendor string should identify the library used to produce
      #  * the stream, e.g. libvorbis 1.0 used "Xiph.Org libVorbis I 20020717".
      #  * If copying a bitstream it should be the same as the source.
      #  */
      # int
      # oggz_comment_set_vendor (OGGZ * oggz, long serialno,
      # 			 const char * vendor_string);
      extern('int oggz_comment_set_vendor (OGGZ * oggz, long, const char * vendor_string)')

      # /**
      #  * Retrieve the first comment.
      #  * \param oggz A OGGZ* handle
      #  * \param serialno Identify a logical bitstream within \a oggz
      #  * \returns A read-only copy of the first comment.
      #  * \retval NULL No comments exist for this OGGZ* object, or \a serialno
      #  *              does not identify an existing logical bitstream in \a oggz.
      #  */
      # const OggzComment *
      # oggz_comment_first (OGGZ * oggz, long serialno);
      extern('const OggzComment * oggz_comment_first (OGGZ * oggz, long)')

      # /**
      #  * Retrieve the next comment.
      #  * \param oggz A OGGZ* handle
      #  * \param serialno Identify a logical bitstream within \a oggz
      #  * \param comment The previous comment.
      #  * \returns A read-only copy of the comment immediately following the given
      #  *          comment.
      #  * \retval NULL \a serialno does not identify an existing
      #  *              logical bitstream in \a oggz.
      #  */
      # const OggzComment *
      # oggz_comment_next (OGGZ * oggz, long serialno, const OggzComment * comment);
      extern('const OggzComment * oggz_comment_next (OGGZ * oggz, long, const OggzComment * comment)')

      # /**
      #  * Retrieve the first comment with a given name.
      #  * \param oggz A OGGZ* handle
      #  * \param serialno Identify a logical bitstream within \a oggz
      #  * \param name the name of the comment to retrieve.
      #  * \returns A read-only copy of the first comment matching the given \a name.
      #  * \retval NULL No match was found, or \a serialno does not identify an
      #  *              existing logical bitstream in \a oggz.
      #  * \note If \a name is NULL, the behaviour is the same as for
      #  *       oggz_comment_first()
      #  */
      # const OggzComment *
      # oggz_comment_first_byname (OGGZ * oggz, long serialno, char * name);
      extern('const OggzComment * oggz_comment_first_byname (OGGZ * oggz, long, char * name)')

      # /**
      #  * Retrieve the next comment following and with the same name as a given
      #  * comment.
      #  * \param oggz A OGGZ* handle
      #  * \param serialno Identify a logical bitstream within \a oggz
      #  * \param comment A comment
      #  * \returns A read-only copy of the next comment with the same name as
      #  *          \a comment.
      #  * \retval NULL No further comments with the same name exist for this
      #  *              OGGZ* object, or \a serialno does not identify an existing
      #  *              logical bitstream in \a oggz.
      #  */
      # const OggzComment *
      # oggz_comment_next_byname (OGGZ * oggz, long serialno,
      #                           const OggzComment * comment);
      extern('const OggzComment * oggz_comment_next_byname (OGGZ * oggz, long, const OggzComment * comment)')

      # /**
      #  * Add a comment
      #  * \param oggz A OGGZ* handle (created with mode OGGZ_WRITE)
      #  * \param serialno Identify a logical bitstream within \a oggz
      #  * \param comment The comment to add
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD \a oggz is not a valid OGGZ* handle
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_OUT_OF_MEMORY Out of memory
      #  */
      # int
      # oggz_comment_add (OGGZ * oggz, long serialno, OggzComment * comment);
      extern('int oggz_comment_add (OGGZ * oggz, long, OggzComment * comment)')

      # /**
      #  * Add a comment by name and value.
      #  * \param oggz A OGGZ* handle (created with mode OGGZ_WRITE)
      #  * \param serialno Identify a logical bitstream within \a oggz
      #  * \param name The name of the comment to add
      #  * \param value The contents of the comment to add
      #  * \retval 0 Success
      #  * \retval OGGZ_ERR_BAD \a oggz is not a valid OGGZ* handle
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_OUT_OF_MEMORY Out of memory
      #  */
      # int
      # oggz_comment_add_byname (OGGZ * oggz, long serialno,
      #                          const char * name, const char * value);
      extern('int oggz_comment_add_byname (OGGZ * oggz, long,
                         const char * name, const char * value)')


      # /**
      #  * Remove a comment
      #  * \param oggz A OGGZ* handle (created with OGGZ_WRITE)
      #  * \param serialno Identify a logical bitstream within \a oggz
      #  * \param comment The comment to remove.
      #  * \retval 1 Success: comment removed
      #  * \retval 0 No-op: comment not found, nothing to remove
      #  * \retval OGGZ_ERR_BAD \a oggz is not a valid OGGZ* handle
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  * logical bitstream in \a oggz.
      #  */
      # int
      # oggz_comment_remove (OGGZ * oggz, long serialno, OggzComment * comment);
      extern('int oggz_comment_remove (OGGZ * oggz, long, OggzComment * comment)')

      # /**
      #  * Remove all comments with a given name.
      #  * \param oggz A OGGZ* handle (created with OGGZ_WRITE)
      #  * \param serialno Identify a logical bitstream within \a oggz
      #  * \param name The name of the comments to remove
      #  * \retval ">= 0" The number of comments removed
      #  * \retval OGGZ_ERR_BAD \a oggz is not a valid OGGZ* handle
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for this OGGZ
      #  * \retval OGGZ_ERR_BAD_SERIALNO \a serialno does not identify an existing
      #  * logical bitstream in \a oggz.
      #  */
      # int
      # oggz_comment_remove_byname (OGGZ * oggz, long serialno, char * name);
      extern('int oggz_comment_remove_byname (OGGZ * oggz, long, char * name)')

      # /**
      #  * Output a comment packet for the specified stream
      #  * \param oggz A OGGZ* handle (created with OGGZ_WRITE)
      #  * \param serialno Identify a logical bitstream within \a oggz
      #  * \param FLAC_final_metadata_block Set this to zero unless the packet_type is
      #  * FLAC, and there are no further metadata blocks to follow. See note below
      #  * for details.
      #  * \returns A comment packet for the stream. When no longer needed it
      #  * should be freed with oggz_packet_destroy().
      #  * \retval NULL content type does not support comments, not enough memory
      #  * or comment was too long for FLAC
      #  * \note FLAC streams may contain multiple metadata blocks of different types.
      #  * When encapsulated in Ogg the first of these must be a Vorbis comment packet
      #  * but PADDING, APPLICATION, SEEKTABLE, CUESHEET and PICTURE may follow.
      #  * The last metadata block must have its first bit set to 1. Since liboggz does
      #  * not know whether you will supply more metadata blocks you must tell it if
      #  * this is the last (or only) metadata block by setting
      #  * FLAC_final_metadata_block to 1.
      #  * \n As FLAC metadata blocks are limited in size to 16MB minus 1 byte, this
      #  * function will refuse to produce longer comment packets for FLAC.
      #  * \n See http://flac.sourceforge.net/format.html for more details.
      #  */
      # ogg_packet *
      # oggz_comments_generate(OGGZ * oggz, long serialno,
      #                        int FLAC_final_metadata_block);
      extern('ogg_packet * oggz_comments_generate(OGGZ * oggz, long, int)')
      
      # /*
      #  * Copy comments between two streams.
      #  * \param src A OGGZ* handle
      #  * \param src_serialno Identify a logical bitstream within \a src
      #  * \param dest A OGGZ* handle (created with OGGZ_WRITE)
      #  * \param dest_serialno Identify a logical bitstream within \a dest
      #  * \retval OGGZ_ERR_BAD \a oggz is not a valid OGGZ* handle
      #  * \retval OGGZ_ERR_INVALID Operation not suitable for \a dest
      #  */
      # int
      # oggz_comments_copy (OGGZ * src, long src_serialno,
      #                     OGGZ * dest, long dest_serialno);
      extern('int oggz_comments_copy (OGGZ * src, long, OGGZ * dest, long)')


      # /**
      #  * Free a packet and its payload.
      #  * \param packet A packet previously returned from a function such
      #  * as oggz_comment_generate(). User generated packets should not be passed.
      #  */
      # void oggz_packet_destroy (ogg_packet *packet);
      extern('void oggz_packet_destroy (ogg_packet *packet)')

      # oggz/oggz_deprecated.h
    end
  end
end
