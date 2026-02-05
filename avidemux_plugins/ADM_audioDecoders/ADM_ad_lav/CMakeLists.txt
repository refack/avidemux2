INCLUDE(ad_plugin)

SET(ADM_ad_lav_SRCS ADM_ad_lav.cpp)

ADM_ADD_AUDIO_DECODER_PLUGIN(ADM_ad_lav ${ADM_ad_lav_SRCS})
TARGET_LINK_LIBRARIES(ADM_ad_lav PRIVATE ADM_coreUtils6 ADM_libavcodec ADM_libavutil ADM_coreAudio6)
