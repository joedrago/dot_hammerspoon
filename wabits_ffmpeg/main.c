#include <arpa/inet.h>
#include <assert.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>

// Most of the wabits*() functions and constants are repurposed from my libavif
// y4m.c implementation. Anything bugfixes in there are still under the same
// license as libavif, so I'll drop this clause here just to keep it honest:
//
// Copyright 2019 Joe Drago. All rights reserved.
// SPDX-License-Identifier: BSD-2-Clause
//
// If anything I'm borrowing BSD code from myself, heh.

// #!/bin/bash
//
// PIPELINE="-y -f avfoundation -i $1 -vf crop=60:60:2209:9"
//
// if [ -z "$1" ]; then
//     ffmpeg -f avfoundation -list_devices true -i ""
//     exit
// fi
//
// if [ ! -z "$2" ]; then
//     echo "Creating test capture PNG: $2"
//     ffmpeg ${PIPELINE} -vframes 1 "$2"
//     exit
// fi
//
// ffmpeg ${PIPELINE} -f yuv4mpegpipe -r 5 - | /Users/joe/work/wabits/build/wabits

typedef int wabitsBool;
#define WABITS_TRUE 1
#define WABITS_FALSE 0

#define WABITS_MIN(a, b) (((a) < (b)) ? (a) : (b))
#define WABITS_DATA_EMPTY { NULL, 0 }

typedef enum wabitsChannelIndex
{
    WABITS_CHAN_Y = 0,
    WABITS_CHAN_U = 1,
    WABITS_CHAN_V = 2,
    WABITS_CHAN_A = 3
} wabitsChannelIndex;

typedef struct wabitsRWData
{
    uint8_t * data;
    size_t size;
} wabitsRWData;

typedef enum wabitsPixelFormat
{
    WABITS_PIXEL_FORMAT_NONE = 0,
    WABITS_PIXEL_FORMAT_YUV444,
    WABITS_PIXEL_FORMAT_YUV422,
    WABITS_PIXEL_FORMAT_YUV420,
    WABITS_PIXEL_FORMAT_YUV400,
    WABITS_PIXEL_FORMAT_COUNT
} wabitsPixelFormat;

void wabitsRWDataFree(wabitsRWData * raw)
{
    free(raw->data);
    raw->data = NULL;
    raw->size = 0;
}

void wabitsRWDataRealloc(wabitsRWData * raw, size_t newSize)
{
    if (raw->size != newSize) {
        uint8_t * newData = (uint8_t *)malloc(newSize);
        if (raw->size && newSize) {
            memcpy(newData, raw->data, WABITS_MIN(raw->size, newSize));
        }
        free(raw->data);
        raw->data = newData;
        raw->size = newSize;
    }
}

void wabitsRWDataSet(wabitsRWData * raw, const uint8_t * data, size_t len)
{
    if (len) {
        wabitsRWDataRealloc(raw, len);
        memcpy(raw->data, data, len);
    } else {
        wabitsRWDataFree(raw);
    }
}

#define Y4M_MAX_LINE_SIZE 2048

struct y4mFrameIterator
{
    int width;
    int height;
    int depth;
    wabitsPixelFormat format;
    FILE * inputFile;
    const char * displayFilename;
};

static wabitsBool getHeaderString(uint8_t * p, uint8_t * end, char * out, size_t maxChars)
{
    uint8_t * headerEnd = p;
    while ((*headerEnd != ' ') && (*headerEnd != '\n')) {
        if (headerEnd >= end) {
            return WABITS_FALSE;
        }
        ++headerEnd;
    }
    size_t formatLen = headerEnd - p;
    if (formatLen > maxChars) {
        return WABITS_FALSE;
    }

    strncpy(out, (const char *)p, formatLen);
    out[formatLen] = 0;
    return WABITS_TRUE;
}

// Returns an unsigned integer value parsed from [start:end[.
// Returns -1 in case of failure.
static int y4mReadUnsignedInt(const char * start, const char * end)
{
    const char * p = start;
    int64_t value = 0;
    while (p < end && *p >= '0' && *p <= '9') {
        value = value * 10 + (*(p++) - '0');
        if (value > INT_MAX) {
            return -1;
        }
    }
    return (p == start) ? -1 : (int)value;
}

