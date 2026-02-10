package simpaths.model.enums;

import microsim.statistics.regression.IntegerValuedEnum;

public enum Education implements IntegerValuedEnum {

	// Semantic ladder: NotAssigned < Low < Medium < High //used in `ordinal()`
	NotAssigned(0),
	Low(1),
	Medium(2),
	High(3);

	private final int value;
	Education(int val) {value=val;}

	@Override
	public int getValue() {return value;}
	public static Education getCode(int val) {
		switch (val) {
			case 0:
				return NotAssigned;
			case 1:
				return Low;
			case 2:
				return Medium;
			case 3:
				return High;
			default:
				throw new IllegalArgumentException("Invalid Education code: " + val + " (expected 0–3)");
		}
	}
}
