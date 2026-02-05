# admCheckOptionalLibs.cmake - Consolidated checks for optional libraries

# #######################################
# Gettext
# #######################################
MACRO(checkGettext)
  IF(NOT GETTEXT_CHECKED)
    OPTION(GETTEXT "" ON)

    MESSAGE(STATUS "Checking for gettext")
    MESSAGE(STATUS "********************")
    ADD_LIBRARY(adm_gettext INTERFACE)
    FIND_PACKAGE(Intl)
    IF(Intl_FOUND)
      SET(HAVE_GETTEXT 1)
      IF(Intl_IS_BUILT_IN)
        MESSAGE(STATUS "libintl is built in")
      ELSE()
        MESSAGE(STATUS "Intl/Gettext version ${Intl_VERSION} found  ( lib = ${Intl_LIBRARIES} incl=${Intl_INCLUDE_DIRS})")
        If(MSVC)
          TARGET_LINK_LIBRARIES(adm_gettext INTERFACE Intl::Intl)
        ELSE()
          TARGET_LINK_LIBRARIES(adm_gettext INTERFACE ${Intl_LIBRARIES})
          TARGET_INCLUDE_DIRECTORIES(adm_gettext INTERFACE ${Intl_INCLUDE_DIRS})
        ENDIF()
      ENDIF()
    ELSE()
      MESSAGE(STATUS "Cannot find gettext/intl,trying harder")
      FIND_HEADER_AND_LIB(raw_INTL libintl.h intl)
      IF(raw_INTL_INCLUDE_DIR)
        MESSAGE(STATUS "Found as include=${raw_INTL_INCLUDE_DIR} , lib = intl (hardcoded)")
        TARGET_LINK_LIBRARIES(adm_gettext INTERFACE intl)
        TARGET_INCLUDE_DIRECTORIES(adm_gettext INTERFACE ${raw_INTL_INCLUDE_DIR})
        TARGET_LINK_DIRECTORIES(adm_gettext INTERFACE ${raw_INTL_LIBRARY_DIR})
      ENDIF()
      APPEND_SUMMARY_LIST("Miscellaneous" "gettext" "${HAVE_GETTEXT}")
    ENDIF()
    SET(GETTEXT_CHECKED 1)
  ENDIF()
ENDMACRO()

# #######################################
# Ftello
# #######################################
MACRO(checkFtello)
	IF(NOT FTELLO_CHECKED)
		OPTION(FTELLO "" ON)

		MESSAGE(STATUS "Checking for ftello ")
		MESSAGE(STATUS "********************")

		IF(FTELLO)
                        ADM_COMPILE(ftello.cpp "" "" "" GOT_FTELLO outputWithoutLibintl)

                        IF(GOT_FTELLO)
                                SET(USE_FTELLO 1)
                                MESSAGE(STATUS "ftello present")
                        ELSE()
                                SET(USE_FTELLO 0)
                                MESSAGE(STATUS "ftello NOT present")
                        ENDIF()
		ELSE()
			MESSAGE("${MSG_DISABLE_OPTION}")
		ENDIF()
		SET(FTELLO_CHECKED 1)
		MESSAGE("")
	ENDIF()
ENDMACRO()

# #######################################
# Sqlite3
# #######################################
# Outputs:
#   SQLITE3_INCLUDEDIR
#   SQLITE3_LINK_LIBRARIES

MACRO(checkSqlite3)
  IF(NOT SQLITE3_CHECKED)

    MESSAGE(STATUS "Checking for Sqlite3")
    MESSAGE(STATUS "********************")
    IF(MSVC)
      FIND_PACKAGE(unofficial-sqlite3 CONFIG REQUIRED)
      ADD_LIBRARY(adm_sqlite3 INTERFACE)
      TARGET_LINK_LIBRARIES(adm_sqlite3 INTERFACE unofficial::sqlite3::sqlite3)
    ELSE()
      FIND_PACKAGE(SQLite3)
      IF(SQLite3_FOUND)
        PRINT_LIBRARY_INFO("Sqlite3" SQLite3_FOUND "${SQLite3_INCLUDE_DIRS}" "${SQLite3_LIBRARIES}")

        SET(SQLITE3_CHECKED 1)
        MESSAGE("")
        ADD_LIBRARY(adm_sqlite3 INTERFACE)
        TARGET_INCLUDE_DIRECTORIES(adm_sqlite3 INTERFACE ${SQLite3_INCLUDE_DIRS})
        TARGET_LINK_LIBRARIES(adm_sqlite3 INTERFACE ${SQLite3_LIBRARIES})
      ELSE()
        MESSAGE(STATUS "SQLite3 not found")
      ENDIF()
    ENDIF()
  ENDIF()
