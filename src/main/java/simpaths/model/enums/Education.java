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

	// Rank for comparing highest qualification; NotAssigned is treated as below Low.
	public int getRank() {
		switch (this) {
			case High:
				return 3;
			case Medium:
				return 2;
			case Low:
				return 1;
			case NotAssigned:
				return 0;
			default:
				return -1;
		}
	}
}
