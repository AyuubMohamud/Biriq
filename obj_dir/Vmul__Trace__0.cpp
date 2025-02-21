// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vmul__Syms.h"


void Vmul___024root__trace_chg_0_sub_0(Vmul___024root* vlSelf, VerilatedVcd::Buffer* bufp);

void Vmul___024root__trace_chg_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmul___024root__trace_chg_0\n"); );
    // Init
    Vmul___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vmul___024root*>(voidSelf);
    Vmul__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    Vmul___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void Vmul___024root__trace_chg_0_sub_0(Vmul___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmul___024root__trace_chg_0_sub_0\n"); );
    Vmul__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    if (VL_UNLIKELY((vlSelfRef.__Vm_traceActivity[1U]))) {
        bufp->chgWData(oldp+0,(vlSelfRef.mul__DOT__result),66);
    }
    bufp->chgIData(oldp+3,(vlSelfRef.a),32);
    bufp->chgIData(oldp+4,(vlSelfRef.b),32);
    bufp->chgCData(oldp+5,(vlSelfRef.op),2);
    bufp->chgIData(oldp+6,(vlSelfRef.res),32);
    bufp->chgQData(oldp+7,((((QData)((IData)(((2U != (IData)(vlSelfRef.op)) 
                                              & (vlSelfRef.a 
                                                 >> 0x1fU)))) 
                             << 0x20U) | (QData)((IData)(vlSelfRef.a)))),33);
    bufp->chgQData(oldp+9,((((QData)((IData)(((~ ((IData)(vlSelfRef.op) 
                                                  >> 1U)) 
                                              & (vlSelfRef.b 
                                                 >> 0x1fU)))) 
                             << 0x20U) | (QData)((IData)(vlSelfRef.b)))),33);
}

void Vmul___024root__trace_cleanup(void* voidSelf, VerilatedVcd* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmul___024root__trace_cleanup\n"); );
    // Init
    Vmul___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vmul___024root*>(voidSelf);
    Vmul__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    vlSymsp->__Vm_activity = false;
    vlSymsp->TOP.__Vm_traceActivity[0U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[1U] = 0U;
}
