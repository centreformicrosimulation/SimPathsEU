package simpaths.data.statistics;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import microsim.data.db.PanelEntityKey;
import simpaths.data.Parameters;
import simpaths.data.filters.FertileFilter;
import simpaths.model.BenefitUnit;
import simpaths.model.Person;
import simpaths.model.SimPathsModel;
import simpaths.model.enums.Dcpst;
import simpaths.model.enums.Indicator;
import simpaths.model.enums.Les_c4;
import simpaths.model.enums.Occupancy;
import simpaths.model.enums.OccupancyExtended;
import simpaths.model.enums.TargetShares;
import simpaths.model.enums.TimeSeriesVariable;

import java.util.Map;

@Entity
public class AlignmentAdjustmentFactors {

    @Id
    private PanelEntityKey key = new PanelEntityKey(1L);

    @Column(name = "partnership_adj_factor")
    private double partnershipAdjustmentFactor;

    @Column(name = "share_cohabiting_sim")
    private double shareCohabitingSimulated;

    @Column(name = "share_cohabiting_tgt")
    private double shareCohabitingTarget;

    @Column(name = "fertility_adj_factor")
    private double fertilityAdjustmentFactor;

    @Column(name = "fertiilty_rate_sim")
    private double fertilityRateSimulated;

    @Column(name = "fertiilty_rate_tgt")
    private double fertilityRateTarget;

    @Column(name = "retirement_adj_factor")
    private double retirementAdjustmentFactor;

    @Column(name = "disability_adj_factor")
    private double disabilityAdjustmentFactor;

    @Column(name = "retirement_share_sim")
    private double retirementShareSimulated;

    @Column(name = "retirement_share_tgt")
    private double retirementShareTarget;

    @Column(name = "disability_share_sim")
    private double disabilityShareSimulated;

    @Column(name = "disability_share_tgt")
    private double disabilityShareTarget;

    @Column(name = "in_school_adj_factor")
    private double inSchoolAdjustmentFactor;

    @Column(name = "in_school_share_sim")
    private double inSchoolShareSimulated;

    @Column(name = "in_school_share_tgt")
    private double inSchoolShareTarget;

    @Column(name = "utility_adj_factor_smales")
    private double utilityAdjustmentFactorSmales;

    @Column(name = "utility_adj_factor_sfemales")
    private double utilityAdjustmentFactorSfemales;

    @Column(name = "utility_adj_factor_couples")
    private double utilityAdjustmentFactorCouples;

    @Column(name = "utility_adj_factor_ac_male")
    private double utilityAdjustmentFactorACMale;

    @Column(name = "utility_adj_factor_ac_female")
    private double utilityAdjustmentFactorACFemale;

    @Column(name = "utility_adj_factor_male_with_dep")
    private double utilityAdjustmentFactorMaleWithDep;

    @Column(name = "utility_adj_factor_female_with_dep")
    private double utilityAdjustmentFactorFemaleWithDep;

    @Column(name = "employed_share_sim_smales")
    private double employedShareSimSingleMales;

    @Column(name = "employed_share_tgt_smales")
    private double employedShareTgtSingleMales;

    @Column(name = "employed_share_sim_sfemales")
    private double employedShareSimSingleFemales;

    @Column(name = "employed_share_tgt_sfemales")
    private double employedShareTgtSingleFemales;

    @Column(name = "employed_share_sim_couples")
    private double employedShareSimCouples;

    @Column(name = "employed_share_tgt_couples")
    private double employedShareTgtCouples;

    @Column(name = "employed_share_sim_ac_male")
    private double employedShareSimACMale;

    @Column(name = "employed_share_tgt_ac_male")
    private double employedShareTgtACMale;

    @Column(name = "employed_share_sim_ac_female")
    private double employedShareSimACFemale;

    @Column(name = "employed_share_tgt_ac_female")
    private double employedShareTgtACFemale;

    @Column(name = "employed_share_sim_male_with_dep")
    private double employedShareSimMaleWithDep;

    @Column(name = "employed_share_tgt_male_with_dep")
    private double employedShareTgtMaleWithDep;

    @Column(name = "employed_share_sim_female_with_dep")
    private double employedShareSimFemaleWithDep;

    @Column(name = "employed_share_tgt_female_with_dep")
    private double employedShareTgtFemaleWithDep;

    public double getPartnershipAdjustmentFactor() {
        return partnershipAdjustmentFactor;
    }

    public void setPartnershipAdjustmentFactor(double partnershipAdjustmentFactor) {
        this.partnershipAdjustmentFactor = partnershipAdjustmentFactor;
    }

