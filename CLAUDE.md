# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SimPaths is a JAS-mine-based microsimulation model that projects individual and household life course events (career, family, health, finances) for EU countries. This repository covers Greece (EL), Italy (IT), Hungary (HU), and Poland (PL). It integrates with EUROMOD for tax/benefit policy simulation.

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
- `input/[COUNTRY]/` — Country-specific Excel parameter files, EUROMOD output CSVs
- `input/DatabaseCountryYear.xlsx` — Cross-country/year index
- `config/default.yml` — Default multi-run parameters (population size, year range, run count)
- `config/alignment_*.yml` — Staged alignment configurations

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

## Branch Conventions

- `main` — stable release
- `develop` — integration
- `feature/name` — new features
- `bugfix/issue-number-description` — bug fixes
- `experimental/description` — exploratory work
- `docs/topic` — documentation

## Validation

Stata do-files in `validation/` compare simulated output against EU-SILC and EUROMOD targets.
