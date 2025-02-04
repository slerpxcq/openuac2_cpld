#include "fx2.h"
#include "fx2regs.h"

extern BOOL GotFeedbackValue;

void ISR_INT1(void) interrupt INT1_VECT
{
	GotFeedbackValue = TRUE;
}