    public double getFertilityAdjustmentFactor() {
        return fertilityAdjustmentFactor;
    }

    public void setFertilityAdjustmentFactor(double factor) {
        this.fertilityAdjustmentFactor = factor;
    }

    public double getRetirementAdjustmentFactor() {
        return retirementAdjustmentFactor;
    }

    public void setRetirementAdjustmentFactor(double retirementAdjustmentFactor) {
        this.retirementAdjustmentFactor = retirementAdjustmentFactor;
    }

    public double getDisabilityAdjustmentFactor() {
        return disabilityAdjustmentFactor;
    }

    public void setDisabilityAdjustmentFactor(double disabilityAdjustmentFactor) {
        this.disabilityAdjustmentFactor = disabilityAdjustmentFactor;
    }

    public double getInSchoolAdjustmentFactor() {
        return inSchoolAdjustmentFactor;
    }

    public void setInSchoolAdjustmentFactor(double inSchoolAdjustmentFactor) {
        this.inSchoolAdjustmentFactor = inSchoolAdjustmentFactor;
    }

    public double getRetirementShareSimulated() { return retirementShareSimulated; }

    public void setRetirementShareSimulated(double retirementShareSimulated) { this.retirementShareSimulated = retirementShareSimulated; }

    public double getRetirementShareTarget() { return retirementShareTarget; }

    public void setRetirementShareTarget(double retirementShareTarget) { this.retirementShareTarget = retirementShareTarget; }

    public double getDisabilityShareSimulated() { return disabilityShareSimulated; }

    public void setDisabilityShareSimulated(double disabilityShareSimulated) { this.disabilityShareSimulated = disabilityShareSimulated; }

    public double getDisabilityShareTarget() { return disabilityShareTarget; }

    public void setDisabilityShareTarget(double disabilityShareTarget) { this.disabilityShareTarget = disabilityShareTarget; }

    public double getInSchoolShareSimulated() { return inSchoolShareSimulated; }

    public void setInSchoolShareSimulated(double inSchoolShareSimulated) { this.inSchoolShareSimulated = inSchoolShareSimulated; }

    public double getInSchoolShareTarget() { return inSchoolShareTarget; }

    public void setInSchoolShareTarget(double inSchoolShareTarget) { this.inSchoolShareTarget = inSchoolShareTarget; }

    public double getUtilityAdjustmentFactorSmales() {
        return utilityAdjustmentFactorSmales;
    }

    public void setUtilityAdjustmentFactorSmales(double utilityAdjustmentFactorSmales) {
        this.utilityAdjustmentFactorSmales = utilityAdjustmentFactorSmales;
    }

    public double getUtilityAdjustmentFactorSfemales() {
        return utilityAdjustmentFactorSfemales;
    }

    public void setUtilityAdjustmentFactorSfemales(double utilityAdjustmentFactorSfemales) {
        this.utilityAdjustmentFactorSfemales = utilityAdjustmentFactorSfemales;
    }

    public double getUtilityAdjustmentFactorCouples() {
        return utilityAdjustmentFactorCouples;
    }

    public double getUtilityAdjustmentFactorACMale() {
        return utilityAdjustmentFactorACMale;
    }

    public double getUtilityAdjustmentFactorACFemale() {
        return utilityAdjustmentFactorACFemale;
    }

    public double getUtilityAdjustmentFactorMaleWithDep() {
        return utilityAdjustmentFactorMaleWithDep;
    }

    public double getUtilityAdjustmentFactorFemaleWithDep() {
        return utilityAdjustmentFactorFemaleWithDep;
    }

    public void setUtilityAdjustmentFactorCouples(double utilityAdjustmentFactorCouples) {
        this.utilityAdjustmentFactorCouples = utilityAdjustmentFactorCouples;
    }

    public void setUtilityAdjustmentFactorACMale(double utilityAdjustmentFactorACMale) {
        this.utilityAdjustmentFactorACMale = utilityAdjustmentFactorACMale;
    }

    public void setUtilityAdjustmentFactorACFemale(double utilityAdjustmentFactorACFemale) {
        this.utilityAdjustmentFactorACFemale = utilityAdjustmentFactorACFemale;
    }

    public void setUtilityAdjustmentFactorMaleWithDep(double utilityAdjustmentFactorMaleWithDep) {
        this.utilityAdjustmentFactorMaleWithDep = utilityAdjustmentFactorMaleWithDep;
    }

