# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

# If CMAKE_DISABLE_SOURCE_CHANGES is set to true and the source directory is an
# existing directory in our source tree, calling file(MAKE_DIRECTORY) on it
# would cause a fatal error, even though it would be a no-op.
if(NOT EXISTS "C:/Users/Zero/Desktop/School stuff/Uni/8 Semestras/Bakalauro darbas/KnowledgeSwap/knowledgeswap/build/windows/x64/_deps/nuget-src")
  file(MAKE_DIRECTORY "C:/Users/Zero/Desktop/School stuff/Uni/8 Semestras/Bakalauro darbas/KnowledgeSwap/knowledgeswap/build/windows/x64/_deps/nuget-src")
endif()
file(MAKE_DIRECTORY
  "C:/Users/Zero/Desktop/School stuff/Uni/8 Semestras/Bakalauro darbas/KnowledgeSwap/knowledgeswap/build/windows/x64/_deps/nuget-build"
  "C:/Users/Zero/Desktop/School stuff/Uni/8 Semestras/Bakalauro darbas/KnowledgeSwap/knowledgeswap/build/windows/x64/_deps/nuget-subbuild/nuget-populate-prefix"
  "C:/Users/Zero/Desktop/School stuff/Uni/8 Semestras/Bakalauro darbas/KnowledgeSwap/knowledgeswap/build/windows/x64/_deps/nuget-subbuild/nuget-populate-prefix/tmp"
  "C:/Users/Zero/Desktop/School stuff/Uni/8 Semestras/Bakalauro darbas/KnowledgeSwap/knowledgeswap/build/windows/x64/_deps/nuget-subbuild/nuget-populate-prefix/src/nuget-populate-stamp"
  "C:/Users/Zero/Desktop/School stuff/Uni/8 Semestras/Bakalauro darbas/KnowledgeSwap/knowledgeswap/build/windows/x64/_deps/nuget-subbuild/nuget-populate-prefix/src"
  "C:/Users/Zero/Desktop/School stuff/Uni/8 Semestras/Bakalauro darbas/KnowledgeSwap/knowledgeswap/build/windows/x64/_deps/nuget-subbuild/nuget-populate-prefix/src/nuget-populate-stamp"
)

set(configSubDirs Debug)
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "C:/Users/Zero/Desktop/School stuff/Uni/8 Semestras/Bakalauro darbas/KnowledgeSwap/knowledgeswap/build/windows/x64/_deps/nuget-subbuild/nuget-populate-prefix/src/nuget-populate-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "C:/Users/Zero/Desktop/School stuff/Uni/8 Semestras/Bakalauro darbas/KnowledgeSwap/knowledgeswap/build/windows/x64/_deps/nuget-subbuild/nuget-populate-prefix/src/nuget-populate-stamp${cfgdir}") # cfgdir has leading slash
endif()
