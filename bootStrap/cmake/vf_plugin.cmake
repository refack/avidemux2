include(admAsNeeded)
include(admPluginLocation)
include(admCheckThreads)

SET(VF_PLUGIN_DIR "${AVIDEMUX_LIB_DIR}/${ADM_PLUGIN_DIR}/videoFilters/")

IF(MSVC)
    FIND_LIBRARY(PTHREAD_LIB_CUSTOM NAMES pthreadVC3 pthreadVC2 pthread pthreads libpthread)
    IF(PTHREAD_LIB_CUSTOM)
        MESSAGE(STATUS "Manually linking pthread: ${PTHREAD_LIB_CUSTOM}")
    ENDIF()
ENDIF()


# # # # # ######### INIT_VIDEO_FILTER_INTERNAL ###################"
MACRO(INIT_VIDEO_FILTER_INTERNAL _lib)
  INCLUDE_DIRECTORIES(.)
  TARGET_COMPILE_DEFINITIONS(${_lib} PRIVATE "ADM_MINIMAL_UI_INTERFACE")
ENDMACRO()


# # # # # ######### INIT_VIDEO_FILTER ###################"
MACRO(INIT_VIDEO_FILTER _lib)
  if(DO_COMMON)
    INIT_VIDEO_FILTER_INTERNAL(${_lib})
  ENDIF()
ENDMACRO()


# # # # # ######### INSTALL_VIDEO_FILTER_INTERNAL ###################"
MACRO(INSTALL_VIDEO_FILTER_INTERNAL _lib _extra)
  INSTALL(TARGETS ${_lib}
                DESTINATION "${VF_PLUGIN_DIR}/${_extra}"
                COMPONENT plugins)
  IF(NOT MSVC)
    SET(EXTRALIB "m")
  ENDIF()
  TARGET_LINK_LIBRARIES(${_lib} PRIVATE ADM_core6 ADM_coreUI6 ADM_coreVideoFilter6 ADM_coreImage6 ADM_coreUtils6 adm_pthread ${EXTRALIB})
  IF(MSVC AND PTHREAD_LIB_CUSTOM)
    TARGET_LINK_LIBRARIES(${_lib} PRIVATE ${PTHREAD_LIB_CUSTOM})
  ENDIF()
ENDMACRO()


# # # # # ######### INSTALL_VIDEO_FILTER ###################"
MACRO(INSTALL_VIDEO_FILTER _lib)
  IF(DO_COMMON)
    INSTALL_VIDEO_FILTER_INTERNAL(${_lib} "")
  ENDIF()
ENDMACRO()


# # # # # ######### ADD_VIDEO_FILTER ###################"
MACRO(ADD_VIDEO_FILTER name)
  IF(DO_COMMON)
    ADM_ADD_SHARED_LIBRARY(${name} ${ARGN})
    IF(NOT MSVC)
      TARGET_LINK_LIBRARIES(${name} PRIVATE m)
    ENDIF()
    ADM_TARGET_NO_EXCEPTION(${name})
  ENDIF()
ENDMACRO()


# # # # # ###### SIMPLE_VIDEO_FILTER
MACRO(SIMPLE_VIDEO_FILTER tgt src )
  ADD_VIDEO_FILTER(${tgt} ${src})
  INIT_VIDEO_FILTER(${tgt})
  INSTALL_VIDEO_FILTER(${tgt} "")
ENDMACRO()
