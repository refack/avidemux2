# admPluginsPackaging.cmake
# Consolidated packaging logic for Avidemux Plugins

IF(NOT AVIDEMUX_PACKAGER)
  SET(AVIDEMUX_PACKAGER "none" CACHE STRING "")
ELSE()
  SET(AVIDEMUX_PACKAGER "${AVIDEMUX_PACKAGER}" CACHE STRING "")
  MESSAGE(STATUS "Packager=${AVIDEMUX_PACKAGER}, valid choices= {deb,rpm,tgz,none}")
ENDIF()

IF("${AVIDEMUX_PACKAGER}" STREQUAL "rpm")
    ##############################
    # RPM
    ##############################
    SET(PLUGIN_EXT ${PLUGIN_UI})
    IF(${PLUGIN_UI} MATCHES "QT4")
            SET(PLUGIN_EXT ${QT_EXTENSION})
    ENDIF(${PLUGIN_UI} MATCHES "QT4")
    IF(DO_SETTINGS)
            SET(CPACK_COMPONENTS_ALL settings)
            SET(CPACK_RPM_PACKAGE_NAME "avidemux3-settings")
            SET(CPACK_RPM_PACKAGE_DESCRIPTION "Simple video editor, settings ")
            SET(CPACK_RPM_PACKAGE_PROVIDES "avidemux3-settings = ${AVIDEMUX_VERSION}")
    ELSE(DO_SETTINGS)
            SET(CPACK_COMPONENTS_ALL plugins)
            SET(CPACK_RPM_PACKAGE_NAME "avidemux3-plugins-${PLUGIN_EXT}")
            SET(CPACK_RPM_PACKAGE_DESCRIPTION "Simple video editor, plugins (${PLUGIN_EXT} ")
            SET(CPACK_RPM_PACKAGE_PROVIDES "avidemux3-plugins-${PLUGIN_EXT} = ${AVIDEMUX_VERSION}")
    ENDIF(DO_SETTINGS)

    SET(CPACK_RPM_PACKAGE_SUMMARY "${CPACK_RPM_PACKAGE_DESCRIPTION}")

    SET(CPACK_PACKAGE_RELOCATABLE "false")

    include(admCPackRpm)

ELSEIF("${AVIDEMUX_PACKAGER}" STREQUAL "deb")
    SET(CPACK_DEB_COMPONENT_INSTALL ON)

    ##############################
    # DEBIAN
    ##############################
    include(admDebianUtils)
    SET(PLUGIN_EXT ${PLUGIN_UI})
    IF(${PLUGIN_UI} MATCHES "QT4")
            SET(PLUGIN_EXT ${QT_EXTENSION})
    ENDIF(${PLUGIN_UI} MATCHES "QT4")
    IF(${PLUGIN_UI} MATCHES "CLI")
            SET(PLUGIN_EXT "cli")
    ENDIF(${PLUGIN_UI} MATCHES "CLI")
    IF(${PLUGIN_UI} MATCHES "COMMON")
            SET(PLUGIN_EXT "common")
    ENDIF(${PLUGIN_UI} MATCHES "COMMON")
    #
    IF(DO_SETTINGS)
            SET(CPACK_COMPONENTS_ALL settings)
            SET(CPACK_DEBIAN_PACKAGE_NAME "avidemux3-settings")
            SET(CPACK_DEBIAN_PACKAGE_DESCRIPTION "Simple video editor, settings")
    ELSE(DO_SETTINGS)
            SET(CPACK_COMPONENTS_ALL plugins)
            SET(CPACK_DEBIAN_PACKAGE_NAME "avidemux3-plugins-${PLUGIN_EXT}")
            SET(CPACK_DEBIAN_PACKAGE_DESCRIPTION "Simple video editor, plugins (${PLUGIN_EXT})")
    ENDIF(DO_SETTINGS)
    #
    # Build our deps list
    #
    SET(DEPS "avidemux3-core-runtime (>=${AVIDEMUX_VERSION})")
    IF(${PLUGIN_UI} MATCHES "COMMON")
            # Audio decoder
            SETDEBIANDEPS(USE_FAAD libfaad2 DEPS)
            SETDEBIANDEPS(USE_VORBIS "libvorbis0a, libvorbisenc2, libogg0" DEPS)
            SETDEBIANDEPS(USE_LIBOPUS libopus0 DEPS)
            # Audio encoder
            SETDEBIANDEPS(USE_LAME libmp3lame0 DEPS)
            SETDEBIANDEPS(USE_FAAC libfaac0 DEPS)
            # Audio device
            SETDEBIANDEPS(USE_AFTEN libpulse0 DEPS)
            # Demuxer
            # Muxer
            # Video Encode
            SETDEBIANDEPS(USE_XVID libxvidcore4 DEPS)
    ENDIF(${PLUGIN_UI} MATCHES "COMMON")
    #
    #
    #
    IF((${PLUGIN_UI} MATCHES "QT4") OR (${PLUGIN_UI} MATCHES "CLI"))
            #SETDEBIANDEPS(USE_X264 "libx264-dev" DEPS) # libx264 contains the lib revision, pull the -dev package to get the latest one
            #SETDEBIANDEPS(USE_X265 "libx265-dev" DEPS) # libx265 contains the lib revision, pull the -dev package to get the latest one
    ENDIF((${PLUGIN_UI} MATCHES "QT4") OR (${PLUGIN_UI} MATCHES "CLI"))
    #
    # Add optional DEPS here
    SET(CPACK_DEBIAN_PACKAGE_DEPENDS "${DEPS}")
    #
    include(admCPack)

ELSEIF("${AVIDEMUX_PACKAGER}" STREQUAL "tgz")
    ##############################
    # TGZ
    ##############################
    SET(CPACK_SET_DESTDIR "ON")
    SET (CPACK_GENERATOR "TGZ")
    # Some more infos
    #
    SET(CPACK_PACKAGE_NAME "avidemux3-plugins-${PLUGIN_UI}")
    #

    include(CPack)
ELSE()
    MESSAGE(STATUS "No packaging... (package=${AVIDEMUX_PACKAGER})")
ENDIF()