static wabitsBool y4mColorSpaceParse(const char * formatString, struct y4mFrameIterator * frame)
{
    if (!strcmp(formatString, "C420jpeg")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV420;
        frame->depth = 8;
        // Chroma sample position is center.
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C420mpeg2")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV420;
        frame->depth = 8;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C420paldv")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV420;
        frame->depth = 8;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C444p10")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV444;
        frame->depth = 10;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C422p10")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV422;
        frame->depth = 10;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C420p10")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV420;
        frame->depth = 10;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C444p12")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV444;
        frame->depth = 12;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C422p12")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV422;
        frame->depth = 12;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C420p12")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV420;
        frame->depth = 12;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C444")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV444;
        frame->depth = 8;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C444alpha")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV444;
        frame->depth = 8;
        // frame->hasAlpha = WABITS_TRUE;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C422")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV422;
        frame->depth = 8;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C420")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV420;
        frame->depth = 8;
        // Chroma sample position is center.
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "Cmono")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV400;
        frame->depth = 8;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "Cmono10")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV400;
        frame->depth = 10;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "Cmono12")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV400;
        frame->depth = 12;
        return WABITS_TRUE;
    }
    return WABITS_FALSE;
}

static int y4mReadLine(FILE * inputFile, wabitsRWData * raw, const char * displayFilename)
{
    static const int maxBytes = Y4M_MAX_LINE_SIZE;
    int bytesRead = 0;
    uint8_t * front = raw->data;

    for (;;) {
        if (fread(front, 1, 1, inputFile) != 1) {
            fprintf(stderr, "Failed to read line: %s\n", displayFilename);
            break;
        }

        ++bytesRead;
        if (bytesRead >= maxBytes) {
            break;
        }

        if (*front == '\n') {
            return bytesRead;
        }
        ++front;
    }
    return -1;
}

struct Image
{
    int width;
    int height;
    uint8_t * planes[3];
};

#define ADVANCE(BYTES)    \
    do {                  \
        p += BYTES;       \
        if (p >= end)     \
            goto cleanup; \
    } while (0)

wabitsBool y4mRead(struct Image * image, struct y4mFrameIterator ** iter)
{
    wabitsBool result = WABITS_FALSE;

    struct y4mFrameIterator frame;
    frame.width = -1;
    frame.height = -1;
    // Default to the color space "C420" to match the defaults of aomenc and ffmpeg.
    frame.depth = 8;
    frame.format = WABITS_PIXEL_FORMAT_YUV420;
    frame.inputFile = NULL;

    wabitsRWData raw = WABITS_DATA_EMPTY;
    wabitsRWDataRealloc(&raw, Y4M_MAX_LINE_SIZE);

    if (iter && *iter) {
        // Continue reading FRAMEs from this y4m stream
        frame = **iter;
    } else {
        // Open a fresh y4m and read its header
        frame.inputFile = stdin;
        frame.displayFilename = "(stdin)";

        int headerBytes = y4mReadLine(frame.inputFile, &raw, frame.displayFilename);
        if (headerBytes < 0) {
            fprintf(stderr, "Y4M header too large: %s\n", frame.displayFilename);
            goto cleanup;
        }
        if (headerBytes < 10) {
            fprintf(stderr, "Y4M header too small: %s\n", frame.displayFilename);
            goto cleanup;
        }

        uint8_t * end = raw.data + headerBytes;
        uint8_t * p = raw.data;

        if (memcmp(p, "YUV4MPEG2 ", 10) != 0) {
            fprintf(stderr, "Not a y4m file: %s\n", frame.displayFilename);
            goto cleanup;
        }
        ADVANCE(10); // skip past header

        char tmpBuffer[32];

        while (p != end) {
            switch (*p) {
                case 'W': // width
                    frame.width = y4mReadUnsignedInt((const char *)p + 1, (const char *)end);
                    break;
                case 'H': // height
                    frame.height = y4mReadUnsignedInt((const char *)p + 1, (const char *)end);
                    break;
                case 'C': // color space
                    if (!getHeaderString(p, end, tmpBuffer, 31)) {
                        fprintf(stderr, "Bad y4m header: %s\n", frame.displayFilename);
                        goto cleanup;
                    }
                    printf("colorspace: %s\n", tmpBuffer);
                    if (!y4mColorSpaceParse(tmpBuffer, &frame)) {
                        fprintf(stderr, "Unsupported y4m pixel format: %s\n", frame.displayFilename);
                        goto cleanup;
                    }
                    break;
                case 'F': // framerate
                    if (!getHeaderString(p, end, tmpBuffer, 31)) {
                        fprintf(stderr, "Bad y4m header: %s\n", frame.displayFilename);
                        goto cleanup;
                    }
                    break;
                case 'X':
                    if (!getHeaderString(p, end, tmpBuffer, 31)) {
                        fprintf(stderr, "Bad y4m header: %s\n", frame.displayFilename);
                        goto cleanup;
                    }
                    break;
                default:
                    break;
            }

            // Advance past header section
            while ((*p != '\n') && (*p != ' ')) {
                ADVANCE(1);
            }
            if (*p == '\n') {
                // Done with y4m header
                break;
            }

            ADVANCE(1);
        }

        if (*p != '\n') {
            fprintf(stderr, "Truncated y4m header (no newline): %s\n", frame.displayFilename);
            goto cleanup;
        }
    }

    int frameHeaderBytes = y4mReadLine(frame.inputFile, &raw, frame.displayFilename);
    if (frameHeaderBytes < 0) {
        fprintf(stderr, "Y4M frame header too large: %s\n", frame.displayFilename);
        goto cleanup;
    }
    if (frameHeaderBytes < 6) {
        fprintf(stderr, "Y4M frame header too small: %s\n", frame.displayFilename);
        goto cleanup;
    }
    if (memcmp(raw.data, "FRAME", 5) != 0) {
        fprintf(stderr, "Truncated y4m (no frame): %s\n", frame.displayFilename);
        goto cleanup;
    }

    if ((frame.width < 1) || (frame.height < 1) || ((frame.depth != 8) && (frame.depth != 10) && (frame.depth != 12))) {
        fprintf(stderr, "Failed to parse y4m header (not enough information): %s\n", frame.displayFilename);
        goto cleanup;
    }

    // lazy AF
    assert(frame.width <= 64);
    assert(frame.height <= 64);
    assert(frame.format == WABITS_PIXEL_FORMAT_YUV422);

    image->width = frame.width;
    image->height = frame.height;

    for (int plane = WABITS_CHAN_Y; plane <= WABITS_CHAN_V; ++plane) {
        uint32_t planeHeight = frame.height;
        uint32_t planeWidthBytes = (plane == WABITS_CHAN_Y) ? frame.width : frame.width >> 1;
        uint8_t * row = image->planes[plane];
        for (uint32_t y = 0; y < planeHeight; ++y) {
            uint32_t bytesRead = (uint32_t)fread(row, 1, planeWidthBytes, frame.inputFile);
            if (bytesRead != planeWidthBytes) {
                fprintf(stderr,
                        "Failed to read y4m row (not enough data, wanted %u, got %u): %s\n",
                        planeWidthBytes,
                        bytesRead,
                        frame.displayFilename);
                goto cleanup;
            }
            row += planeWidthBytes;
        }
    }

    result = WABITS_TRUE;
cleanup:
    if (iter) {
        if (*iter) {
            free(*iter);
            *iter = NULL;
        }

        if (result && frame.inputFile) {
            ungetc(fgetc(frame.inputFile), frame.inputFile); // Kick frame.inputFile to force EOF

            if (!feof(frame.inputFile)) {
                // Remember y4m state for next time
                *iter = malloc(sizeof(struct y4mFrameIterator));
                if (*iter == NULL) {
                    fprintf(stderr, "Inter-frame state memory allocation failure\n");
                    result = WABITS_FALSE;
                } else {
                    **iter = frame;
                }
            }
        }
    }

    wabitsRWDataFree(&raw);
    return result;
}

