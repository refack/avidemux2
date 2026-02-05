INCLUDE(ad_plugin)
SET(ADM_ad_alaw_SRCS ADM_ad_alaw.cpp)

ADM_ADD_AUDIO_DECODER_PLUGIN(ADM_ad_alaw ${ADM_ad_alaw_SRCS})
