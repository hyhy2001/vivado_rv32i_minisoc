#include <stdint.h>

static inline void mmio_write8(uint32_t addr, uint8_t value) {
  *(volatile uint8_t *)addr = value;
}

static inline void mmio_write32(uint32_t addr, uint32_t value) {
  *(volatile uint32_t *)addr = value;
}

enum {
  UART_TX = 0x20000000u,
  TOHOST  = 0x20000004u,
};

int main(void) {
  const char *s = "Hello RV32I\n";
  for (; *s; s++) mmio_write8(UART_TX, (uint8_t)*s);
  mmio_write32(TOHOST, 1);
  return 0;
}
