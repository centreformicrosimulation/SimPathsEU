package simpaths.integrationtest;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.*;
import org.yaml.snakeyaml.Yaml;
import simpaths.model.enums.Country;

/**
 * End-to-end regression test for SimPathsEU.
 *
 * Flow (ordered):
 *   1. Build a fresh input database from the EU inputs via {@code multirun.jar -DBSetup}
 *      using {@code config/test_create_database.yml} (Poland, seed 606, pop 30000).
 *   2. Verify that the expected input artefacts were produced.
 *   3. Run a short deterministic simulation via {@code multirun.jar}
 *      using {@code config/test_run.yml} (Poland, seed 100, 2019-2022, pop 20000,
 *      integrationTest=true).
 *   4. Diff each produced CSV against a committed golden file with a hybrid
 *      absolute/relative numeric tolerance (see {@link #tokensMatchWithTolerance}).
 *
 * Two baselines are supported, picked automatically from
 * {@code parameter_args.trainingFlag} in {@code config/test_run.yml}:
 *
 * <ul>
 *   <li>{@code trainingFlag: false} (real EUROMOD data) — the simulation writes
 *       into {@code output/INTEGRATION_TESTS/} and is diffed against
 *       {@code src/test/java/simpaths/integrationtest/expected/}. Those CSVs are
 *       NOT committed ({@code .gitignore}) because real data is not shareable.</li>
 *   <li>{@code trainingFlag: true} (shared training data) — the simulation writes
 *       into {@code output/INTEGRATION_TESTS_TRAINING/} and is diffed against
 *       {@code src/test/java/simpaths/integrationtest/expected_training/}. Those
 *       CSVs <b>are</b> committed and act as a CI-ready regression baseline.</li>
 * </ul>
 */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class RunSimPathsIntegrationTest {

    /** Absolute epsilon for numeric comparison. */
    private static final double ABS_EPSILON = 1e-9;
    /** Relative epsilon for numeric comparison. */
    private static final double REL_EPSILON = 1e-6;
    private static final Path TEST_RUN_CONFIG = Paths.get("config", "test_run.yml");
    private static final Map<String, Object> TEST_RUN_CONFIG_MAP = loadTestRunConfig();
    private static final boolean TRAINING_FLAG = resolveTrainingFlag();
    private static final Path COUNTRY_POLICY_SCHEDULE = resolveCountryPolicySchedule();
    /** Name of the sub-folder under {@code output/} that the integration run writes into. */
    private static final String OUTPUT_SUBFOLDER =
            TRAINING_FLAG ? "INTEGRATION_TESTS_TRAINING" : "INTEGRATION_TESTS";
    /** Directory holding golden CSVs to diff against. */
    private static final Path EXPECTED_DIR = Paths.get(
            "src", "test", "java", "simpaths", "integrationtest",
            TRAINING_FLAG ? "expected_training" : "expected");

    @Test
    @DisplayName("Initial database setup runs successfully")
    @Order(1)
    void testRunSetup() {
        runCommand(
                "java", "-jar", "multirun.jar", "-DBSetup", "-config", "test_create_database.yml",
                "-t", String.valueOf(TRAINING_FLAG)
        );
    }

    @Test
    @DisplayName("Database and configuration files are created")
    @Order(2)
    void testVerifySetupOutput() {
        assertFileExists("input/input.mv.db");
        assertFileExists(COUNTRY_POLICY_SCHEDULE.toString());
        assertFileExists("input/DatabaseCountryYear.xlsx");
    }

    @Test
    @DisplayName("Simulation runs successfully")
    @Order(3)
    void testRunSimulation() {
        runCommand(
                "java", "-jar", "multirun.jar", "-config", "test_run.yml",
                "-t", String.valueOf(TRAINING_FLAG)
        );
    }

    @Nested
    @DisplayName("Simulation output matches golden CSVs")
    @Order(4)
    class testVerifySimulationOutput {

        /**
         * Fixed-name output directory written by {@code SimPathsMultiRun} when
         * {@code integrationTest=true}. The exact sub-folder name is chosen by
         * {@link RunSimPathsIntegrationTest#TRAINING_FLAG} so real-data and
         * training-data runs never overwrite each other.
         */
        private static final Path OUTPUT_DIR = Paths.get("output", OUTPUT_SUBFOLDER);

        @BeforeAll
        public static void loadResults() {
            assertTrue(
                    Files.isDirectory(OUTPUT_DIR),
                    "Integration-test output directory is missing: " + OUTPUT_DIR
                            + " (expected because parameter_args.trainingFlag="
                            + TRAINING_FLAG + " in " + TEST_RUN_CONFIG + ")"
            );
        }

        @Test
        public void compareStatistics1() throws IOException {
            compareFiles(
                    OUTPUT_DIR.resolve("csv/Statistics1.csv"),
                    EXPECTED_DIR.resolve("Statistics1.csv")
            );
        }

        @Test
        public void compareStatistics21() throws IOException {
            compareFiles(
                    OUTPUT_DIR.resolve("csv/Statistics21.csv"),
                    EXPECTED_DIR.resolve("Statistics21.csv")
            );
        }

        @Test
        public void verifyAlignmentAdjustmentFactorsExported() {
            assertTrue(
                    Files.exists(OUTPUT_DIR.resolve("csv/AlignmentAdjustmentFactors1.csv")),
                    "Expected output file is missing: " + OUTPUT_DIR.resolve("csv/AlignmentAdjustmentFactors1.csv")
            );
        }

        @Test
        public void compareHealthStatistics1() throws IOException {
            compareFiles(
                    OUTPUT_DIR.resolve("csv/HealthStatistics1.csv"),
                    EXPECTED_DIR.resolve("HealthStatistics1.csv")
            );
        }

        @Test
        public void compareEmploymentStatistics1() throws IOException {
            compareFiles(
                    OUTPUT_DIR.resolve("csv/EmploymentStatistics1.csv"),
                    EXPECTED_DIR.resolve("EmploymentStatistics1.csv")
            );
        }
    }

    // ------------------------------------------------------------------
    // File-comparison helpers
    // ------------------------------------------------------------------

    void compareFiles(Path actualFile, Path expectedFile) throws IOException {
        assertTrue(Files.exists(actualFile), "Expected output file is missing: " + actualFile);
        assertTrue(Files.exists(expectedFile),
                "Golden file is missing: " + expectedFile + System.lineSeparator()
                        + "If this is the first run on this machine, capture a baseline by copying:" + System.lineSeparator()
                        + "    cp " + actualFile + " " + expectedFile);
        assertTrue(filesMatchWithTolerance(actualFile, expectedFile), fileMismatchMessage(actualFile, expectedFile));
    }

    String fileMismatchMessage(Path actualFile, Path expectedFile) throws IOException {
        List<String> actualLines = Files.readAllLines(actualFile);
        List<String> expectedLines = Files.readAllLines(expectedFile);
        int maxLines = Math.max(expectedLines.size(), actualLines.size());

        StringBuilder differences = new StringBuilder();
        for (int i = 0; i < maxLines; i++) {
            String expectedLine = (i < expectedLines.size()) ? expectedLines.get(i) : "<MISSING>";
            String actualLine = (i < actualLines.size()) ? actualLines.get(i) : "<EXTRA>";

            if (!linesMatchWithTolerance(expectedLine, actualLine)) {
                differences.append(String.format("""
                    Line %d:
                    Expected: %s
                    Actual  : %s
                    """,
                        i + 1, expectedLine, actualLine));
            }
        }

        return String.format("""

            The actual output from the integration test does not match the expected output.

            Actual output file  : %s
            Expected output file: %s

            Differences:

            %s
            IF THIS IS EXPECTED - for example, if you have changed substantive processes within the model
            or the structure of the output, please:

            1. Verify that the output is correct and as expected.
            2. Replace the expected output file with the new output file:
                cp %s %s
            3. Commit this change (or keep it local, per your project's policy) so future runs pass.

            """, actualFile, expectedFile, differences, actualFile, expectedFile);
    }

    private boolean filesMatchWithTolerance(Path actualFile, Path expectedFile) throws IOException {
        List<String> actualLines = Files.readAllLines(actualFile);
        List<String> expectedLines = Files.readAllLines(expectedFile);

        if (actualLines.size() != expectedLines.size()) {
            return false;
        }
        for (int i = 0; i < expectedLines.size(); i++) {
            if (!linesMatchWithTolerance(expectedLines.get(i), actualLines.get(i))) {
                return false;
            }
        }
        return true;
    }

    private boolean linesMatchWithTolerance(String expectedLine, String actualLine) {
        String[] expectedTokens = expectedLine.split(",", -1);
        String[] actualTokens = actualLine.split(",", -1);

        if (expectedTokens.length != actualTokens.length) {
            return false;
        }
        for (int i = 0; i < expectedTokens.length; i++) {
            if (!tokensMatchWithTolerance(expectedTokens[i], actualTokens[i])) {
                return false;
            }
        }
        return true;
    }

    /**
     * Hybrid numeric tolerance:
     *   - If both tokens parse as doubles, they match when
     *     |a - b| <= max(ABS_EPSILON, REL_EPSILON * max(|a|,|b|)).
     *   - NaN values are treated as equal to each other (Java's == says no, but for
     *     regression-comparison purposes "still NaN" is the intended behaviour).
     *   - +/- infinities must match sign.
     *   - If either token is not numeric, tokens must match exactly as strings.
     *
     * This fixes the UK reference implementation's bug in which any two parseable
     * doubles were considered equal regardless of value.
     */
    private boolean tokensMatchWithTolerance(String expectedToken, String actualToken) {
        String expectedTrimmed = expectedToken.trim();
        String actualTrimmed = actualToken.trim();

        Double expectedNumber = tryParseDouble(expectedTrimmed);
        Double actualNumber = tryParseDouble(actualTrimmed);

        if (expectedNumber != null && actualNumber != null) {
            double e = expectedNumber;
            double a = actualNumber;
            if (Double.isNaN(e) && Double.isNaN(a)) {
                return true;
            }
            if (Double.isNaN(e) || Double.isNaN(a)) {
                return false;
            }
            if (Double.isInfinite(e) || Double.isInfinite(a)) {
                return Double.compare(e, a) == 0;
            }
            double diff = Math.abs(e - a);
            double tolerance = Math.max(ABS_EPSILON, REL_EPSILON * Math.max(Math.abs(e), Math.abs(a)));
            return diff <= tolerance;
        }

        return expectedToken.equals(actualToken);
    }

    private Double tryParseDouble(String value) {
        try {
            return Double.parseDouble(value);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static Map<String, Object> loadTestRunConfig() {
        try (FileInputStream inputStream = new FileInputStream(TEST_RUN_CONFIG.toFile())) {
            Map<String, Object> config = new Yaml().load(inputStream);
            if (config == null) {
                throw new IllegalStateException("Integration test config is empty: " + TEST_RUN_CONFIG);
            }
            return config;
        } catch (IOException e) {
            throw new IllegalStateException("Failed to read integration test config: " + TEST_RUN_CONFIG, e);
        }
    }

    /**
     * Read {@code parameter_args.trainingFlag} from {@code test_run.yml}. Defaults
     * to {@code false} (real-data baseline) when the key is absent.
     */
    @SuppressWarnings("unchecked")
    private static boolean resolveTrainingFlag() {
        Object parameterArgs = TEST_RUN_CONFIG_MAP.get("parameter_args");
        if (!(parameterArgs instanceof Map)) {
            return false;
        }
        Object trainingFlag = ((Map<String, Object>) parameterArgs).get("trainingFlag");
        if (trainingFlag instanceof Boolean) {
            return (Boolean) trainingFlag;
        }
        if (trainingFlag instanceof String) {
            return Boolean.parseBoolean((String) trainingFlag);
        }
        return false;
    }

    private static Path resolveCountryPolicySchedule() {
        Object countryName = TEST_RUN_CONFIG_MAP.get("countryString");
        if (!(countryName instanceof String countryString)) {
            throw new IllegalStateException("Integration test config is missing a valid countryString: " + TEST_RUN_CONFIG);
        }

        String countryCode = Country.getCountryFromNameString(countryString).toString();
        return Paths.get("input", countryCode, "EUROMODpolicySchedule.xlsx");
    }

    // ------------------------------------------------------------------
    // Process / assertion helpers
    // ------------------------------------------------------------------

    private void runCommand(String... args) {
        try {
            ProcessBuilder processBuilder = new ProcessBuilder();
            processBuilder.command(args);
            processBuilder.redirectErrorStream(true);

            Process process = processBuilder.start();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    System.out.println(line); // Log output to console when running in Maven
                }
            }
            int exitCode = process.waitFor();
            assertEquals(0, exitCode, "Process exited with error code: " + exitCode);
        } catch (Exception e) {
            throw new RuntimeException("Failed to run: " + e.getMessage(), e);
        }
    }

    private void assertFileExists(String path) {
        assertTrue(new File(path).exists(), "Missing file " + path);
    }
}
