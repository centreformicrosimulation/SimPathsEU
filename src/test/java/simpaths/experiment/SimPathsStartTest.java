package simpaths.experiment;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import static org.junit.jupiter.api.Assertions.*;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

public class SimPathsStartTest {

    private static final ByteArrayOutputStream outContent = new ByteArrayOutputStream();
    private static final ByteArrayOutputStream errContent = new ByteArrayOutputStream();

    @BeforeAll
    public static void setUpStreams() {
        System.setOut(new PrintStream(outContent));
        System.setErr(new PrintStream(errContent));
    }

    @BeforeEach
    public void resetStreams() {
        outContent.reset();
        errContent.reset();
    }

    @Test
    public void testSimPathsStartHelpOption() {
        String[] args = {"-h"};
        SimPathsStart.main(args);

        String expectedHelpText = "SimPathsStart will start the SimPaths run";

        assertTrue(outContent.toString().contains(expectedHelpText));
        assertEquals("", errContent.toString().trim());
    }

    @Test
    public void testSimPathsStartHelpOptionWithOtherArguments() {
        String[] args = {"-g", "false", "-h", "-c", "UK"};
        SimPathsStart.main(args);

        String expectedHelpText = "SimPathsStart will start the SimPaths run";

        assertTrue(outContent.toString().contains(expectedHelpText));
        assertEquals("", errContent.toString().trim());
    }

    @Test
    public void testBadCountryName() {
        String[] args = {"-g", "false", "-s", "2017", "-c", "XX"};

        String expectedError = "Code 'XX' not a valid country.";

        SimPathsStart.main(args);
        assertTrue(errContent.toString().contains(expectedError));
    }

    @Test
    public void testReuseExistingDatabaseConflictsWithSetupOnly() {
        String[] args = {"-g", "false", "--reuse-existing-db", "-Setup"};

        try {
            Method parseCommandLineArgs = SimPathsStart.class.getDeclaredMethod("parseCommandLineArgs", String[].class);
            parseCommandLineArgs.setAccessible(true);
            boolean parsed = (boolean) parseCommandLineArgs.invoke(null, (Object) args);

            Field setupOnly = SimPathsStart.class.getDeclaredField("setupOnly");
            setupOnly.setAccessible(true);
            Field reuseExistingDatabase = SimPathsStart.class.getDeclaredField("reuseExistingDatabase");
            reuseExistingDatabase.setAccessible(true);

            assertTrue(parsed);
            assertTrue(setupOnly.getBoolean(null));
            assertFalse(reuseExistingDatabase.getBoolean(null));
        } catch (ReflectiveOperationException e) {
            fail(e);
        }
    }

    @Test
    public void testRebuildDatabaseOverridesReuse() {
        String[] args = {"-g", "false", "--reuse-existing-db", "--rebuild-db"};

        try {
            Method parseCommandLineArgs = SimPathsStart.class.getDeclaredMethod("parseCommandLineArgs", String[].class);
            parseCommandLineArgs.setAccessible(true);
            boolean parsed = (boolean) parseCommandLineArgs.invoke(null, (Object) args);

            Field reuseExistingDatabase = SimPathsStart.class.getDeclaredField("reuseExistingDatabase");
            reuseExistingDatabase.setAccessible(true);

            assertTrue(parsed);
            assertFalse(reuseExistingDatabase.getBoolean(null));
        } catch (ReflectiveOperationException e) {
            fail(e);
        }
    }
}
