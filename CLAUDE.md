# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SimPaths is a JAS-mine-based microsimulation model that projects individual and household life course events (career, family, health, finances) for EU countries. This repository covers Greece (EL), Italy (IT), Spain (ES), Hungary (HU), and Poland (PL). It integrates with EUROMOD for tax/benefit policy simulation.

Spain (ES) is being added. **The Java code treats ES as a first-class country** — `Country.ES("Spain", 13)`, `Region.ES1`–`ES7` (NUTS-1), `Labour.CATEGORY_ES_1`–`3` (ids 51–53), Spanish state-pension rules in `Parameters.getStatePensionAge` (statutory ages given in years and months), an ES block in `BenefitUnit.getRegressionValue`, and `Person.Regressors.ES1`–`ES7`. The earlier `Parameters.dataCountryString()` seam that redirected `ES`→`PL` has been removed, so nothing falls back to Poland's structures any more.

**Most of `input/ES/` is now genuine Spanish data** (verified Aug 2026):

- `InitialPopulations/population_initial_ES_2011..2024.csv` — real Spanish populations on the current 44-column camelCase schema, `demRgn ∈ {1…7}`, so all seven NUTS-1 regions resolve. The earlier `ES_TBC/` staging folder is gone.
- `EUROMODoutput/es_2005..2025_std.txt` — genuine Spanish EUROMOD output (`dct = 13`, 344 columns); the tax-unit identifier is `tu_nucfam_HeadID`, mapped in `input/system_bu_names.xlsx`. The leftover `EUROMODoutput/pl/` folder is gone.
- Eleven of the twelve `reg_*.xlsx` carry ES coefficients with `ES1`–`ES6` region dummies (`reg_wages`, `reg_employmentSelection` and `reg_fertility` also include `ES7`; `reg_RMSE` has no region dummies). `align_popProjections.xlsx` is keyed on `ES1`–`ES7`, and `time_series_factor.xlsx` is Spain's own uprating series, no longer Poland's.
- `input/DatabaseCountryYear.xlsx` includes ES, and `src/main/resources/images/ES.png` supplies the GUI flag.

**Still outstanding before `-c ES` is trustworthy:**

