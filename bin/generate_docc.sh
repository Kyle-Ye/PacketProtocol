set -eu

# A `realpath` alternative using the default C implementation.
filepath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

PACKETPROTOCOL_ROOT="$(dirname $(dirname $(filepath $0)))"

swift package \
    --allow-writing-to-directory "$PACKETPROTOCOL_ROOT/docs" \
    generate-documentation \
    --target PacketProtocol \
    --disable-indexing \
    --hosting-base-path packetprotocol \
    --output-path "$PACKETPROTOCOL_ROOT/docs"