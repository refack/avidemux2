INCLUDE(ad_plugin)

SET(ADM_ad_ima_adpcm_SRCS ADM_ad_ima_adpcm.cpp)

ADM_ADD_AUDIO_DECODER_PLUGIN(ADM_ad_ima_adpcm ${ADM_ad_ima_adpcm_SRCS})
