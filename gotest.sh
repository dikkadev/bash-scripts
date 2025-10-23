gotest() {
    local args=("$@")

    set -o pipefail && go test "${args[@]}" -json | tparse -all
}
