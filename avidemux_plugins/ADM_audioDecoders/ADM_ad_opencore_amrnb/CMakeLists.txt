# OpenCORE AMR-NB decoder
INCLUDE(admCheckOpencore)
checkOpencoreAmrnb()

IF(OPENCORE_AMRNB_FOUND)
  INCLUDE(ad_plugin)

  SET(ADM_ad_opencore_amrnb_SRCS ADM_ad_opencore_amrnb.cpp)

  ADM_ADD_AUDIO_DECODER_PLUGIN(ADM_ad_opencore_amrnb ${ADM_ad_opencore_amrnb_SRCS})
  TARGET_LINK_LIBRARIES(ADM_ad_opencore_amrnb PRIVATE  ${OPENCORE_AMRNB_LIBRARY_DIR})

  ADD_TARGET_CFLAGS(ADM_ad_opencore_amrnb "-I${OPENCORE_AMRNB_INCLUDE_DIR}")
ENDIF()
