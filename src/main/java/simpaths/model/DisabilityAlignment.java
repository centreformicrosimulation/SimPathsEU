package simpaths.model;

import microsim.engine.SimulationEngine;
import simpaths.data.IEvaluation;
import simpaths.data.Parameters;
import simpaths.model.decisions.DecisionParams;
import simpaths.model.enums.Indicator;
import simpaths.model.enums.Les_c4;
import simpaths.model.enums.TargetShares;

import java.util.Set;


/**
 * DisabilityAlignment adjusts the probability of becoming disabled.
 * The object is designed to assist modification of the intercept of the "H2" disability model.
 *
 * A search routine is used to find the value by which the intercept should be adjusted.
 * If the projected share of disabled individuals in the population differs from the desired target by more than a specified threshold,
 * then the intercept is adjusted and the share re-evaluated.
 *
 * Importantly, the adjustment needs to be only found once. Modified intercepts can then be used in subsequent simulations.
 */
public class DisabilityAlignment implements IEvaluation {

    private double targetDisabledShare;
    private Set<Person> persons;
    private SimPathsModel model;
    private long numWithDlltsd;
    private long numIneligibleDisabled;
    private boolean probitActive;


    // CONSTRUCTOR
    public DisabilityAlignment(Set<Person> persons) {
        this.model = (SimPathsModel) SimulationEngine.getInstance().getManager(SimPathsModel.class.getCanonicalName());
        this.persons = persons;
        targetDisabledShare = Parameters.getTargetShare(model.getYear(), TargetShares.Disability);
        probitActive = !Parameters.enableIntertemporalOptimisations || DecisionParams.flagDisability;

        numWithDlltsd = persons.stream()
                .filter(person -> person.getDlltsd() != null)
                .count();

        // Persons not eligible for the disability probit keep their current dlltsd
        numIneligibleDisabled = persons.stream()
                .filter(person -> person.getDlltsd() != null
                        && (person.getDag() < Parameters.AGE_TO_BECOME_SEMI_RESPONSIBLE
                            || Les_c4.Retired.equals(person.getLes_c4())
                            || Les_c4.Student.equals(person.getLes_c4()))
                        && Indicator.True.equals(person.getDlltsd()))
                .count();
    }


    /**
     * Evaluates the discrepancy between the expected (smooth) disabled share at a candidate adjustment
     * and the target share. Uses sum of probit probabilities rather than stochastic realisations,
     * yielding a smooth, deterministic objective for the root search.
     *
     * @param args An array of parameters, where args[0] represents the probit intercept adjustment.
     * @return target disabled share minus expected disabled share at the given adjustment.
     */
    @Override
    public double evaluate(double[] args) {

        if (numWithDlltsd == 0) return targetDisabledShare;

        double expectedDisabled;
        if (probitActive) {
            expectedDisabled = persons.parallelStream()
                    .filter(person -> person.getDlltsd() != null
                            && person.getDag() >= Parameters.AGE_TO_BECOME_SEMI_RESPONSIBLE
                            && !Les_c4.Retired.equals(person.getLes_c4())
                            && !Les_c4.Student.equals(person.getLes_c4()))
                    .mapToDouble(person -> {
                        double score = Parameters.getRegHealthH2().getScore(person, Person.DoublesVariables.class);
                        return Parameters.getRegHealthH2().getProbability(score + args[0]);
                    })
                    .sum();
        } else {
            // Intertemporal path with flagDisability off: all eligible become non-disabled
            expectedDisabled = 0;
        }

        double expectedDisabledShare = (expectedDisabled + numIneligibleDisabled) / numWithDlltsd;
        return targetDisabledShare - expectedDisabledShare;
    }
}
