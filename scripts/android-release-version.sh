#!/bin/sh
# Derives the Android version name and version code a release tag stands for.
#
#   sh scripts/android-release-version.sh v1.2.3                  # tag -> version fields
#   sh scripts/android-release-version.sh --allow-beta v1.0.0-beta.1 # beta or prod tag -> extended fields
#   sh scripts/android-release-version.sh --self-test             # run the rules locally
#
# In standard mode (`vMAJOR.MINOR.PATCH`), it prints two lines, which are also
# valid GITHUB_OUTPUT entries:
#
#   version_name=1.2.3
#   version_code=1020300
#
# In `--allow-beta` mode, it accepts either `vMAJOR.MINOR.PATCH` (prod channel)
# or `vMAJOR.MINOR.PATCH-beta.N` (beta channel targeting dev, with 1 <= N <= 99)
# and prints:
#
#   version_name=1.0.0-beta.1
#   base_version_name=1.0.0
#   version_code=999901
#   release_channel=beta
#   target_env=dev
#
# The tag is the only source of truth for a release, so anything that is not
# vMAJOR.MINOR.PATCH (or vMAJOR.MINOR.PATCH-beta.N with --allow-beta) is
# rejected rather than guessed at:
#
#   - a missing or different prefix, an unsupported suffix (`-rc1`, `+2`), two
#     or four parts, non-numeric parts and leading zeros all fail.
#   - MINOR and PATCH must stay below 100 so that
#     baseCode = MAJOR * 10000 + MINOR * 100 + PATCH preserves semver order.
#   - Stable releases map to `baseCode * 100` (e.g. v1.0.0 -> 1000000) and
#     beta tags (`-beta.N`, 1 <= N <= 99) map to `(baseCode - 1) * 100 + N`
#     (e.g. v1.0.0-beta.1 -> 999901, v1.0.0-beta.2 -> 999902), so every beta
#     and stable release receives a strictly monotonic, non-colliding
#     versionCode.
#   - Google Play caps versionCode at 2100000000, so MAJOR must stay below
#     2100.
#
# Re-tagging the same version reuses the same version code on purpose: Play
# rejects a second upload with a code it already has, so a fix ships as a new
# tag, never as a rebuilt old one.

set -eu

fail() {
    printf 'error: %s\n' "$1" >&2
    exit 1
}

