# Integration-test golden files — Spain (ES), training-data baseline

Golden CSVs that `RunSimPathsESIntegrationTest` diffs against when
`parameter_args.trainingFlag: true` in `config/test_run_ES.yml` (the default).

These CSVs **are committed**, because the training data is shareable. This is the
CI-ready regression baseline that every PR is diffed against — the exact counterpart
of [`../expected_training_PL/`](../expected_training_PL/README.md).

| | training data | real data |
|---|---|---|
| output folder | `output/INTEGRATION_TESTS_TRAINING_ES/` | `output/INTEGRATION_TESTS_ES/` |
| golden files | `expected_training_ES/` (committed) | [`../expected_ES/`](../expected_ES/README.md) (gitignored) |

Inputs: `input/ES/InitialPopulations/training/` (2011–2024) and
`input/ES/EUROMODoutput/training/` (2005–2025), both committed.

## Regenerating the baseline

Do this only when you have **intentionally** changed model behaviour and confirmed
the new output is correct. The new CSVs are committed and become the reference every
PR is diffed against.

```sh
mvn clean package -DskipTests
mvn verify -Dit.test=RunSimPathsESIntegrationTest

SRC=output/INTEGRATION_TESTS_TRAINING_ES/csv
DST=src/test/java/simpaths/integrationtest/expected_training_ES
cp "$SRC/WealthIncomeStatistics.csv" "$SRC/DemographicStatistics.csv" \
   "$SRC/HealthStatistics.csv" "$SRC/HealthByGender.csv" \
   "$SRC/LabourStatistics.csv" "$DST/"
git add "$DST"/*.csv

mvn verify -Dit.test=RunSimPathsESIntegrationTest   # confirm green, then commit
```

`AlignmentStatistics.csv` is only checked for existence, not diffed.

## When the diff fires on someone else's PR

The training-data baseline is the repo's contract: if the diff fires on a PR, the
change moved simulated output and the author needs to justify it. If the change is
intentional, regenerate and commit the baseline as above; if not, the diff is exactly
the signal that caught a regression.

## Caveat on the numbers

The ES baseline pins *reproducibility*, not correctness. Several ES inputs are still
Polish clones — notably `input/ES/reg_labourSupplyUtility.xlsx`,
`align_educLevel.xlsx` and `social_care_parameters.xlsx` — so ES levels are not yet
meaningful. The test's job is to catch unintended movement, and to catch ES breaking
outright when country-generic code changes.

## Comparison rules

Same hybrid tolerance as every other baseline — see
[`../expected_PL/README.md`](../expected_PL/README.md#comparison-rules).
