INCLUDE(ve_plugin)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_BINARY_DIR})

MACRO(DEFINE_VID_ENCODER codec)
  SET(family ffQsv)
  SET(outName ADM_ve_${family}${codec})
  SET(${family}${codec}_SRCS
        ffQsvAV1Plugin.cpp
        ADM_ffQsvAV1.cpp)
  ADD_VIDEO_ENCODER(${outName} ${${family}${codec}_SRCS})
  INSTALL_VIDEO_ENCODER(${outName})
  TARGET_LINK_LIBRARIES(${outName} PRIVATE ADM_libavcodec ADM_libavutil)
ENDMACRO(DEFINE_VID_ENCODER codec)

DEFINE_VID_ENCODER(AV1)
