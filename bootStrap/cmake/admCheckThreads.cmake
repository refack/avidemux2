# - This module determines the thread library of the system.
# The following variables are set
#  PTHREAD_FOUND - system has pthreads
#  PTHREAD_INCLUDE_DIR - the pthreads include directory
#  PTHREAD_LIBRARIES - the libraries needed to use pthreads

MESSAGE(STATUS "Checking Thread support  ")
IF(NOT PTHREAD_CHECKED)
  MESSAGE(STATUS "Environment is ver=${MSVC_VERSION} msvc=${MSVC}")
  MESSAGE(STATUS "Looking for Threads::Threads")

  FIND_PACKAGE(Threads)
  IF(Threads_FOUND)
    MESSAGE(STATUS "Found Threads::Threads")
    SET(PTHREAD_FOUND 1)
    ADD_LIBRARY(adm_pthread INTERFACE)

    IF(TARGET Threads::Threads)
      TARGET_LINK_LIBRARIES(adm_pthread INTERFACE Threads::Threads)
    ELSE()
      IF(CMAKE_THREAD_LIBS_INIT)
        TARGET_LINK_LIBRARIES(adm_pthread INTERFACE ${CMAKE_THREAD_LIBS_INIT})
      ENDIF()
    ENDIF()

    # Handle explicit PTHREAD_INCLUDE_DIR if set (e.g. Haiku)
    IF(PTHREAD_INCLUDE_DIR)
      TARGET_INCLUDE_DIRECTORIES(adm_pthread INTERFACE "${PTHREAD_INCLUDE_DIR}")
    ENDIF()

    SET(PTHREAD_LIBRARIES adm_pthread)

  ELSE()
    MESSAGE(FATAL_ERROR "Threads not found, cannot continue")
  ENDIF()

  SET(PTHREAD_CHECKED 1)
ENDIF()

MACRO(ADM_LINK_THREAD target)
  TARGET_LINK_LIBRARIES(${target} PRIVATE adm_pthread)
ENDMACRO()