validate_uint_part() {
    tag_ctx=$1
    label=$2
    part=$3
    case $part in
        '') fail "tag '$tag_ctx' has an empty $label; expected vMAJOR.MINOR.PATCH" ;;
        *[!0-9]*) fail "tag '$tag_ctx' has a non-numeric $label '$part'; expected vMAJOR.MINOR.PATCH" ;;
    esac
    if [ ${#part} -gt 1 ] && [ "${part#0}" != "$part" ]; then
        fail "tag '$tag_ctx' has a $label with a leading zero ('$part')"
    fi
}

parse_core_semver() {
    tag_ctx=$1
    core=$2

    case $core in
        v*.*.*) ;;
        *) fail "tag '$tag_ctx' is not vMAJOR.MINOR.PATCH (for example v1.2.3)" ;;
    esac

    rest=${core#v}
    major=${rest%%.*}
    rest=${rest#*.}
    minor=${rest%%.*}
    patch=${rest#*.}

    case $patch in
        *.*) fail "tag '$tag_ctx' has more than three version parts; expected vMAJOR.MINOR.PATCH" ;;
    esac

    validate_uint_part "$tag_ctx" "version part" "$major"
    validate_uint_part "$tag_ctx" "version part" "$minor"
    validate_uint_part "$tag_ctx" "version part" "$patch"

    [ "$minor" -lt 100 ] || fail "tag '$tag_ctx' has MINOR=$minor; keep MINOR below 100 so the version code keeps semver order"
    [ "$patch" -lt 100 ] || fail "tag '$tag_ctx' has PATCH=$patch; keep PATCH below 100 so the version code keeps semver order"
    [ "$major" -le 2100 ] || fail "tag '$tag_ctx' has MAJOR=$major; Google Play caps versionCode at 2100000000"
    if [ "$major" -eq 2100 ]; then
        [ "$minor" -eq 0 ] && [ "$patch" -eq 0 ] || fail "tag '$tag_ctx' has MAJOR=2100 with MINOR=$minor PATCH=$patch; only v2100.0.0 is allowed (versionCode cap 2100000000)"
    fi

    base_version_name="$major.$minor.$patch"
    base_code=$((major * 10000 + minor * 100 + patch))
    [ "$base_code" -ge 1 ] || fail "tag '$tag_ctx' maps to base version 0.0.0, which Android does not accept"
    version_code=$((base_code * 100))
}

derive() {
    tag=${1:-}
    [ -n "$tag" ] || fail "no tag given; expected vMAJOR.MINOR.PATCH (for example v1.2.3)"

    parse_core_semver "$tag" "$tag"

    printf 'version_name=%s\n' "$base_version_name"
    printf 'version_code=%s\n' "$version_code"
}

derive_allow_beta() {
    tag=${1:-}
    [ -n "$tag" ] || fail "no tag given; expected vMAJOR.MINOR.PATCH or vMAJOR.MINOR.PATCH-beta.N"

    case $tag in
        *-beta.*)
            core=${tag%%-beta.*}
            beta_num=${tag#*-beta.}
            case $beta_num in
                ''|*[!0-9]*)
                    fail "tag '$tag' has an invalid beta number '$beta_num'; expected vMAJOR.MINOR.PATCH-beta.N with N in 1..99"
                    ;;
            esac
            if [ ${#beta_num} -gt 1 ] && [ "${beta_num#0}" != "$beta_num" ]; then
                fail "tag '$tag' has a beta number with a leading zero ('$beta_num')"
            fi
            [ "$beta_num" -ge 1 ] && [ "$beta_num" -le 99 ] || fail "tag '$tag' has beta number $beta_num; keep N in 1..99"
            parse_core_semver "$tag" "$core"
            version_code=$(((base_code - 1) * 100 + beta_num))
            version_name="$base_version_name-beta.$beta_num"
            release_channel="beta"
            target_env="dev"
            ;;
        *)
            parse_core_semver "$tag" "$tag"
            version_name="$base_version_name"
            release_channel="prod"
            target_env="prod"
            ;;
    esac

    printf 'version_name=%s\n' "$version_name"
    printf 'base_version_name=%s\n' "$base_version_name"
    printf 'version_code=%s\n' "$version_code"
    printf 'release_channel=%s\n' "$release_channel"
    printf 'target_env=%s\n' "$target_env"
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
    check_beta_ok() {
        expected=$1
        tag=$2
        if actual=$(derive_allow_beta "$tag" 2>&1); then
            if [ "$actual" = "$expected" ]; then
                printf 'ok    --allow-beta %s\n' "$tag"
            else
                printf 'FAIL  --allow-beta %s -> %s (wanted %s)\n' "$tag" "$actual" "$expected"
                failures=$((failures + 1))
            fi
        else
            printf 'FAIL  --allow-beta %s was rejected: %s\n' "$tag" "$actual"
            failures=$((failures + 1))
        fi
    }
    check_beta_rejected() {
        tag=$1
        if actual=$(derive_allow_beta "$tag" 2>&1); then
            printf 'FAIL  --allow-beta %s was accepted -> %s\n' "$tag" "$actual"
            failures=$((failures + 1))
        else
            printf 'ok    --allow-beta %s rejected\n' "$tag"
        fi
    }

    check_ok "version_name=1.0.0
version_code=1000000" v1.0.0
    check_ok "version_name=1.2.3
version_code=1020300" v1.2.3
    check_ok "version_name=0.9.9
version_code=90900" v0.9.9
    check_ok "version_name=2.10.0
version_code=2100000" v2.10.0
    check_ok "version_name=2.4.99
version_code=2049900" v2.4.99

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
    check_rejected "v1.0.0-beta.1"
    check_rejected "v1.2.3+4"
    check_rejected "v01.2.3"
    check_rejected "v1.100.0"
    check_rejected "v1.2.100"
    check_rejected "v2100.0.0"
    check_rejected "vrelease"
    check_rejected ""

    check_beta_ok "version_name=0.0.1-beta.1
base_version_name=0.0.1
version_code=1
release_channel=beta
target_env=dev" v0.0.1-beta.1

    check_beta_ok "version_name=1.0.0-beta.1
base_version_name=1.0.0
version_code=999901
release_channel=beta
target_env=dev" v1.0.0-beta.1

    check_beta_ok "version_name=1.0.0-beta.2
base_version_name=1.0.0
version_code=999902
release_channel=beta
target_env=dev" v1.0.0-beta.2

    check_beta_ok "version_name=1.0.0-beta.99
base_version_name=1.0.0
version_code=999999
release_channel=beta
target_env=dev" v1.0.0-beta.99

    check_beta_ok "version_name=1.2.3-beta.12
base_version_name=1.2.3
version_code=1020212
release_channel=beta
target_env=dev" v1.2.3-beta.12

    check_beta_ok "version_name=1.0.0
base_version_name=1.0.0
version_code=1000000
release_channel=prod
target_env=prod" v1.0.0

    check_beta_ok "version_name=1.0.1-beta.1
base_version_name=1.0.1
version_code=1000001
release_channel=beta
target_env=dev" v1.0.1-beta.1

    # Monotonic order across beta iterations, stable transition, and next patch beta.
    prev_code=0
    for mono_tag in v1.0.0-beta.1 v1.0.0-beta.2 v1.0.0-beta.99 v1.0.0 v1.0.1-beta.1 v1.0.1; do
        cur_code=$(derive_allow_beta "$mono_tag" | sed -n 's/^version_code=//p')
        if [ "$cur_code" -gt "$prev_code" ]; then
            printf 'ok    monotonic %s (%s > %s)\n' "$mono_tag" "$cur_code" "$prev_code"
        else
            printf 'FAIL  %s (%s) is not > %s\n' "$mono_tag" "$cur_code" "$prev_code"
            failures=$((failures + 1))
        fi
        prev_code=$cur_code
    done

    check_beta_rejected "v0.0.0-beta.1"
    check_beta_rejected "v1.0.0-beta.0"
    check_beta_rejected "v1.0.0-beta.01"
    check_beta_rejected "v1.0.0-beta.100"
    check_beta_rejected "v1.0.0-beta.1.2"
    check_beta_rejected "v1.0.0-rc1"
    check_beta_rejected "v0.0.1-test"
    check_beta_rejected "v2100.0.0-beta.1"
    check_beta_rejected ""

    if [ "$failures" -ne 0 ]; then
        printf 'error: %s self-test case(s) failed\n' "$failures" >&2
        exit 1
    fi
    printf 'all self-test cases passed\n'
}

case ${1:-} in
    --self-test) self_test ;;
    --allow-beta)
        shift
        derive_allow_beta "${1:-}"
        ;;
    '') fail "no tag given; expected vMAJOR.MINOR.PATCH (for example v1.2.3)" ;;
    *) derive "$1" ;;
esac
