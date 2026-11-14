#!/bin/sh
# Derives the Android version name and version code a release tag stands for.
#
#   sh scripts/android-release-version.sh v1.2.3      # tag -> version fields
#   sh scripts/android-release-version.sh --self-test # run the rules locally
#
# On success it prints two lines, which are also valid GITHUB_OUTPUT entries:
#
#   version_name=1.2.3
#   version_code=10203
#
# The tag is the only source of truth for a release, so anything that is not
# exactly vMAJOR.MINOR.PATCH is rejected rather than guessed at:
#
#   - a missing or different prefix, a suffix (`-rc1`, `+2`), two or four parts,
#     non-numeric parts and leading zeros all fail.
#   - MINOR and PATCH must stay below 100 so that
#     versionCode = MAJOR * 10000 + MINOR * 100 + PATCH sorts the same way the
#     version names do. Two releases therefore never share a version code, and a
#     higher semver is always a higher code.
#   - Google Play caps versionCode at 2100000000, so MAJOR must stay below
#     210000.
#
# Re-tagging the same version reuses the same version code on purpose: Play
# rejects a second upload with a code it already has, so a fix ships as a new
# tag, never as a rebuilt old one.

set -eu

fail() {
    printf 'error: %s\n' "$1" >&2
    exit 1
}

derive() {
    tag=${1:-}
    [ -n "$tag" ] || fail "no tag given; expected vMAJOR.MINOR.PATCH (for example v1.2.3)"

    case $tag in
        v*.*.*) ;;
        *) fail "tag '$tag' is not vMAJOR.MINOR.PATCH (for example v1.2.3)" ;;
    esac

    rest=${tag#v}
    major=${rest%%.*}
    rest=${rest#*.}
    minor=${rest%%.*}
    patch=${rest#*.}

    case $patch in
        *.*) fail "tag '$tag' has more than three version parts; expected vMAJOR.MINOR.PATCH" ;;
    esac

    for part in "$major" "$minor" "$patch"; do
        case $part in
            '') fail "tag '$tag' has an empty version part; expected vMAJOR.MINOR.PATCH" ;;
            *[!0-9]*) fail "tag '$tag' has a non-numeric version part '$part'; expected vMAJOR.MINOR.PATCH" ;;
        esac
        if [ ${#part} -gt 1 ] && [ "${part#0}" != "$part" ]; then
            fail "tag '$tag' has a version part with a leading zero ('$part')"
        fi
    done

    [ "$minor" -lt 100 ] || fail "tag '$tag' has MINOR=$minor; keep MINOR below 100 so the version code keeps semver order"
    [ "$patch" -lt 100 ] || fail "tag '$tag' has PATCH=$patch; keep PATCH below 100 so the version code keeps semver order"
    [ "$major" -lt 210000 ] || fail "tag '$tag' has MAJOR=$major; Google Play caps versionCode at 2100000000"

    version_name="$major.$minor.$patch"
    version_code=$((major * 10000 + minor * 100 + patch))
    [ "$version_code" -ge 1 ] || fail "tag '$tag' maps to versionCode 0, which Android does not accept"

    printf 'version_name=%s\n' "$version_name"
    printf 'version_code=%s\n' "$version_code"
}

self_test() {
    failures=0
    check_ok() {
        expected=$1
        tag=$2
        if actual=$(derive "$tag" 2>&1); then
            if [ "$actual" = "$expected" ]; then
                printf 'ok    %s\n' "$tag"
            else
                printf 'FAIL  %s -> %s (wanted %s)\n' "$tag" "$actual" "$expected"
                failures=$((failures + 1))
            fi
        else
            printf 'FAIL  %s was rejected: %s\n' "$tag" "$actual"
            failures=$((failures + 1))
        fi
    }
    check_rejected() {
        tag=$1
        if actual=$(derive "$tag" 2>&1); then
            printf 'FAIL  %s was accepted -> %s\n' "$tag" "$actual"
            failures=$((failures + 1))
        else
            printf 'ok    %s rejected\n' "$tag"
        fi
    }

    check_ok "version_name=1.0.0
version_code=10000" v1.0.0
    check_ok "version_name=1.2.3
version_code=10203" v1.2.3
    check_ok "version_name=0.9.9
version_code=909" v0.9.9
    check_ok "version_name=2.10.0
version_code=21000" v2.10.0
    check_ok "version_name=2.4.99
version_code=20499" v2.4.99

    # semver order must equal code order around the minor/patch carry
    lower=$(derive v2.4.99 | sed -n 's/^version_code=//p')
    higher=$(derive v2.5.0 | sed -n 's/^version_code=//p')
    if [ "$lower" -lt "$higher" ]; then
        printf 'ok    v2.4.99 < v2.5.0\n'
    else
        printf 'FAIL  v2.4.99 (%s) is not below v2.5.0 (%s)\n' "$lower" "$higher"
        failures=$((failures + 1))
    fi

    check_rejected "1.2.3"
    check_rejected "v1.2"
    check_rejected "v1.2.3.4"
    check_rejected "v1.2.3-rc1"
    check_rejected "v1.2.3+4"
    check_rejected "v01.2.3"
    check_rejected "v1.100.0"
    check_rejected "v1.2.100"
    check_rejected "v210000.0.0"
    check_rejected "vrelease"
    check_rejected ""

    if [ "$failures" -ne 0 ]; then
        printf 'error: %s self-test case(s) failed\n' "$failures" >&2
        exit 1
    fi
    printf 'all self-test cases passed\n'
}

case ${1:-} in
    --self-test) self_test ;;
    '') fail "no tag given; expected vMAJOR.MINOR.PATCH (for example v1.2.3)" ;;
    *) derive "$1" ;;
esac
