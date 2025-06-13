
include_guard()

include(ExternalProject)

function(Dependency_HandleDefine define output)
  set(first true)
  foreach(value ${define})
    if(first)
      set(variable ${value})
      set(first false)
    else()
      list(APPEND configure_args "-D${variable}=${value}")
      set(first true)
    endif()
  endforeach()
  set(${output} ${configure_args} PARENT_SCOPE)
endfunction()

function(Dependency_HandleExpected expected output)
  foreach(value ${expected})
    list(APPEND byproducts "<INSTALL_DIR>/${value}")
  endforeach()
  set(${output} ${byproducts} PARENT_SCOPE)
endfunction()

function(Dependency_ProjectName repository output)
  string(REPLACE "/" "_" project_name ${repository})
  set(${output} ${project_name} PARENT_SCOPE)
endfunction()

function(Dependency_Prepare repository tag expected define)
  set(repository 
    "https://github.com/${repository}.git" PARENT_SCOPE)
  set(tag 
    ${tag} PARENT_SCOPE)

  Dependency_ProjectName(
    "${repository}"
    "project_name"
  )
  set(project_name
    ${project_name} PARENT_SCOPE)

  Dependency_HandleDefine(
    "${define}"
    "define_output"
  )
  set(define 
    ${define_output} PARENT_SCOPE)

  Dependency_HandleExpected(
    "${expected}"
    "expected_output"
  )
  set(expected
    ${expected_output} PARENT_SCOPE)
endfunction()

function(
  Dependency_ExternalProject 
  project_name repository tag define expected)
  set(configure
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    ${define}
  )
  ExternalProject_Add(${project_name}

    GIT_REPOSITORY "${repository}"
    GIT_TAG        "${tag}"

    CONFIGURE_COMMAND
    ${CMAKE_COMMAND} 
      -S <SOURCE_DIR> 
      -B <BINARY_DIR> ${configure}

    BUILD_COMMAND
    ${CMAKE_COMMAND} 
      --build <BINARY_DIR>

    INSTALL_COMMAND 
    ${CMAKE_COMMAND} 
      --install <BINARY_DIR> 
      --prefix  <INSTALL_DIR>

    BUILD_BYPRODUCTS ${expected}
  )
endfunction()

function(Dependency_Library target_name project_name expected)
  add_library(
    ${target_name}
    INTERFACE IMPORTED
  )
  ExternalProject_Get_Property(
    ${project_name} 
    INSTALL_DIR
  )
  file(MAKE_DIRECTORY ${INSTALL_DIR}/include)
  target_include_directories(
    ${target_name}
    INTERFACE
    ${INSTALL_DIR}/include
  )
  foreach(value ${expected})
    string(REPLACE "<INSTALL_DIR>" "${INSTALL_DIR}" path ${value})
    target_link_libraries(
      ${target_name}
      INTERFACE
      ${path}
    )
  endforeach()
  add_dependencies(${target_name} ${project_name})
endfunction()

function(
  Dependency_Run
  project_name repository tag define expected target_name)

  Dependency_ExternalProject(
    "${project_name}"
    "${repository}"
    "${tag}"
    "${define}"
    "${expected}"
  )
  Dependency_Library(
    "${target_name}"
    "${project_name}"
    "${expected}"
  )
endfunction()

function(Dependency target_name) 
  cmake_parse_arguments(
    ""
    ""
    "REPOSITORY;TAG"
    "EXPECTED;DEFINE"
    ${ARGV}
  )
  Dependency_Prepare(
    "${_REPOSITORY}"
    "${_TAG}"
    "${_EXPECTED}"
    "${_DEFINE}"
  )
  Dependency_Run(
    "${project_name}"
    "${repository}"
    "${tag}"
    "${define}"
    "${expected}"
    "${target_name}"
  )
endfunction()
