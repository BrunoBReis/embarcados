#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include <stdio.h>

void app_main(void) {
  while (1) {
    printf("Ola, ESP32 via ESP-IDF!\n");
    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}