ENDMACRO()

# #######################################
# Misc Libs (SDL, XVideo, Execinfo)
# #######################################
MACRO(checkMiscLibs)
    ########################################
    # gettext
    ########################################
    checkGettext()

    SET(ADM_LOCALE "${CMAKE_INSTALL_PREFIX}/share/locale")

    ########################################
    # SDL
    ########################################
    OPTION(SDL "" ON)

    MESSAGE(STATUS "Checking for SDL>=2 (only for windows)")
    MESSAGE(STATUS "**************************************")

    IF(SDL AND WIN32 AND NOT MSVC)
        FIND_PACKAGE(SDL2)
        PRINT_LIBRARY_INFO("SDL2" SDL2_FOUND "${SDL2_INCLUDE_DIR}" "${SDL2_LIBRARY}")

        MARK_AS_ADVANCED(SDLMAIN_LIBRARY)
        MARK_AS_ADVANCED(SDL2_INCLUDE_DIR)
        MARK_AS_ADVANCED(SDL2_LIBRARY)

        IF(SDL2_FOUND)
            SET(USE_SDL 1)
        ENDIF()
    ELSE()
        MESSAGE("${MSG_DISABLE_OPTION}")
    ENDIF()

    APPEND_SUMMARY_LIST("Miscellaneous" "SDL" "${USE_SDL}")

    MESSAGE("")

    ########################################
    # XVideo
    ########################################
    IF(UNIX AND NOT APPLE)
        OPTION(XVIDEO "" ON)

        IF(XVIDEO)
            MESSAGE(STATUS "Checking for XVideo")
            MESSAGE(STATUS "*******************")

            FIND_HEADER_AND_LIB(XVIDEO X11/extensions/Xvlib.h Xv XvShmPutImage)
            FIND_HEADER_AND_LIB(XEXT X11/extensions/XShm.h Xext XShmAttach)
            PRINT_LIBRARY_INFO("XVideo" XVIDEO_FOUND "${XVIDEO_INCLUDE_DIR}" "${XVIDEO_LIBRARY_DIR}")
            PRINT_LIBRARY_INFO("Xext" XEXT_FOUND "${XEXT_INCLUDE_DIR}" "${XEXT_LIBRARY_DIR}")

            IF(XVIDEO_FOUND AND XEXT_FOUND)
                SET(USE_XV 1)
            ENDIF()

            MESSAGE("")
        ENDIF()

        APPEND_SUMMARY_LIST("Miscellaneous" "XVideo" "${XVIDEO_FOUND}")
    ELSE()
        SET(XVIDEO_CAPABLE FALSE)
    ENDIF()

    ########################################
    # Execinfo
    ########################################
    MESSAGE(STATUS "Checking for execinfo")
    MESSAGE(STATUS "*********************")

    FIND_HEADER_AND_LIB(EXECINFO execinfo.h c backtrace_symbols)
    PRINT_LIBRARY_INFO("execinfo" EXECINFO_FOUND "${EXECINFO_INCLUDE_DIR}" "${EXECINFO_LIBRARY_DIR}")

    IF(EXECINFO_INCLUDE_DIR)
        # Try linking without -lexecinfo
        ADM_COMPILE(execinfo.cpp "" ${EXECINFO_INCLUDE_DIR} "" WITHOUT_LIBEXECINFO outputWithoutLibexecinfo)

        IF(WITHOUT_LIBEXECINFO)
            SET(EXECINFO_LIBRARY_DIR "")
            SET(HAVE_EXECINFO 1)

            MESSAGE(STATUS "execinfo not required")
        ELSE()
            ADM_COMPILE(execinfo.cpp "" ${EXECINFO_INCLUDE_DIR} ${EXECINFO_LIBRARY_DIR} WITH_LIBEXECINFO outputWithLibexecinfo)

            IF(WITH_LIBEXECINFO)
                SET(HAVE_EXECINFO 1)

                MESSAGE(STATUS "execinfo is required")
            ELSE()
                MESSAGE(STATUS "Does not work, without ${outputWithoutLibexecinfo}")
                MESSAGE(STATUS "Does not work, with ${outputWithLibexecinfo}")
            ENDIF()
        ENDIF()
    ENDIF()

    MESSAGE("")
ENDMACRO()
