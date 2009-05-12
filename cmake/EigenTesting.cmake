

option(EIGEN_NO_ASSERTION_CHECKING "Disable checking of assertions" OFF)

# similar to set_target_properties but append the property instead of overwriting it
macro(ei_add_target_property target prop value)

  get_target_property(previous ${target} ${prop})
  set_target_properties(${target} PROPERTIES ${prop} "${previous} ${value}")

endmacro(ei_add_target_property)

macro(ei_add_property prop value)
  get_property(previous GLOBAL PROPERTY ${prop})
  set_property(GLOBAL PROPERTY ${prop} "${previous}${value}")
endmacro(ei_add_property)

# Macro to add a test
#
# the unique parameter testname must correspond to a file
# <testname>.cpp which follows this pattern:
#
# #include "main.h"
# void test_<testname>() { ... }
#
# this macro add an executable test_<testname> as well as a ctest test
# named <testname>
#
# On platforms with bash simply run:
#   "ctest -V" or "ctest -V -R <testname>"
# On other platform use ctest as usual
#
macro(ei_add_test testname)

  set(targetname test_${testname})

  set(filename ${testname}.cpp)
  add_executable(${targetname} ${filename})

  if(NOT EIGEN_NO_ASSERTION_CHECKING)

    if(MSVC)
      set_target_properties(${targetname} PROPERTIES COMPILE_FLAGS "/EHsc")
    else(MSVC)
      set_target_properties(${targetname} PROPERTIES COMPILE_FLAGS "-fexceptions")
    endif(MSVC)

    option(EIGEN_DEBUG_ASSERTS "Enable debuging of assertions" OFF)
    if(EIGEN_DEBUG_ASSERTS)
      set_target_properties(${targetname} PROPERTIES COMPILE_DEFINITIONS "-DEIGEN_DEBUG_ASSERTS=1")
    endif(EIGEN_DEBUG_ASSERTS)

  else(NOT EIGEN_NO_ASSERTION_CHECKING)

    set_target_properties(${targetname} PROPERTIES COMPILE_DEFINITIONS "-DEIGEN_NO_ASSERTION_CHECKING=1")

  endif(NOT EIGEN_NO_ASSERTION_CHECKING)

  if(${ARGC} GREATER 1)
    ei_add_target_property(${targetname} COMPILE_FLAGS "${ARGV1}")
  endif(${ARGC} GREATER 1)

  ei_add_target_property(${targetname} COMPILE_FLAGS "-DEIGEN_TEST_FUNC=${testname}")

  if(TEST_LIB)
    target_link_libraries(${targetname} Eigen2)
  endif(TEST_LIB)

  target_link_libraries(${targetname} ${EXTERNAL_LIBS})
  if(${ARGC} GREATER 2)
    string(STRIP "${ARGV2}" ARGV2_stripped)
    string(LENGTH "${ARGV2_stripped}" ARGV2_stripped_length)
    if(${ARGV2_stripped_length} GREATER 0)
      target_link_libraries(${targetname} ${ARGV2})
    endif(${ARGV2_stripped_length} GREATER 0)
  endif(${ARGC} GREATER 2)

  if(WIN32)
    add_test(${testname} "${targetname}")
  else(WIN32)
    add_test(${testname} "${Eigen_SOURCE_DIR}/test/runtest.sh" "${testname}")
  endif(WIN32)

endmacro(ei_add_test)

