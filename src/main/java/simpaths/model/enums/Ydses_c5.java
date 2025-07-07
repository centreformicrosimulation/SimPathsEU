package simpaths.model.enums;
import microsim.statistics.regression.IntegerValuedEnum;

public enum Ydses_c5 implements IntegerValuedEnum {
	Q1(1),	//This is the baseline (omitted) in the health status regression for example.
	Q2(2),
	Q3(3),
	Q4(4),
	Q5(5),
	;

	private final int value;

	Ydses_c5(int val) {value = val;}

	@Override
	public int getValue() {
		return value;
	}
}
