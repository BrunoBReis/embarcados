#pragma once

#include <stdbool.h>

#ifndef APP_LED_GPIO
#define APP_LED_GPIO 2
#endif

#ifndef APP_LED_ACTIVE_HIGH
#define APP_LED_ACTIVE_HIGH 1
#endif

void led_init(void);
void led_set(bool on);
bool led_toggle(void);