    public void setUtilityAdjustmentFactorFemaleWithDep(double utilityAdjustmentFactorFemaleWithDep) {
        this.utilityAdjustmentFactorFemaleWithDep = utilityAdjustmentFactorFemaleWithDep;
    }

    public double getShareCohabitingSimulated() {return shareCohabitingSimulated;}

    public void setShareCohabitingSimulated(double shareCohabitingSimulated) { this.shareCohabitingSimulated = shareCohabitingSimulated; }

    public double getFertilityRateSimulated() {
        return fertilityRateSimulated;
    }

    public void setFertilityRateSimulated(double fertilityRateSimulated) {
        this.fertilityRateSimulated = fertilityRateSimulated;
    }

    public double getFertilityRateTarget() {
        return fertilityRateTarget;
    }

    public void setFertilityRateTarget(double fertilityRateTarget) {
        this.fertilityRateTarget = fertilityRateTarget;
    }

    public double getShareCohabitingTarget() {
        return shareCohabitingTarget;
    }

    public void setShareCohabitingTarget(double shareCohabitingTarget) {
        this.shareCohabitingTarget = shareCohabitingTarget;
    }

    // employed share getters/setters
    public double getEmployedShareSimSingleMales() { return employedShareSimSingleMales; }
    public void setEmployedShareSimSingleMales(double v) { this.employedShareSimSingleMales = v; }
    public double getEmployedShareTgtSingleMales() { return employedShareTgtSingleMales; }
    public void setEmployedShareTgtSingleMales(double v) { this.employedShareTgtSingleMales = v; }

    public double getEmployedShareSimSingleFemales() { return employedShareSimSingleFemales; }
    public void setEmployedShareSimSingleFemales(double v) { this.employedShareSimSingleFemales = v; }
    public double getEmployedShareTgtSingleFemales() { return employedShareTgtSingleFemales; }
    public void setEmployedShareTgtSingleFemales(double v) { this.employedShareTgtSingleFemales = v; }

    public double getEmployedShareSimCouples() { return employedShareSimCouples; }
    public void setEmployedShareSimCouples(double v) { this.employedShareSimCouples = v; }
    public double getEmployedShareTgtCouples() { return employedShareTgtCouples; }
    public void setEmployedShareTgtCouples(double v) { this.employedShareTgtCouples = v; }

    public double getEmployedShareSimACMale() { return employedShareSimACMale; }
    public void setEmployedShareSimACMale(double v) { this.employedShareSimACMale = v; }
    public double getEmployedShareTgtACMale() { return employedShareTgtACMale; }
    public void setEmployedShareTgtACMale(double v) { this.employedShareTgtACMale = v; }

    public double getEmployedShareSimACFemale() { return employedShareSimACFemale; }
    public void setEmployedShareSimACFemale(double v) { this.employedShareSimACFemale = v; }
    public double getEmployedShareTgtACFemale() { return employedShareTgtACFemale; }
    public void setEmployedShareTgtACFemale(double v) { this.employedShareTgtACFemale = v; }

    public double getEmployedShareSimMaleWithDep() { return employedShareSimMaleWithDep; }
    public void setEmployedShareSimMaleWithDep(double v) { this.employedShareSimMaleWithDep = v; }
    public double getEmployedShareTgtMaleWithDep() { return employedShareTgtMaleWithDep; }
    public void setEmployedShareTgtMaleWithDep(double v) { this.employedShareTgtMaleWithDep = v; }

    public double getEmployedShareSimFemaleWithDep() { return employedShareSimFemaleWithDep; }
    public void setEmployedShareSimFemaleWithDep(double v) { this.employedShareSimFemaleWithDep = v; }
    public double getEmployedShareTgtFemaleWithDep() { return employedShareTgtFemaleWithDep; }
    public void setEmployedShareTgtFemaleWithDep(double v) { this.employedShareTgtFemaleWithDep = v; }

