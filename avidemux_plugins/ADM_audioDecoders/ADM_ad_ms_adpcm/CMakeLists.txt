INCLUDE(ad_plugin)

SET(ADM_ad_ms_adpcm_SRCS ADM_ad_ms_adpcm.cpp)

ADM_ADD_AUDIO_DECODER_PLUGIN(ADM_ad_ms_adpcm ${ADM_ad_ms_adpcm_SRCS})
