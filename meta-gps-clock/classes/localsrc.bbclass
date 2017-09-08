# Use the source local to this repo

LOCALSRC = "${@os.path.realpath(d.expand('${LAYERDIR_gps-clock}/..'))}"

inherit externalsrc

EXTERNALSRC = "${LOCALSRC}/${BPN}"
EXERNTALSRC_SYMLINKS = ""

