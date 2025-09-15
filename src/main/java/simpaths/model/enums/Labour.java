package simpaths.model.enums;

import microsim.statistics.regression.IntegerValuedEnum;
import simpaths.data.Parameters;
import simpaths.model.Person;

import java.util.Objects;

import static simpaths.data.Parameters.COUNTRY_STRING;

public enum Labour implements IntegerValuedEnum {
    //int categoryId, int femaleMin, int femaleMax, int maleMin, int maleMax
    ZERO(0, 0, 0, 0, 0),  // 0 hours for both genders

    //EL
    CATEGORY_EL_1(1, 1, 39,   1, 39),   // [1-39]
    CATEGORY_EL_2(2, 40, 40,  40, 40),  // [40]
    CATEGORY_EL_3(3, 41, Parameters.MAX_LABOUR_HOURS_IN_WEEK,  41, Parameters.MAX_LABOUR_HOURS_IN_WEEK),  // [41+]

    //IT
    CATEGORY_IT_1(1, 1, 29,   1, 35),   // [1-29] vs [1-35]
    CATEGORY_IT_2(2, 30, 35,  36, 39),  // [30-35] vs [36-39]
    CATEGORY_IT_3(3, 36, 39,  40, 49),  // [36-39] vs [40-49]
    CATEGORY_IT_4(4, 40, 55, 50, 65), // [40+] vs [50+]

    //PL; same as EL
    CATEGORY_PL_1(1, 1, 39, 1, 39),  //sub categoryId 20 to 1
    CATEGORY_PL_2(2, 40, 40, 40, 40),
    CATEGORY_PL_3(3, 41, Parameters.MAX_LABOUR_HOURS_IN_WEEK, 41, Parameters.MAX_LABOUR_HOURS_IN_WEEK),

    //HU; same as EL
    CATEGORY_HU_1(1, 1, 39, 1, 39),
    CATEGORY_HU_2(2, 40, 40, 40, 40),
    CATEGORY_HU_3(3, 41, Parameters.MAX_LABOUR_HOURS_IN_WEEK, 41, Parameters.MAX_LABOUR_HOURS_IN_WEEK);


    private final int categoryId;
    private final int femaleMin, femaleMax;
    private final int maleMin, maleMax;

    Labour(int categoryId, int femaleMin, int femaleMax, int maleMin, int maleMax) {
        this.categoryId = categoryId;
        this.femaleMin = femaleMin;
        this.femaleMax = femaleMax;
        this.maleMin = maleMin;
        this.maleMax = maleMax;
    }

    @Override
    public int getValue() {
        return categoryId;  // Now returns category ID instead of hours
    }

    // Gender-aware conversion methods
    public static Labour convertHoursToLabour(double hoursWorked, Gender gender) {
        if (hoursWorked <= 0) return ZERO;

        return switch (gender) {
            case Female -> convertFemaleHours(hoursWorked);
            default -> convertMaleHours(hoursWorked);
        };
    }

    private static Labour convertFemaleHours(double hours) {
        if (Objects.equals(COUNTRY_STRING, "EL")) {
            if (hours <= 39) return CATEGORY_EL_1;
            else if (hours <= 40) return CATEGORY_EL_2;
            else return CATEGORY_EL_3;
        }
        else if (Objects.equals(COUNTRY_STRING, "IT")) {
            if (hours <= 29) return CATEGORY_IT_1;
            else if (hours <= 35) return CATEGORY_IT_2;
            else if (hours <= 39) return CATEGORY_IT_3;
            else return CATEGORY_IT_4;
        }
        else if (Objects.equals(COUNTRY_STRING, "PL")) {
            if (hours <= 39) return CATEGORY_PL_1;
            else if (hours <= 40) return CATEGORY_PL_2;
            else return CATEGORY_PL_3;
        }
        else if (Objects.equals(COUNTRY_STRING, "HU")) {
            if (hours <= 39) return CATEGORY_HU_1;
            else if (hours <= 40) return CATEGORY_HU_2;
            else return CATEGORY_HU_3;
        }
        else {
            throw new IllegalArgumentException("Country not recognized: " + COUNTRY_STRING);
        }
    }


    private static Labour convertMaleHours(double hours) {
        if (Objects.equals(COUNTRY_STRING, "EL")) {
            if (hours <= 39) return CATEGORY_EL_1;
            else if (hours <= 40) return CATEGORY_EL_2;
            else return CATEGORY_EL_3;
        }
        else if (Objects.equals(COUNTRY_STRING, "IT")) {
            if (hours <= 35) return CATEGORY_IT_1;
            else if (hours <= 39) return CATEGORY_IT_2;
            else if (hours <= 49) return CATEGORY_IT_3;
            else return CATEGORY_IT_4;
        }
        if (Objects.equals(COUNTRY_STRING, "PL")) {
            if (hours <= 39) return CATEGORY_PL_1;
            else if (hours <= 40) return CATEGORY_PL_2;
            else return CATEGORY_PL_3;
        }
        if (Objects.equals(COUNTRY_STRING, "HU")) {
            if (hours <= 39) return CATEGORY_HU_1;
            else if (hours <= 40) return CATEGORY_HU_2;
            else return CATEGORY_HU_3;
        }
        else {
            throw new IllegalArgumentException("Country not recognized: " + COUNTRY_STRING);
        }
    }

    public int getHours(Person person) {
        if (this == ZERO) return 0;

        Gender gender = person.getDgn();
        if (Parameters.USE_CONTINUOUS_LABOUR_SUPPLY_HOURS && person != null) {

            int min = (gender == Gender.Female) ? femaleMin : maleMin;
            int max = (gender == Gender.Female) ? femaleMax : maleMax;

            double draw = person.getLabourSupplySingleDraw();
            return (int) Math.round(draw * (max - min) + min);
        } else {
            // Return midpoint for discrete mode
            return (gender == Gender.Female) ?
                    (femaleMin + femaleMax) / 2 :
                    (maleMin + maleMax) / 2;
        }
    }
}
