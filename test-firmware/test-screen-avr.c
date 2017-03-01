
#include <inttypes.h>
#include <avr/io.h>
#include <util/delay.h>

/* https://www.arduino.cc/en/Hacking/PinMapping168 */
#define DPIN0		PD0
#define DPIN1		PD1
#define DPIN2		PD2
#define DPIN3		PD3
#define DPIN4		PD4
#define DPIN5		PD5
#define DPIN6		PD6
#define DPIN7		PD7
#define DPIN8		PB0
#define DPIN9		PB1
#define DPIN10		PB2
#define DPIN11		PB3
#define DPIN12		PB4
#define DPIN13		PB5

#define LEDPIN		DPIN13

#define OEPIN		DPIN12
#define LATPIN		DPIN11
#define CLKPIN		DPIN10

#define A0PIN		DPIN2
#define A1PIN		DPIN3
#define A2PIN		DPIN4
#define AMASK		(_BV(A0PIN) | _BV(A1PIN) | _BV(A2PIN))

#define R1PIN		DPIN5
#define G1PIN		DPIN6
#define B1PIN		DPIN7
#define RGB1MASK	(_BV(R1PIN) | _BV(G1PIN) | _BV(B1PIN))

void write_row(uint8_t row)
{
	uint8_t bitclock = 0;

	/* Pull OE high */
	PORTB |= _BV(OEPIN);

	/* set row */
	PORTD = (PORTD & ~AMASK) | (row << A0PIN);

	bitclock = 32;
	while(bitclock--)
	{
		PORTD = (PORTD & ~RGB1MASK) | ((bitclock << R1PIN) & RGB1MASK);

		PORTB |= _BV(CLKPIN);
		asm("nop");
		asm("nop");
		asm("nop");
		PORTB &= ~_BV(CLKPIN);
		asm("nop");
		asm("nop");
		asm("nop");
	}

	/* latch */
	PORTB |= _BV(LATPIN);
	asm("nop");
	asm("nop");
	asm("nop");
	PORTB &= ~_BV(LATPIN);

	/* Pull OE low */
	PORTB &= ~_BV(OEPIN);
}

int main(void)
{
	uint8_t row = 0;

	PORTB = 0;
	PORTD = 0;
	DDRB |= _BV(OEPIN) | _BV(LATPIN) | _BV(CLKPIN) | _BV(LEDPIN);
	DDRD |= AMASK | RGB1MASK;

	PORTB &= ~_BV(LEDPIN);

	while (1)
	{
		row = 8;
		while(row--)
		{
			write_row(row);
		}
		/*_delay_ms(10);*/
	}

	return 0;
}


