package simpaths.data.filters;

import microsim.statistics.ICollectionFilter;
import simpaths.model.Person;
import simpaths.model.enums.Education;
import simpaths.model.enums.Les_c4;

public class EducationWorkingCSfilter implements ICollectionFilter {

	private Education education;

	public EducationWorkingCSfilter(Education education) {
		super();
		this.education = education;
	}

	public boolean isFiltered(Object object) {
		if (object instanceof Person) {
			Person person = (Person) object;
			return (person.getDeh_c4().equals(education) &&
					person.getLes_c4().equals(Les_c4.EmployedOrSelfEmployed) &&
					person.getGrossEarningsYearly() >= 1. &&
					person.getLabourSupplyHoursWeekly() > 0);
		}
		else throw new IllegalArgumentException("Object passed to EducationWorkingCSfilter must be of type Person!");
	}
}