    public void update(SimPathsModel model) {

        // The collector fires AFTER the model's yearlySchedule (ordering 1 > 0),
        // and UpdateYear (year++) is the last step in that schedule.
        // So model.getYear() here is already the NEXT year.
        // Use model.getYear()-1 to read the year that was just processed.
        int processedYear = model.getYear() - 1;

        // cohabitation
        double val = model.getPartnershipAdjustment(processedYear);
        setPartnershipAdjustmentFactor(val);
        long numPersonsWhoCanHavePartner = model.getPersons().stream()
                .filter(person -> person.getDag() >= Parameters.MIN_AGE_COHABITATION)
                .count();
        long numPersonsPartnered = model.getPersons().stream()
                .filter(person -> (person.getDcpst().equals(Dcpst.Partnered)))
                .count();
        val = (numPersonsWhoCanHavePartner > 0) ? (double) numPersonsPartnered / numPersonsWhoCanHavePartner : 0.0;
        setShareCohabitingSimulated(val);
        setShareCohabitingTarget(Parameters.getTargetShare(processedYear, TargetShares.Partnership));

        // fertility
        val = model.getFertilityAdjustment(processedYear);
        setFertilityAdjustmentFactor(val);
        FertileFilter filter = new FertileFilter();
        long numFertilePersons = model.getPersons().stream()
                .filter(person -> filter.evaluate(person))
                .count();
        long numBirths = model.getPersons().stream()
                .filter(person -> (person.getDag() < 1))
                .count();
        val = (numFertilePersons > 0) ? (double) numBirths / numFertilePersons : 0.0;
        setFertilityRateSimulated(val);
        setFertilityRateTarget(Parameters.getFertilityRateByYear(processedYear));

        // retirement
        setRetirementAdjustmentFactor(model.getRetirementAdjustment(processedYear));
        long numWithLes = model.getPersons().stream()
                .filter(person -> person.getLes_c4() != null)
                .count();
        long numRetired = model.getPersons().stream()
                .filter(person -> Les_c4.Retired.equals(person.getLes_c4()))
                .count();
        val = (numWithLes > 0) ? (double) numRetired / numWithLes : 0.0;
        setRetirementShareSimulated(val);
        setRetirementShareTarget(Parameters.getTargetShare(processedYear, TargetShares.Retirement));

        // disability
        setDisabilityAdjustmentFactor(model.getDisabilityAdjustment(processedYear));
        long numWithDlltsd = model.getPersons().stream()
                .filter(person -> person.getDlltsd() != null)
                .count();
        long numDisabled = model.getPersons().stream()
                .filter(person -> Indicator.True.equals(person.getDlltsd()))
                .count();
        val = (numWithDlltsd > 0) ? (double) numDisabled / numWithDlltsd : 0.0;
        setDisabilityShareSimulated(val);
        setDisabilityShareTarget(Parameters.getTargetShare(processedYear, TargetShares.Disability));

        // inSchool
        setInSchoolAdjustmentFactor(model.getInSchoolAdjustment(processedYear));
        long numPersonsInAgeRange = model.getPersons().stream()
                .filter(person -> person.getDag() >= 16 && person.getDag() <= 29 && person.getLes_c4() != null)
                .count();
        long numStudents = model.getPersons().stream()
                .filter(person -> person.getDag() >= 16 && person.getDag() <= 29
                        && person.getLes_c4() != null
                        && Les_c4.Student.equals(person.getLes_c4()))
                .count();
        val = (numPersonsInAgeRange > 0) ? (double) numStudents / numPersonsInAgeRange : 0.0;
        setInSchoolShareSimulated(val);
        setInSchoolShareTarget(Parameters.getTargetShare(processedYear, TargetShares.Students));

        // utility — maps may be null if time_series_factor.xlsx sheets are absent
        setUtilityAdjustmentFactorSmales(safeGetTimeSeriesValue(processedYear, TimeSeriesVariable.UtilityAdjustmentSingleMales));
        setUtilityAdjustmentFactorSfemales(safeGetTimeSeriesValue(processedYear, TimeSeriesVariable.UtilityAdjustmentSingleFemales));
        setUtilityAdjustmentFactorCouples(safeGetTimeSeriesValue(processedYear, TimeSeriesVariable.UtilityAdjustmentCouples));
        setUtilityAdjustmentFactorACMale(safeGetTimeSeriesValue(processedYear, TimeSeriesVariable.UtilityAdjustmentACMales));
        setUtilityAdjustmentFactorACFemale(safeGetTimeSeriesValue(processedYear, TimeSeriesVariable.UtilityAdjustmentACFemales));
        setUtilityAdjustmentFactorMaleWithDep(safeGetTimeSeriesValue(processedYear, TimeSeriesVariable.UtilityAdjustmentMaleWithDep));
        setUtilityAdjustmentFactorFemaleWithDep(safeGetTimeSeriesValue(processedYear, TimeSeriesVariable.UtilityAdjustmentFemaleWithDep));

        // employment shares by occupancy type
        // accumulate counts and fractional employment in a single pass over benefit units
        Map<OccupancyExtended, double[]> empStats = new java.util.EnumMap<>(OccupancyExtended.class);
        for (OccupancyExtended occ : OccupancyExtended.values()) {
            empStats.put(occ, new double[2]); // [0] = count, [1] = sum of fracEmployed
        }
        for (BenefitUnit bu : model.getBenefitUnits()) {
            OccupancyExtended ext = classifyBenefitUnit(bu);
            if (ext != null) {
                double[] stats = empStats.get(ext);
                stats[0]++;
                stats[1] += bu.fracEmployed();
            }
        }
        setEmployedShareSimSingleMales(computeShare(empStats.get(OccupancyExtended.Single_Male)));
        setEmployedShareTgtSingleMales(Parameters.getTargetShare(processedYear, TargetShares.EmploymentSingleMales));
        setEmployedShareSimSingleFemales(computeShare(empStats.get(OccupancyExtended.Single_Female)));
        setEmployedShareTgtSingleFemales(Parameters.getTargetShare(processedYear, TargetShares.EmploymentSingleFemales));
        setEmployedShareSimCouples(computeShare(empStats.get(OccupancyExtended.Couple)));
        setEmployedShareTgtCouples(Parameters.getTargetShare(processedYear, TargetShares.EmploymentCouples));
        setEmployedShareSimACMale(computeShare(empStats.get(OccupancyExtended.Male_AC)));
        setEmployedShareTgtACMale(Parameters.getTargetShare(processedYear, TargetShares.EmploymentMaleAdultChildren));
        setEmployedShareSimACFemale(computeShare(empStats.get(OccupancyExtended.Female_AC)));
        setEmployedShareTgtACFemale(Parameters.getTargetShare(processedYear, TargetShares.EmploymentFemaleAdultChildren));
        setEmployedShareSimMaleWithDep(computeShare(empStats.get(OccupancyExtended.Male_With_Dependent)));
        setEmployedShareTgtMaleWithDep(Parameters.getTargetShare(processedYear, TargetShares.EmploymentMaleWithDependent));
        setEmployedShareSimFemaleWithDep(computeShare(empStats.get(OccupancyExtended.Female_With_Dependent)));
        setEmployedShareTgtFemaleWithDep(Parameters.getTargetShare(processedYear, TargetShares.EmploymentFemaleWithDependent));

    }

