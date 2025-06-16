@echo off

if [%1]==[] goto usage

echo -----------------------

if not defined VSCMD_ARG_TGT_ARCH (
  echo ERROR: this script must be run from a VS Developer command prompt.
  exit /B 1
)

rem Check that the target arch is x64
if /I "%VSCMD_ARG_TGT_ARCH%" NEQ "x64" (
  echo ERROR: you need the x64 Native Tools prompt, not %VSCMD_ARG_TGT_ARCH%.
  exit /B 1
)

set "LLVM_BASE=%~1"
set "IWYU_BASE=%CD%"

echo LLVM directory: %LLVM_BASE%
echo IWYU directory: %IWYU_BASE%

goto :skipLLVM

echo -----------------------
echo Configure LLVM
echo -----------------------
mkdir %LLVM_BASE%\build
cmake -B %LLVM_BASE%/build -S %LLVM_BASE%/llvm ^
   -DLLVM_ENABLE_PROJECTS=clang ^
   -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
   -DLLVM_INCLUDE_TESTS=OFF ^
   -DLLVM_INCLUDE_EXAMPLES=OFF ^
   -DLLVM_INCLUDE_BENCHMARKS=OFF ^
   -DLLVM_INCLUDE_DOCS=OFF ^
   -G Ninja

echo -----------------------
echo Build LLVM
echo -----------------------

ninja -C %LLVM_BASE%/build clang
ninja -C %LLVM_BASE%/build clangToolingInclusionsStdlib

:skipLLVM

set LLVM_DIR=%LLVM_BASE%/build/lib/cmake/llvm
set CLANG_DIR=%LLVM_BASE%/build/lib/cmake/clang

set "LLVM_FS=%LLVM_BASE:\=/%"
set CLANG_CL_EXE=%LLVM_FS%/build/bin/clang-cl.exe

echo -----------------------
echo Configure IWYU
echo -----------------------
mkdir %IWYU_BASE%\build
cmake -B %IWYU_BASE%/build -S %IWYU_BASE% ^
   -DCMAKE_C_COMPILER=%CLANG_CL_EXE% ^
   -DCMAKE_CXX_COMPILER=%CLANG_CL_EXE% ^
   -DCMAKE_PREFIX_PATH="%LLVM_BASE%/build" ^
   -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
   -G Ninja

echo -----------------------
echo Build IWYU
echo -----------------------
ninja -C %IWYU_BASE%/build

echo -----------------------
echo Copy IWYU
echo -----------------------
rem copy %IWYU_BASE%\build\bin\include-what-you-use.exe %~dp0

echo -----------------------
echo Create IWYU VS Solution
echo -----------------------
mkdir %IWYU_BASE%\vs_projects
cmake -B %IWYU_BASE%/vs_projects -S %IWYU_BASE% ^
   -DCMAKE_C_COMPILER=%CLANG_CL_EXE% ^
   -DCMAKE_CXX_COMPILER=%CLANG_CL_EXE% ^
   -DCMAKE_PREFIX_PATH="%LLVM_BASE%/build" ^
   -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
   -G "Visual Studio 17"

goto :eof

:usage
@echo usage [LLVM_DIR_NAME]

exit /B 1