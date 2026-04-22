# Integration-test golden files

This directory holds the "golden" CSV outputs that `RunSimPathsIntegrationTest`
diffs the simulation output against. The CSV files are **not committed** to
this repository (see the entry in `.gitignore`) because SimPathsEU does not yet
have a shared training-data set — each developer must capture a local baseline
against their own input data before making behavioural changes.

## When to use this test

Before refactoring anything that could shift simulated output (model code,
alignment, tax/benefit, health transitions, …) run the test once to capture
the current output as the baseline, then run it again after your change to
verify that nothing moved.

## Regenerating the golden files locally

1. Build the project:

    ```sh
    mvn clean package -DskipTests
    ```

2. Run the integration test once. It will fail on the comparison step because
   the expected CSVs do not yet exist:

    ```sh
    mvn verify -Dit.test=RunSimPathsIntegrationTest
    ```

3. Copy the actual outputs into this directory as the baseline:

    ```sh
    LATEST=$(ls -td output/*/ | head -n 1)
    cp "${LATEST}csv/Statistics1.csv"                 src/test/java/simpaths/integrationtest/expected/
    cp "${LATEST}csv/Statistics21.csv"                src/test/java/simpaths/integrationtest/expected/
    cp "${LATEST}csv/HealthStatistics1.csv"           src/test/java/simpaths/integrationtest/expected/
    cp "${LATEST}csv/EmploymentStatistics1.csv"       src/test/java/simpaths/integrationtest/expected/
    # AlignmentAdjustmentFactors1.csv is only checked for existence, no diff.
    ```

4. Rerun `mvn verify` — it should now pass.

## When the diff fires after a refactor

If you made an *intentional* behavioural change, regenerate the baseline as
above and keep the new files locally. If the diff was unexpected, that is
exactly the signal this test exists to provide — investigate before moving on.

## Comparison rules

The test uses a **hybrid numeric tolerance** (see
`RunSimPathsIntegrationTest.tokensMatchWithTolerance`):

- numeric tokens match when `|a - b| <= max(1e-9, 1e-6 * max(|a|, |b|))`
- `NaN` is treated as equal to `NaN`
- non-numeric tokens must match exactly as strings
- line counts and column counts must match exactly

## Why this directory is empty in the repo

It's empty until a shareable training data set for EU is added. Once that
exists, we can commit a canonical set of goldens here and the test becomes
a CI-ready regression check for every PR.
