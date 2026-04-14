#include "led.h"

#include "driver/gpio.h"

static bool s_led_on;

static int led_level(bool on) {
  if (APP_LED_ACTIVE_HIGH) {
    return on ? 1 : 0;
  }

  return on ? 0 : 1;
}

void led_init(void) {
  gpio_num_t gpio = (gpio_num_t)APP_LED_GPIO;

  gpio_reset_pin(gpio);
  gpio_set_direction(gpio, GPIO_MODE_OUTPUT);
  led_set(false);
}

void led_set(bool on) {
  s_led_on = on;
  gpio_set_level((gpio_num_t)APP_LED_GPIO, led_level(on));
}

bool led_toggle(void) {
  led_set(!s_led_on);
  return s_led_on;
}
