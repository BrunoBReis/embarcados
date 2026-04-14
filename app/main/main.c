#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include <stdio.h>

#include "led.h"

void app_main(void) {
  led_init();

  while (1) {
    bool led_on = led_toggle();
    printf("LED %s\n", led_on ? "aceso" : "apagado");
    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}