# print a summary of the different options
macro(ei_testing_print_summary)

  message("************************************************************")
  message("***    Eigen's unit tests configuration summary          ***")
  message("************************************************************")

  get_property(EIGEN_TESTING_SUMMARY GLOBAL PROPERTY EIGEN_TESTING_SUMMARY)
  get_property(EIGEN_TESTED_BACKENDS GLOBAL PROPERTY EIGEN_TESTED_BACKENDS)
  get_property(EIGEN_MISSING_BACKENDS GLOBAL PROPERTY EIGEN_MISSING_BACKENDS)
  message("Enabled backends:      ${EIGEN_TESTED_BACKENDS}")
  message("Disabled backends:     ${EIGEN_MISSING_BACKENDS}")

  if(EIGEN_TEST_SSE2)
    message("SSE2:              ON")
  else(EIGEN_TEST_SSE2)
    message("SSE2:              AUTO")
  endif(EIGEN_TEST_SSE2)

  if(EIGEN_TEST_SSE3)
    message("SSE3:              ON")
  else(EIGEN_TEST_SSE3)
    message("SSE3:              AUTO")
  endif(EIGEN_TEST_SSE3)

  if(EIGEN_TEST_SSSE3)
    message("SSSE3:             ON")
  else(EIGEN_TEST_SSSE3)
    message("SSSE3:             AUTO")
  endif(EIGEN_TEST_SSSE3)

  if(EIGEN_TEST_ALTIVEC)
    message("Altivec:           ON")
  else(EIGEN_TEST_ALTIVEC)
    message("Altivec:           AUTO")
  endif(EIGEN_TEST_ALTIVEC)

  if(EIGEN_TEST_NO_EXPLICIT_VECTORIZATION)
    message("Explicit vec:      OFF")
  else(EIGEN_TEST_NO_EXPLICIT_VECTORIZATION)
    message("Explicit vec:      AUTO")
  endif(EIGEN_TEST_NO_EXPLICIT_VECTORIZATION)

  message("\n${EIGEN_TESTING_SUMMARY}")
  #   message("CXX:               ${CMAKE_CXX_COMPILER}")
  # if(CMAKE_COMPILER_IS_GNUCXX)
  #   execute_process(COMMAND ${CMAKE_CXX_COMPILER} --version COMMAND head -n 1 OUTPUT_VARIABLE EIGEN_CXX_VERSION_STRING OUTPUT_STRIP_TRAILING_WHITESPACE)
  #   message("CXX_VERSION:       ${EIGEN_CXX_VERSION_STRING}")
  # endif(CMAKE_COMPILER_IS_GNUCXX)
  #   message("CXX_FLAGS:         ${CMAKE_CXX_FLAGS}")
  #   message("Sparse lib flags:  ${SPARSE_LIBS}")

  message("************************************************************")

endmacro(ei_testing_print_summary)

macro(ei_init_testing)
  define_property(GLOBAL PROPERTY EIGEN_TESTED_BACKENDS BRIEF_DOCS " " FULL_DOCS " ")
  define_property(GLOBAL PROPERTY EIGEN_MISSING_BACKENDS BRIEF_DOCS " " FULL_DOCS " ")
  define_property(GLOBAL PROPERTY EIGEN_TESTING_SUMMARY BRIEF_DOCS " " FULL_DOCS " ")

  set_property(GLOBAL PROPERTY EIGEN_TESTED_BACKENDS "")
  set_property(GLOBAL PROPERTY EIGEN_MISSING_BACKENDS "")
  set_property(GLOBAL PROPERTY EIGEN_TESTING_SUMMARY "")
endmacro(ei_init_testing)

if(CMAKE_COMPILER_IS_GNUCXX)
  if(CMAKE_SYSTEM_NAME MATCHES Linux)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g2")
    set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} -O2 -g2")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -fno-inline-functions")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -O0 -g2")
  endif(CMAKE_SYSTEM_NAME MATCHES Linux)
  set(EI_OFLAG "-O2")
# MSVC fails with:
# cl : Command line warning D9025 : overriding '/Od' with '/O2'
# cl : Command line error D8016 : '/RTC1' and '/O2' command-line options are incompatible
# elseif(MSVC)
#   set(EI_OFLAG "/O2")
else(CMAKE_COMPILER_IS_GNUCXX)
  set(EI_OFLAG "")
endif(CMAKE_COMPILER_IS_GNUCXX)