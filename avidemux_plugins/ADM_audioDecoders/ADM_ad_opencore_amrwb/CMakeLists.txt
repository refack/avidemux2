# OpenCORE AMR-WB decoder
INCLUDE(admCheckOpencore)
checkOpencoreAmrwb()

IF(OPENCORE_AMRWB_FOUND)
  INCLUDE(ad_plugin)

  SET(ADM_ad_opencore_amrwb_SRCS ADM_ad_opencore_amrwb.cpp)

  ADM_ADD_AUDIO_DECODER_PLUGIN(ADM_ad_opencore_amrwb ${ADM_ad_opencore_amrwb_SRCS})
  TARGET_LINK_LIBRARIES(ADM_ad_opencore_amrwb PRIVATE  ${OPENCORE_AMRWB_LIBRARY_DIR})

  ADD_TARGET_CFLAGS(ADM_ad_opencore_amrwb "-I${OPENCORE_AMRWB_INCLUDE_DIR}")
ENDIF()
