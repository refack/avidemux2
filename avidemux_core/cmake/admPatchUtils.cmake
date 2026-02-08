macro(patch_file baseDir patchFile)
	execute_process(COMMAND ${PATCH_EXECUTABLE} -p0 -i "${patchFile}"
					WORKING_DIRECTORY "${baseDir}"
                                        RESULT_VARIABLE   res
        )
        if(res)
                MESSAGE(FATAL_ERROR "Patch failed")
        ENDIF()
ENDMACRO()

macro(patch_file_p1 baseDir patchFile)
	execute_process(COMMAND ${PATCH_EXECUTABLE} -p1  -i "${patchFile}"
					WORKING_DIRECTORY "${baseDir}"
                                        RESULT_VARIABLE   res
				)
        if(res)
                MESSAGE(FATAL_ERROR "Patch failed")
        ENDIF()
ENDMACRO()
