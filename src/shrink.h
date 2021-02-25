/*
 * shrink.h - compressor definitions
 *
 * Copyright (C) 2019 Emmanuel Marty
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

/*
 * Uses the libdivsufsort library Copyright (c) 2003-2008 Yuta Mori
 *
 * Inspired by cap by Sven-�ke Dahl. https://github.com/svendahl/cap
 * Also inspired by Charles Bloom's compression blog.
 * http://cbloomrants.blogspot.com/ With ideas from LZ4 by Yann Collet.
 * https://github.com/lz4/lz4 With help and support from spke
 * <zxintrospec@gmail.com>
 *
 */

#ifndef _SHRINK_H
#define _SHRINK_H

#include "matchfinder.h"

#ifdef __cplusplus
extern "C" {
#endif

#define NARRIVALS_PER_POSITION_MAX 55
#define NARRIVALS_PER_POSITION_NORMAL 46
#define NARRIVALS_PER_POSITION_SMALL 9

#define NMATCHES_PER_INDEX 64
#define MATCHES_PER_INDEX_SHIFT 6

#define LEAVE_ALONE_MATCH_SIZE 120

#define TOKEN_CODE_LARGE_MATCH   2 /* 10 */
#define TOKEN_SIZE_LARGE_MATCH   2

#define TOKEN_CODE_7BIT_MATCH    6 /* 110 */
#define TOKEN_SIZE_7BIT_MATCH    3

#define TOKEN_CODE_4BIT_MATCH    7 /* 111 */
#define TOKEN_SIZE_4BIT_MATCH    3


/** One finalized match */
typedef struct _apultra_final_match {
  int length;
  int offset;
} apultra_final_match;

/** Forward arrival slot */
typedef struct {
  int cost;

  unsigned int from_pos : 21;
  int from_slot : 7;
  unsigned int follows_literal : 1;

  unsigned int rep_offset : 21;
  unsigned int short_offset : 4;
  unsigned int rep_pos : 21;
  unsigned int match_len : 11;

  int score;
} apultra_arrival;

/** Compression statistics */
typedef struct _apultra_stats {
  int num_literals;
  int num_4bit_matches;
  int num_7bit_matches;
  int num_variable_matches;
  int num_rep_matches;
  int num_eod;

  int safe_dist;

  int min_offset;
  int max_offset;
  long long total_offsets;

  int min_match_len;
  int max_match_len;
  int total_match_lens;

  int min_rle1_len;
  int max_rle1_len;
  int total_rle1_lens;

  int min_rle2_len;
  int max_rle2_len;
  int total_rle2_lens;

  int commands_divisor;
  int match_divisor;
  int rle1_divisor;
  int rle2_divisor;
} apultra_stats;

/** Compression context */
typedef struct _apultra_compressor {
  apultra_matchfinder matchfinder;
  apultra_final_match *best_match;
  apultra_arrival *arrival;
  int *first_offset_for_byte;
  int *next_offset_for_pos;
  int *offset_cache;
  int flags;
  int block_size;
  int max_arrivals;
} apultra_compressor;

/**
 * Get maximum compressed size of input(source) data
 *
 * @param nInputSize input(source) size in bytes
 *
 * @return maximum compressed size
 */
size_t apultra_get_max_compressed_size(size_t nInputSize);

/**
 * Compress memory
 *
 * @param pInputData pointer to input(source) data to compress
 * @param pOutBuffer buffer for compressed data
 * @param nInputSize input(source) size in bytes
 * @param nMaxOutBufferSize maximum capacity of compression buffer
 * @param nFlags compression flags (set to 0)
 * @param nMaxWindowSize maximum window size to use (0 for default)
 * @param nDictionarySize size of dictionary in front of input data (0 for none)
 * @param progress progress function, called after compressing each block, or
 * NULL for none
 * @param pStats pointer to compression stats that are filled if this function
 * is successful, or NULL
 *
 * @return actual compressed size, or -1 for error
 */
size_t apultra_compress(const unsigned char *pInputData,
                        unsigned char *pOutBuffer, size_t nInputSize,
                        size_t nMaxOutBufferSize, const unsigned int nFlags,
                        size_t nMaxWindowSize, size_t nDictionarySize,
                        void (*progress)(long long nOriginalSize,
                                         long long nCompressedSize),
                        apultra_stats *pStats);

#ifdef __cplusplus
}
#endif

#endif /* _SHRINK_H */
