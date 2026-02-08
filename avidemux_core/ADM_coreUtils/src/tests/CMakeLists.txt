
ADD_EXECUTABLE(fourcc_unittest fourcc_unittest.cpp)
TARGET_LINK_LIBRARIES(fourcc_unittest ADM_coreUtils6)
TARGET_INCLUDE_DIRECTORIES(fourcc_unittest PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../include
    ${AVIDEMUX_CORE_SOURCE_DIR}/ADM_core/include
    ${AVIDEMUX_CORE_SOURCE_DIR}/ADM_coreDemuxer/include/unix
    ${CMAKE_BINARY_DIR}/config
)
