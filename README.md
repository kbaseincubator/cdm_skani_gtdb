# cdm_skani_gtdb

CTS (CDM Task Service) job wrapper for [skani](https://github.com/bluenote-1577/skani) paired with the **GTDB R232** reference sketch database. Lets you query user genomes against the full GTDB R232 representative set for nearest-reference ANI in seconds (vs hours for the full GTDB-Tk pipeline).

For ad-hoc skani usage without GTDB reference data (user-vs-user comparison, custom reference sets), use [`cdm_skani`](https://github.com/kbaseincubator/cdm_skani).

## Container

- Published to `ghcr.io/kbaseincubator/cdm_skani_gtdb`
- Skani version: **0.3.1** (pinned, same binary as cdm_skani)
- Entrypoint: `skani` (no subcommand) - append `search` (typical) or `dist` as the first argument

## Reference data

Bound at CTS registration time to the existing GTDB-Tk R232 bundle:

- `cts-refdata/gtdbtk/r232/gtdbtk_r232_data.tar.gz`
- Refdata UUID: `bb6352b4-b86f-4e3d-a858-4bc77327ab13`
- Mounted at: `/ref_data/`

Inside the unpacked R232 bundle the skani sketch directory is at `/ref_data/release232/skani/database/`. Pass that path to `skani search -d`.

### Why R232 and not skani's pre-sketched R226

skani publishes a pre-sketched GTDB at `http://faust.compbio.cs.cmu.edu/skani-files/skani_gtdb_r226-v0.3.tar.gz`, but that one is **R226** (older). The KBase inner-loop stack standardized on **R232** for `cdm_gtdbtk`, and we chose to reuse the same R232 bundle for `cdm_skani_gtdb` so that any downstream table joining taxonomy (gtdbtk) and nearest-reference ANI (skani_gtdb) on the same genome resolves to the same GTDB version. Closest-reference IDs from skani therefore match `closest_genome_reference` from gtdbtk by construction.

### Version pin (skani 0.3.1)

The skani binary is copied out of `ecogenomic/gtdbtk:2.7.2`, which is exactly the binary used by GTDB-Tk 2.7.2 to build the R232 skani sketches inside the bundle. Sketch-format compatibility across skani versions is documented as "use the same version that built the database"; pinning here removes that failure mode.

## Usage

### Typical: search query genomes against the bundled GTDB R232 sketch DB

```python
job = tscli.submit_job(
    "ghcr.io/kbaseincubator/cdm_skani_gtdb:0.1.0",
    input_genomes,                       # one or more user .fna / .fna.gz
    "cts/io/<user>/output/skani_gtdb/run1",
    cluster="kbase",
    declobber=True,
    output_mount_point="/out",
    args=[
        "search",
        "-d", "/ref_data/release232/skani/database/",
        "-o", "/out/hits.tsv",
        "-t", "4",
        "-n", "10",                       # top-10 nearest GTDB references per query
        "--short-header",
        tscli.insert_files(),
    ],
    num_containers=1,
    cpus=4, memory="32GB", runtime="PT1H",
)
```

Memory: per the skani docs, querying ~140k GTDB representatives takes "seconds with a single processor and ~6 GB of RAM" - the 32 GB budget here is comfort margin.

### Output columns

skani search emits a TSV with: `Ref_file`, `Query_file`, `ANI`, `Align_fraction_ref`, `Align_fraction_query`, `Ref_name`, `Query_name`. With `--detailed`, also adds contig N50 and other diagnostics. With `--ci`, adds 5%/95% ANI confidence intervals.

For nearest-neighbor queries the `Ref_file` basename is the GTDB representative genome ID (e.g. `GCA_000147015.1_genomic.fna.gz`) - strip `_genomic.fna.gz` to recover the GTDB ID that matches `gtdbtk.bac120.summary.tsv:closest_genome_reference`.

## Reference

Shaw & Yu, *Nature Methods* (2023), DOI 10.1038/s41592-023-02018-3.
