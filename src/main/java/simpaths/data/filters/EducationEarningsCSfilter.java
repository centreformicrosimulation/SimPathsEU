package simpaths.data.filters;

import microsim.statistics.ICollectionFilter;
import simpaths.model.Person;
import simpaths.model.enums.Education;

public class EducationEarningsCSfilter implements ICollectionFilter {

	private Education education;

	public EducationEarningsCSfilter(Education education) {
		super();
		this.education = education;
	}

	public boolean isFiltered(Object object) {
		if (object instanceof Person) {
			Person person = (Person) object;
			return (person.getDeh_c4().equals(education) &&
					person.getGrossEarningsYearly() >= 0.);
		}
		else throw new IllegalArgumentException("Object passed to EducationEarningsCSfilter must be of type Person!");
	}
}
