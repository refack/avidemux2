#pragma once
#include "ADM_coreVideoEncoderFFmpeg.h"
#include "ffQsvAV1.h"

enum FF_QsvAV1Preset
{
  QSV_AV1_PRESET_VERYFAST=1,
  QSV_AV1_PRESET_FASTER=2,
  QSV_AV1_PRESET_FAST=3,
  QSV_AV1_PRESET_MEDIUM=4,
  QSV_AV1_PRESET_SLOW=5,
  QSV_AV1_PRESET_VERYSLOW=6
};

enum FF_QsvAV1Profile
{
  QSV_AV1_PROFILE_MAIN=0,
  QSV_AV1_PROFILE_HIGH=1,
  QSV_AV1_PROFILE_PRO=2
};

enum FF_QsvAV1RateControl
{
  QSV_AV1_RC_CQP=0,
  QSV_AV1_RC_CBR=1,
  QSV_AV1_RC_VBR=2,
  QSV_AV1_RC_ICQ=3,
};

#define QSV_AV1_CONF_DEFAULT \
{ \
  QSV_AV1_PRESET_MEDIUM, /* preset */ \
  QSV_AV1_PROFILE_MAIN, /* profile */ \
  QSV_AV1_RC_ICQ, /* rc_mode */ \
  20,    /* quality (q scale or icq quality) */ \
  5000, /* bitrate */ \
  10000, /* max_bitrate */ \
  100,   /* gopsize */ \
  0, /* lookahead */ \
}

/**
    \class ADM_ffQsvAV1Encoder
    \brief Wrapper for av1_qsv encoder in libavcodec
*/
class ADM_ffQsvAV1Encoder : public ADM_coreVideoEncoderFFmpeg
{
protected:
               uint64_t     frameIncrement;
public:

                           ADM_ffQsvAV1Encoder(ADM_coreVideoFilter *src,bool globalHeader);
virtual                    ~ADM_ffQsvAV1Encoder();
virtual        bool        configureContext(void);
virtual        bool        setup(void);
virtual        bool        encode (ADMBitstream * out);
virtual const  char        *getFourcc(void);
virtual        uint64_t     getEncoderDelay(void);
};