#define SERVERADDRESS "127.0.0.1"

int main(int argc, char * argv[])
{
    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        fprintf(stderr, "Error opening socket");
        return EXIT_FAILURE;
    }

    struct sockaddr_in server;
    memset(&server, 0, sizeof(struct sockaddr_in));
    server.sin_family = AF_INET;
    server.sin_addr.s_addr = inet_addr(SERVERADDRESS);
    server.sin_port = htons(9001);

    struct Image image;
    image.planes[0] = malloc(64 * 64);
    image.planes[1] = malloc(64 * 64);
    image.planes[2] = malloc(64 * 64);

    struct y4mFrameIterator * frameIter = NULL;

    char udpBuffer[32];

    for (;;) {
        if (feof(stdin)) {
            break;
        }
        if (!y4mRead(&image, &frameIter)) {
            fprintf(stderr, "ERROR: Cannot read y4m through standard input");
            break;
        }

        int bits = 0;
        uint8_t * yPlane = image.planes[0];
        for (int bitIndex = 0; bitIndex < 16; ++bitIndex) {
            int bitX = bitIndex % 4;
            int bitY = bitIndex / 4;
            int pixelX = 6 + bitX * (image.width / 4);
            int pixelY = 6 + bitY * (image.height / 4);
            uint8_t pixel = yPlane[pixelX + (pixelY * image.width)];
            // printf("bit[%u]: (%u, %u) (%u, %u): %u\n", bitIndex, bitX, bitY, pixelX, pixelY, pixel);
            if (pixel > 127) {
                bits += (1 << bitIndex);
            }
        }

        printf("Frame bits: %u\r", bits);
        sprintf(udpBuffer, "%u", bits);
        if (sendto(sockfd, udpBuffer, strlen(udpBuffer), 0, (const struct sockaddr *)&server, sizeof(server)) < 0) {
            fprintf(stderr, "Error in sendto()\n");
            return -1;
        }
    }
    return 0;
}
