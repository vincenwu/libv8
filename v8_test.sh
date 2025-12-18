#!/bin/sh
set -e

dir="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "${dir}/v8" ]; then
  echo "v8 not found"
  exit 1
fi

cxx="g++"
cxxflags=""
ldflags=""

if [ -n "${LLVM_VERSION:-}" ]; then
  cxx="clang++-${LLVM_VERSION}"
  cxxflags="${cxxflags} -stdlib=libc++"
  ldflags="${ldflags} -stdlib=libc++"
fi

(
  set -x
  "${cxx}" -I"${dir}/v8" -I"${dir}/v8/include" \
    "${dir}/v8/samples/hello-world.cc" -o hello_world \
    -L"${dir}/v8/out/release/obj/" -lv8_monolith \
    -pthread -std=c++17 -ldl \
    ${cxxflags} ${ldflags}
)

sh -c "./hello_world"
