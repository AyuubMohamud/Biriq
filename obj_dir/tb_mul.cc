
#include "Vmul.h"
#include "verilated_vcd_c.h"
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <iostream>

vluint64_t simtime = 0;

int main() {
  Vmul *soc = new Vmul;
  char a_char[8] = {1, 0, 0, 0, 0, 1, 1, 0};
  Verilated::traceEverOn(true);
  VerilatedVcdC *m_trace = new VerilatedVcdC;
  soc->trace(m_trace, 15);
  m_trace->open("trace.vcd");

  soc->a = 0x7fffffff;
  soc->b = 0x7fffffff;
  soc->op = 0b00;

  soc->eval();

  printf("0x%08X\n", soc->res);
  m_trace->close();
  delete soc;
}