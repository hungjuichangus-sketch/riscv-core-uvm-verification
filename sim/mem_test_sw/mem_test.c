// Small memory read/write smoke test, run against real Ibex RTL via
// dut/ibex/examples/simple_system (Verilator). Exercises word, byte, and
// halfword loads/stores (LW/SW, LB/SB, LH/SH -> data_be_o byte enables)
// plus a simple load-use hazard, for a first look at Ibex actually
// executing memory instructions before any testbench code is written.

#include "simple_system_common.h"

static volatile uint32_t mem_buf[4];

int main(void) {
  puts("Ibex memory read/write smoke test\n");

  // --- Word store/load (SW/LW) ---
  mem_buf[0] = 0xDEADBEEF;
  uint32_t word_read = mem_buf[0];
  puts("Word store/load: wrote 0xDEADBEEF, read back ");
  puthex(word_read);
  putchar('\n');
  if (word_read != 0xDEADBEEF) {
    puts("FAIL: word mismatch\n");
  }

  // --- Byte stores/loads (SB/LB) assembled into one word ---
  volatile uint8_t *byte_ptr = (volatile uint8_t *)&mem_buf[1];
  byte_ptr[0] = 0xAB;
  byte_ptr[1] = 0xCD;
  byte_ptr[2] = 0xEF;
  byte_ptr[3] = 0x12;
  uint32_t byte_read = mem_buf[1];
  puts("Four byte stores assembled word: ");
  puthex(byte_read);
  putchar('\n');
  if (byte_read != 0x12EFCDAB) {
    puts("FAIL: byte-enable assembly mismatch\n");
  }

  // --- Halfword stores/loads (SH/LH) assembled into one word ---
  volatile uint16_t *half_ptr = (volatile uint16_t *)&mem_buf[2];
  half_ptr[0] = 0x1234;
  half_ptr[1] = 0x5678;
  uint32_t half_read = mem_buf[2];
  puts("Two halfword stores assembled word: ");
  puthex(half_read);
  putchar('\n');
  if (half_read != 0x56781234) {
    puts("FAIL: halfword assembly mismatch\n");
  }

  // --- Load-use hazard: consume a loaded value on the very next op ---
  mem_buf[3] = 100;
  uint32_t loaded = mem_buf[3];
  uint32_t dependent = loaded + loaded;
  puts("Load-use hazard (100+100): ");
  puthex(dependent);
  putchar('\n');
  if (dependent != 200) {
    puts("FAIL: load-use hazard result wrong\n");
  } else {
    puts("PASS: load-use hazard result correct\n");
  }

  puts("Memory test complete\n");
  sim_halt();
  return 0;
}
