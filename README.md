# SimPathsEU

by Matteo Richiardi, Patryk Bronka, Justin van de Ven, Mariia Vartuzova, David Sonnewald

## Introduction

SimPaths is a family of models for individual and household life course events, all sharing common components. The framework is designed to project life histories through time, building up a detailed picture of career paths, family (inter)relations, health, and financial circumstances. The framework builds upon standardised assumptions and data sources, which facilitates adaptation to alternative countries. This repository, **SimPathsEU**, covers Greece (`EL`), Hungary (`HU`), Italy (`IT`), and Poland (`PL`), and integrates with EUROMOD for tax and benefit policy simulation. Careful attention is paid to model validation, and sensitivity of projections to key assumptions. The modular nature of the SimPaths framework is designed to facilitate analysis of alternative assumptions concerning the tax and benefit system, sensitivity to parameter estimates and alternative approaches for projecting labour/leisure and consumption/savings decisions. Projections for a workhorse model parameterised to the UK context are reported in [Bronka, P., Richiardi, M., & van de Ven, J. (2023). *SimPaths: an open-source microsimulation model for life course analysis* (No. CEMPA6/23), Centre for Microsimulation and Policy Analysis at the Institute for Social and Economic Research*](https://www.microsimulation.ac.uk/publications/publication-557738/), which closely reflect observed data throughout a 10-year validation window.

## Getting Started

To contribute to this project, you need to fork the repository and set up your development environment.

### Access to Data

We are committed to maintaining transparency and open-source principles in this project. All the code, documentation, and resources related to our project are available on GitHub for you to explore, use, and contribute to.

The data used by this project is not freely shareable. If you are interested in accessing the data necessary to run the simulation, get in touch with the repository maintainers for further instructions.

However, please note that _training_ data is provided. It allows the simulation to be run and developed, but results obtained on the basis of the training dataset should not be interpreted, except for the purpose of training and development. 

**How to Request Access to Data:**

If you have a need for the data, please contact the repository maintainers through the [issue tracker](https://github.com/simpaths/SimPathsEU/issues).


### Forking the Repository

1. Click the "Fork" button at the top-right corner of this repository.
2. Untick the `Copy only the main branch` box.
3. This will create a copy of the repository in your own GitHub account.
4. Follow [instructions here](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork) to periodically synchronize your fork with the most recent version of this ("upstream") repository. This will ensure you use an up-to-date version of the model.

### Setting up your development environment
1. **Java Development Kit (JDK):** the project targets **Java 19 or later** (see `pom.xml`, which pins `source`/`target` to 19). Install a compatible JDK, e.g. OpenJDK 19+ from [Adoptium](https://adoptium.net/).
2. **Maven:** required to build from the command line. See [installation instructions](https://maven.apache.org/install.html). (Not required if you only build via the IDE.)
3. **Download an IDE** (integrated development environment) of your choice - we recommend [IntelliJ IDEA](https://www.jetbrains.com/idea/download/); download the Community (free) or Ultimate (paid) edition, depending on your needs.
4. Clone your forked repository to your local machine. Import the cloned repository into IntelliJ as a Maven project

### Compiling and running SimPaths with Maven in the CLI

SimPaths can also be compiled by Maven ([installation instructions here](https://maven.apache.org/install.html)) and run from the command line without an IDE. After cloning the repository and setting up the JDK, in the root directory you can run:
```
$ mvn clean package
```
... to create two runnable jars for single- and multi-run SimPaths:
```
.
SimPaths/
      ...
      |-- multirun.jar
      |-- singlerun.jar
      `-- src
```

To build without running the unit test suite (faster turnaround during development):
```
$ mvn clean package -DskipTests
```

#### Running tests

Unit tests run by default as part of the `test` / `package` phases. Integration tests (which exercise a full end-to-end simulation) are bound to the `verify` phase:
```
$ mvn verify                                          # run unit + integration tests
$ mvn verify -Dit.test=RunSimPathsIntegrationTest     # run just the integration test
```

#### Single run

`singlerun.jar` runs a single SimPaths simulation and is also the entry point used to build/rebuild the input population database. It takes the following options:

- `-c` Country (e.g. `EL`, `HU`, `IT`, `PL`) — **required for the initial setup**
- `-s` Start year
- `-e` End year
- `-p` Simulated population size
- `-g` [true/false] show/hide gui
- `-r` Re-write policy schedule from detected policy files
- `-Setup` do setup phases (creating input populations database) only
- `--rebuild-db` Force a rebuild of `input/input.mv.db` instead of reusing it (headless mode)
- `--reuse-existing-db` Reuse `input/input.mv.db` if present, otherwise build it (headless mode)

**Important:** the country (`-c`) and start year (`-s`) must be specified when creating or rebuilding the input population database — the resulting `input/input.mv.db` is country- and year-specific.

Typical workflows:
```
# 1. Build (or rebuild) input.mv.db for a given country/start year.
#    Both commands below rebuild the database identically — pick ONE,
#    based on what you want to happen after the rebuild finishes:
#
#    Option 1 — rebuild the database and exit (no simulation).
#               Use this to prep the DB ahead of a multirun.
$ java -jar singlerun.jar -c PL -s 2011 -g false -Setup
#
#    Option 2 — rebuild the database and then run a single-run simulation
#               straight after, using the freshly built DB.
$ java -jar singlerun.jar -c PL -s 2011 -g false --rebuild-db

# 2. Run a single-run simulation on an existing input.mv.db (reuse as-is,
#    or build it first if missing — no rebuild if it already exists)
$ java -jar singlerun.jar -c PL -s 2011 -g false --reuse-existing-db

# 3. Run a simulation over a given year range on an existing database
$ java -jar singlerun.jar -g false -s 2011 -e 2013 -p 30000
```

#### Multi run

For multiple runs, `multirun.jar` takes the following options:

- `-r` random seed for first run (incremented by +1 for subsequent runs)
- `-p` simulated population size
- `-n` number of runs
- `-s` start year of runs
- `-e` end year of runs
- `-g` [true/false] show/hide gui
- `-f` write console output and logs to file (in 'output/logs/run_[seed].txt')
- `-config <file>` use a custom YAML config from `config/` instead of `default.yml`
- `-DBSetup` build the input population database for the configured country/start year, then exit

**Note:** `multirun.jar` does **not** take a `-c` country flag — it resolves the country from `input/DatabaseCountryYear.xlsx`. Make sure that file reflects the country you intend to run.

**Before running multiruns:**
1. Ensure `input/DatabaseCountryYear.xlsx` is populated with the country/year combination you intend to run — multirun reads it to resolve the country and start year.
2. Rebuild the input database whenever it needs to be refreshed (especially when changing the start year). A different population size alone does not require a rebuild: the processed starting population is resampled to match the requested size.

Typical multirun workflow:
```
# 1. (Re)build the input database for the configured country/start year
$ java -jar multirun.jar -DBSetup -s 2011 -g false

# 2. Run N simulations over a year range
$ java -jar multirun.jar -g false -s 2011 -e 2013 -p 30000 -n 3
```

Example with explicit seed and logging:
```
$ java -jar multirun.jar -r 100 -p 50000 -n 20 -s 2017 -e 2020 -g false -f
```

Run `java -jar singlerun.jar -h` or `java -jar multirun.jar -h` to show these help messages.

### Batch scenario scripts

Helper Bash scripts in `scripts/` run `multirun.jar` across multiple alignment configs in sequence and move each scenario's CSV output into `output/<scenario-name>/`:

- `run_alignment_multiruns.sh` — full set of alignment scenarios
- `run_multiruns-alignPopOFF.sh` — single `alignment_00_populationOFF` scenario
- `run_multiruns-alignPopOFF_QUICK.sh` — quick smoke-test variant
- `run_TEST_multiruns.sh` — subset used while testing new alignments

Run from the project root (the scripts resolve paths relative to it):
```
$ ./scripts/run_alignment_multiruns.sh
```

Defaults (start/end year, population size, runs per scenario, JVM heap, random seed) are set at the top of each script and can be overridden via environment variables, e.g.:
```
$ POP_SIZE=10000 RUNS_PER_SCENARIO=2 ./scripts/run_alignment_multiruns.sh
```

### Contributing

1. Create a new branch for your contributions. This will likely be based on either the `main` branch of this repository (if you seek to modify the stable version of the model) or `develop` (if you seek to modify the most recent version of the model).  Please see branch naming convention below.
2. Make your changes, add your code, and write tests if applicable.
3. Commit your changes.
4. Push your changes to your fork.
5. Open a Pull Request (PR) on this repository from your fork. Be sure to provide a detailed description of your changes in the PR.

### Branch Naming Conventions

In our open-source project, we follow a clear and consistent branch naming convention to streamline the development process and maintain a structured repository. These conventions help our team of contributors collaborate effectively. Here are the primary branch naming patterns:

1. **Main Branches:**
    - `main`: Represents the stable version of our model.
    - `develop`: Used for ongoing development and integration of new features.

2. **Feature Branches:**
    - `feature/your-feature-name`: Create feature branches for developing new features.

3. **Bug Fix Branches:**
    - `bugfix/issue-number-description`: Use bug fix branches for specific issue resolutions. For example, `bugfix/123-fix-health-process-issue`.

4. **Experimental or Miscellaneous Branches:**
    - `experimental/your-description`: For experimental or miscellaneous work not tied to specific features or bug fixes. For instance, `experimental/new-architecture`.

5. **Documentation Branches:**
    - `docs/documentation-topic`: Prefix documentation branches with `docs` for updating or creating documentation. For example, `docs/update-readme`.

These branch naming conventions are designed to make it easy for our contributors to understand the purpose of each branch and maintain consistency within our repository. Please adhere to these conventions when creating branches for your contributions.