- Three files under `input/ES/` remain byte-identical PL clones and still need Spanish values: `reg_labourSupplyUtility.xlsx` (so the ES block in `BenefitUnit` is still estimated on Polish coefficients), `align_educLevel.xlsx`, `social_care_parameters.xlsx`.
- `alignment_adjustment_factors.xlsx` is **expected** to be identical across countries — do not flag it as a stale PL clone. All 13 data sheets are zero-filled, and zero is the neutral cold start for a fresh calibration. Aligned runs search for the adjustment path and overwrite the in-memory map only; the workbook is never written back, so calibrated values are copied in by hand if you want to reuse them (see the file's own `Info` sheet).
- `scenario_retirementAgeFixed.xlsx` was rebuilt with Spain's schedule (65 to 2017, 66 for 2018–2023, 67 from 2024, gender-neutral) to match `Parameters.getStatePensionAge` case `"ES"`; it is no longer a PL clone.
- `input/ES/InitialPopulations/training/` is **empty** while `EUROMODoutput/training/` holds 21 files (501 columns, against 344 in the production files), so `-t true` has no ES starting population to read.
- The `Region.ES1`–`ES7` code↔name mapping is still unverified against the EUROMOD ES country report (TODO at `Region.java:22`).

**Data access**: The input data is not freely shareable. Training data is provided for development, but results from training data should not be interpreted beyond development purposes. Contact maintainers via GitHub issues for real data access.

## Build and Run

Requires **Java 19** and **Maven**.

```bash
# Build both JARs (output: singlerun.jar, multirun.jar in project root)
mvn clean package

# Run setup phase (creates input population database, no simulation)
java -jar singlerun.jar -c IT -s 2017 -g false -Setup

# Run multi-run simulation
java -jar multirun.jar -r 100 -p 50000 -n 20 -s 2017 -e 2020 -g false -f

# Run tests
mvn test

# Run a single test class
mvn test -Dtest=SimPathsStartTest
```

CLI help: `java -jar singlerun.jar -h` or `java -jar multirun.jar -h`

### Key CLI flags

- `-c <CC>` country code (`EL`, `IT`, `ES`, `HU`, `PL`); `-s` start year; `-e` end year; `-p` population size; `-g true|false` show GUI.
- `-t true|false` (`--training`) — use the training-data subset under `input/<CC>/InitialPopulations/training/` and `EUROMODoutput/training/` (uses `TaxDonorParserTraining`). On `multirun.jar` this **overrides** `parameter_args.trainingFlag` from the YAML config.
- `singlerun.jar -Setup` — setup phase only (build the H2 input DB, no simulation). Multi-run equivalent is `-DBSetup`.
- `multirun.jar -r <seed>` random seed, `-n <N>` max runs, `-f` output to file, `-config <file.yml>` custom config (default `config/default.yml`).
- **Training auto-detect**: if `-t` is omitted and `input/<CC>/InitialPopulations/*.csv` is empty, `Parameters.trainingFlag` is flipped to `true` automatically and a notice is printed to stdout (`SimPathsStart.java:363-368, 520-525`). To diagnose which mode is active at runtime, look for either `Training-data flag set explicitly via CLI: -t ...` or `auto-switching to training data` in the console output.

## Architecture

### Entity Hierarchy

**Household → BenefitUnit → Person** (all JPA entities persisted in H2 at `input/input.mv.db`)

- `Person` — individual agent; tracks age, gender, education, employment, health, wages, disability, family links
- `BenefitUnit` — tax/benefit assessment unit; tracks wealth, income, childcare costs, poverty status
- `Household` — container grouping benefit units from the same origin household

### Key Packages

| Package | Role |
|---------|------|
| `simpaths.experiment` | Entry points: `SimPathsStart` (single run), `SimPathsMultiRun` (batch), `SimPathsCollector` (output), `SimPathsObserver` (GUI) |
| `simpaths.model` | Core agents (`Person`, `BenefitUnit`, `Household`) and simulation manager `SimPathsModel` |
| `simpaths.model.decisions` | Dynamic stochastic optimization — consumption/labour/savings via CES utility, grids, expectations |
| `simpaths.model.taxes` | EUROMOD donor population matching for tax/benefit imputation (`DonorPerson`, `TaxEvaluation`) |
| `simpaths.model.enums` | All enumerations (`Country`, `Region`, `Gender`, `Education`, `ActivityStatus`, etc.) |
| `simpaths.data` | Global parameters (`Parameters` static config), regression managers, Mahalanobis distance matching |
| `simpaths.data.startingpop` | Parses and persists the initial EU-SILC population |
| `simpaths.data.filters` | Alignment target filters for demographics and economics |
| `simpaths.data.statistics` | Output statistics collection (Gini, poverty, employment rates) |

### Simulation Flow

1. **Setup**: `SimPathsStart` loads input population into H2 database
2. **Build**: `SimPathsModel.buildObjects()` instantiates agents from DB
3. **Annual event loop** fires transitions: demographics (partnerships, births, deaths, retirement) → labour market → tax/benefit evaluation → health/disability
4. **Alignment**: Mahalanobis-distance resampling adjusts distributions to match targets (YAML configs in `config/alignment_*.yml`)
5. **Collection**: `SimPathsCollector` exports CSV statistics and optional DB snapshots to timestamped `output/` subdirectories

### Data Inputs

- `input/input.mv.db` — H2 database with processed EU-SILC starting population
- `input/[COUNTRY]/InitialPopulations/` — actual starting-population CSVs; `…/training/` holds the shipped training subset
- `input/[COUNTRY]/EUROMODoutput/` — EUROMOD donor CSVs; `…/training/` holds the training subset
- `input/[COUNTRY]/` — country-specific Excel parameter files (e.g. `EUROMODpolicySchedule.xlsx`)
- `input/DatabaseCountryYear.xlsx` — Cross-country/year index
- `config/default.yml` — Default multi-run parameters (population size, year range, run count)
- `config/alignment_*.yml` — Staged alignment configurations
- `config/test_create_database.yml`, `config/test_run.yml` — Configs used by the integration test

### Repository layout (beyond `src/`)

- `scripts/` — shell wrappers for batch multi-runs (`run_alignment_multiruns.sh`, `run_multiruns-alignPopOFF.sh`, `run_TEST_multiruns.sh`, …)
- `input_processing/` — Stata do-files that prepare model inputs upstream of the Java pipeline (master conditions, regression-estimate cleaning, lag-structure generation). For ES: `90_cleaning_excel_inputs.do` reads `reg_estimates_ES_toClean/` and writes `reg_estimates_ES_Cleaned/`; `91_add_dct_to_EUROMOD_training.do` stamps `dct` onto the training donor files.
- `input/<CC>/DoFilesTargets/` — Stata do-files that build that country's alignment-target workbooks from the initial populations (`01`–`05` for retirement, in-school, disability, partnership and employment) plus `91_plot_targets_from_xlsx.do` for the target plots
- `tools/generate_simpaths_eu_variable_codebook.py` — variable codebook generator
- `validation/` — Stata validation against EU-SILC/EUROMOD targets
- `documentation/` — supplementary documentation
- `output/` — timestamped simulation outputs (created at runtime)

### Tax/Benefit Imputation

Uses a donor population approach: simulated persons are matched to EUROMOD-processed donors using Mahalanobis distance. Key classes: `DonorTaxImputation`, `TaxEvaluation`, `MatchIndices`.

### Decisions Module

Solves dynamic stochastic problems over a discretised state space (`Grid`, `Grids`, `States`, `Axis`). `ExpectationsFactory` constructs transition expectations; `CESUtility` evaluates utility. Results are stored in grid files loaded at startup.

## Testing

JUnit 5 + Mockito. Tests in `src/test/java/simpaths/`:

- `experiment/SimPathsStartTest` — CLI argument parsing, country validation
- `experiment/SimPathsMultiRunTest` — Multi-run configuration
- `experiment/PersonTest` — Person entity logic
- `data/MahalanobisDistanceTest` — Statistical matching
- `integrationtest/RunSimPathsIntegrationTest` — End-to-end run using `config/test_create_database.yml` + `config/test_run.yml`

## Branch Conventions

- `main` — stable release
- `develop` — integration
- `feature/name` — new features
- `bugfix/issue-number-description` — bug fixes
- `experimental/description` — exploratory work
- `docs/topic` — documentation

## Validation

Stata do-files in `validation/` compare simulated output against EU-SILC and EUROMOD targets.
