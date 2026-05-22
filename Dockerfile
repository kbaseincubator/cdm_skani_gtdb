# cdm_skani_gtdb: skani ANI calculator paired with GTDB R232 reference sketches.
#
# Same skani binary as cdm_skani (0.3.1, copied from ecogenomic/gtdbtk:2.7.2).
# Pairing rationale: gtdbtk 2.7.2 built the R232 skani sketch DB using exactly
# this skani version, so reusing the binary guarantees sketch-format
# compatibility with the bundled reference data.
#
# REFDATA EXPECTATION
#
# This image is intended to be registered in CTS with the existing GTDB-Tk
# R232 reference data bundle bound at registration time. That same bundle is
# already used by cdm_gtdbtk:
#
#   cts-refdata/gtdbtk/r232/gtdbtk_r232_data.tar.gz
#   refdata UUID: bb6352b4-b86f-4e3d-a858-4bc77327ab13
#
# CTS will mount it at /ref_data/. The R232 tarball wraps its contents in a
# release232/ directory (CTS does not strip it), and the skani sketch DB lives
# at:
#
#   /ref_data/release232/skani/database/
#
# Demo notebooks should pass `-d /ref_data/release232/skani/database/` to `skani search`.
# We don't bake the path into the image so a future GTDB release (R233+) only
# needs a new refdata bundle registration, not a new image build.
#
# CHOICE OF GTDB RELEASE (R232 vs R226)
#
# skani publishes a pre-sketched GTDB DB at
# http://faust.compbio.cs.cmu.edu/skani-files/skani_gtdb_r226-v0.3.tar.gz, but
# that is R226 (older). We chose R232 - same release cdm_gtdbtk uses - so
# downstream tables that join taxonomy (gtdbtk) and ANI (skani_gtdb) per
# genome reference the same GTDB version. Closest-genome IDs in skani output
# match closest_genome_reference in gtdbtk output.

FROM ecogenomic/gtdbtk:2.7.2 AS source

FROM ubuntu:jammy

COPY --from=source /usr/bin/skani /usr/local/bin/skani

ENV LC_ALL=C
WORKDIR /data

ENTRYPOINT ["skani"]
