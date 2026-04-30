# Integration-test golden files — training-data baseline

This directory holds the golden CSV outputs that `RunSimPathsIntegrationTest`
diffs the simulation output against **when `parameter_args.trainingFlag: true`
in `config/test_run.yml`** (the shared training-data baseline).

Unlike the real-data baseline under [`../expected/`](../expected/README.md),
the CSV files in this directory **are committed to the repository** because
the training data is shareable. This baseline is therefore suitable as a
CI-ready regression check for every PR.

> When `trainingFlag: true`, `SimPathsMultiRun` writes simulation output to
> `output/INTEGRATION_TESTS_TRAINING/` (and to `output/INTEGRATION_TESTS/`
> when `trainingFlag: false`). The test picks the matching output folder
> and the matching expected directory automatically.

## Regenerating the training baseline

Do this only when you have **intentionally** changed model behaviour and
confirmed the new output is correct. The new CSVs will be committed and will
become the reference every PR is diffed against.

1. Set `parameter_args.trainingFlag: true` in `config/test_run.yml`
   (and `config/test_create_database.yml`).

2. Make sure the training input data is in place under
   `input/<COUNTRY>/InitialPopulations/training/` and
   `input/<COUNTRY>/EUROMODoutput/training/` (see `Parameters.java` —
   `getInputDirectoryInitialPopulations` / `getEuromodOutputDirectory` switch
   on `trainingFlag`).

3. Build and run the test:

    ```sh
    mvn clean package -DskipTests
    mvn verify -Dit.test=RunSimPathsIntegrationTest
    ```

4. Copy the actual outputs as the new baseline and commit them:

    ```sh
    SRC=output/INTEGRATION_TESTS_TRAINING/csv
    cp "$SRC/Statistics1.csv"           src/test/java/simpaths/integrationtest/expected_training/
    cp "$SRC/Statistics21.csv"          src/test/java/simpaths/integrationtest/expected_training/
    cp "$SRC/HealthStatistics1.csv"     src/test/java/simpaths/integrationtest/expected_training/
    cp "$SRC/EmploymentStatistics1.csv" src/test/java/simpaths/integrationtest/expected_training/
    git add src/test/java/simpaths/integrationtest/expected_training/*.csv
    ```

5. Re-run `mvn verify` to confirm the test now passes, then commit.

## When the diff fires on someone else's PR

The training-data baseline is the repo's contract: if the diff fires on a PR,
the change moved simulated output and the author needs to justify it. If the
change is intentional, regenerate and commit the baseline as above; if not,
the diff is exactly the signal that caught a regression.

## Comparison rules

Same hybrid tolerance as the real-data baseline — see
[`../expected/README.md`](../expected/README.md#comparison-rules).
