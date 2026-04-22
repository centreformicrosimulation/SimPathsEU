package simpaths.data.statistics;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;

import microsim.data.db.PanelEntityKey;
import microsim.statistics.CrossSection;
import microsim.statistics.IDoubleSource;
import microsim.statistics.functions.MeanArrayFunction;

import simpaths.data.filters.AgeGroupCSfilter;
import simpaths.data.filters.EmploymentHistoryFilter;
import simpaths.model.Person;
import simpaths.model.SimPathsModel;
import simpaths.model.enums.Les_c4;

/**
 * Employment statistics entity. Records, for the working-age adult population (16-64):
 *   - transition rates between employed (E) and not-employed (NE) states
 *   - headline proportions employed / not-employed
 *
 * Ported from SimPathsUK. Uses the same Person.getEmployed()/getNonwork()
 * integer indicators and Les_c4 enum which are common to both UK and EU models.
 */
@Entity
public class EmploymentStatistics {

    @Id
    private PanelEntityKey key = new PanelEntityKey(1L);

    @Column(name = "EmpToNotEmp")
    private double labEmpToNotEmpShare;         // Proportion of employed persons who became not-employed

    @Column(name = "NotEmpToEmp")
    private double labNotEmpToEmpShare;         // Proportion of not-employed persons who became employed

    @Column(name = "PropEmployed")
    private double labEmpShare;

    @Column(name = "PropUnemployed")
    private double labUnempShare;


    public double getEmpToNotEmp() {
        return labEmpToNotEmpShare;
    }

    public void setEmpToNotEmp(double empToNotEmp) {
        this.labEmpToNotEmpShare = empToNotEmp;
    }

    public double getNotEmpToEmp() {
        return labNotEmpToEmpShare;
    }

    public void setNotEmpToEmp(double notEmpToEmp) {
        this.labNotEmpToEmpShare = notEmpToEmp;
    }

    public double getPropEmployed() {
        return labEmpShare;
    }

    public void setPropEmployed(double propEmployed) {
        this.labEmpShare = propEmployed;
    }

    public double getPropUnemployed() {
        return labUnempShare;
    }

    public void setPropUnemployed(double propUnemployed) {
        this.labUnempShare = propUnemployed;
    }

    public void update(SimPathsModel model) {

        EmploymentHistoryFilter employedLastPeriod = new EmploymentHistoryFilter(Les_c4.EmployedOrSelfEmployed);
        EmploymentHistoryFilter notEmployedLastPeriod = new EmploymentHistoryFilter(Les_c4.NotEmployed);

        // Entering employment transition rate: among those NE last period, share that are E now
        CrossSection.Integer personsNotEmpToEmp = new CrossSection.Integer(model.getPersons(), Person.class, "getEmployed", true);
        personsNotEmpToEmp.setFilter(notEmployedLastPeriod);
        // Entering not-employed transition rate: among those E last period, share that are NE now
        CrossSection.Integer personsEmpToNotEmp = new CrossSection.Integer(model.getPersons(), Person.class, "getNonwork", true);
        personsEmpToNotEmp.setFilter(employedLastPeriod);

        MeanArrayFunction notEmpToEmpFn = new MeanArrayFunction(personsNotEmpToEmp);
        notEmpToEmpFn.applyFunction();
        setNotEmpToEmp(notEmpToEmpFn.getDoubleValue(IDoubleSource.Variables.Default));

        MeanArrayFunction empToNotEmpFn = new MeanArrayFunction(personsEmpToNotEmp);
        empToNotEmpFn.applyFunction();
        setEmpToNotEmp(empToNotEmpFn.getDoubleValue(IDoubleSource.Variables.Default));

        // Working-age adults (16-64) employment and unemployment proportions
        AgeGroupCSfilter workingAgeFilter = new AgeGroupCSfilter(16, 64);

        CrossSection.Integer personsEmployed = new CrossSection.Integer(model.getPersons(), Person.class, "getEmployed", true);
        CrossSection.Integer personsUnemployed = new CrossSection.Integer(model.getPersons(), Person.class, "getNonwork", true);

        personsEmployed.setFilter(workingAgeFilter);
        personsUnemployed.setFilter(workingAgeFilter);

        MeanArrayFunction isEmployed = new MeanArrayFunction(personsEmployed);
        isEmployed.applyFunction();
        setPropEmployed(isEmployed.getDoubleValue(IDoubleSource.Variables.Default));

        MeanArrayFunction isUnemployed = new MeanArrayFunction(personsUnemployed);
        isUnemployed.applyFunction();
        setPropUnemployed(isUnemployed.getDoubleValue(IDoubleSource.Variables.Default));
    }
}
