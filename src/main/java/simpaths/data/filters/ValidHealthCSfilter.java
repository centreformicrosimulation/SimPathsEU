package simpaths.data.filters;

import microsim.statistics.ICollectionFilter;
import simpaths.model.Person;

public class ValidHealthCSfilter implements ICollectionFilter {

	public boolean isFiltered(Object object) {
		if (object instanceof Person) {
			Person person = (Person) object;
			return person.getDhe() != null;
		}
		else throw new IllegalArgumentException("Object passed to ValidHealthCSfilter must be of type Person!");
	}
}