    /**
     * Classifies a BenefitUnit into an OccupancyExtended subgroup.
     * Mirrors the matchesSubgroup logic used in ActivityAlignmentV2.
     * Returns null if the unit does not fall into any at-risk-of-work subgroup.
     */
    private static OccupancyExtended classifyBenefitUnit(BenefitUnit bu) {
        Occupancy occ = bu.getOccupancy();
        Person male = bu.getMale();
        Person female = bu.getFemale();
        boolean maleAtRisk = (male != null) && male.atRiskOfWork();
        boolean femaleAtRisk = (female != null) && female.atRiskOfWork();

        if (occ == Occupancy.Couple) {
            if (maleAtRisk && femaleAtRisk) return OccupancyExtended.Couple;
            if (maleAtRisk) return OccupancyExtended.Male_With_Dependent;
            if (femaleAtRisk) return OccupancyExtended.Female_With_Dependent;
            return null;
        } else if (occ == Occupancy.Single_Male && male != null) {
            return (male.getAdultChildFlag() == 1) ? OccupancyExtended.Male_AC : OccupancyExtended.Single_Male;
        } else if (occ == Occupancy.Single_Female && female != null) {
            return (female.getAdultChildFlag() == 1) ? OccupancyExtended.Female_AC : OccupancyExtended.Single_Female;
        }
        return null;
    }

    private static double computeShare(double[] stats) {
        return (stats[0] > 0) ? stats[1] / stats[0] : 0.0;
    }

    /**
     * Safely reads a time series value, returning 0.0 if the underlying map is null
     * (e.g. when the corresponding sheet is absent from time_series_factor.xlsx).
     */
    private static final java.util.Set<TimeSeriesVariable> reportedMissing = java.util.EnumSet.noneOf(TimeSeriesVariable.class);

    private static double safeGetTimeSeriesValue(int year, TimeSeriesVariable variable) {
        try {
            return Parameters.getTimeSeriesValue(year, variable);
        } catch (NullPointerException e) {
            if (reportedMissing.add(variable)) {
                System.out.println("WARNING: time series map for " + variable + " is null — "
                        + "corresponding sheet is missing from time_series_factor.xlsx. Defaulting to 0.0.");
            }
            return 0.0;
        }
    }
}
