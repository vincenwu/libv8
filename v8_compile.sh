#!/bin/sh

set -e

dir="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "${dir}/v8" ]; then
	echo "v8 not found"
	exit 1
fi

PATH="${dir}/depot_tools:$PATH"
export PATH

os="$RUNNER_OS"

if [ -z "$os" ]; then
	case "$(uname -s)" in
		Linux)
			os="Linux"
			;;
		Darwin)
			os="macOS"
			;;
		*)
			echo "Unknown OS type"
			exit 1
	esac
fi

cores="2"

if [ "$os" = "Linux" ]; then
	cores="$(grep -c processor /proc/cpuinfo)"
elif [ "$os" = "macOS" ]; then
	cores="$(sysctl -n hw.logicalcpu)"
fi

cc_wrapper=""
if command -v ccache >/dev/null 2>&1 ; then
  cc_wrapper="ccache"
fi

gn_args="$(grep -v "^#" "${dir}/args/${os}.gn" | grep -v "^$")
cc_wrapper=\"$cc_wrapper\""

if [ -n "${LLVM_VERSION:-}" ]; then
    gn_args="$gn_args clang_base_path=\"/usr/lib/llvm-${LLVM_VERSION}\""
    gn_args="$gn_args custom_toolchain=\"//../toolchain:clang-libc++\""
    gn_args="$gn_args host_toolchain=\"//../toolchain:clang-libc++\""
fi

cd "${dir}/v8"

gn gen "./out/release" --args="$gn_args"

echo "==================== Build args start ===================="
gn args "./out/release" --list | tee "${dir}/gn-args_${os}.txt"
echo "==================== Build args end ===================="

(
	set -x
	ninja -C "./out/release" -j "$cores" -v v8_monolith
)

ls -lh ./out/release/obj/libv8_*.a

cd -
