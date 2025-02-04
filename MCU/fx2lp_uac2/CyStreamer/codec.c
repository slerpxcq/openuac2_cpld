#include "codec.h"

#include <stddef.h>

#ifndef USE_EXTERNAL_CODEC

AUDIO_CodecTypeDef code codec =
{
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
};

#endif // USE_EXTERNAL_CODEC