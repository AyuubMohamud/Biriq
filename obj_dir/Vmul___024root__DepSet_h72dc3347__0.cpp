// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vmul.h for the primary calling header

#include "Vmul__pch.h"
#include "Vmul___024root.h"

void Vmul___024root___ico_sequent__TOP__0(Vmul___024root* vlSelf);

void Vmul___024root___eval_ico(Vmul___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmul___024root___eval_ico\n"); );
    Vmul__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        Vmul___024root___ico_sequent__TOP__0(vlSelf);
        vlSelfRef.__Vm_traceActivity[1U] = 1U;
    }
}

VL_INLINE_OPT void Vmul___024root___ico_sequent__TOP__0(Vmul___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmul___024root___ico_sequent__TOP__0\n"); );
    Vmul__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlWide<3>/*95:0*/ __Vtemp_3;
    VlWide<3>/*95:0*/ __Vtemp_4;
    VlWide<3>/*95:0*/ __Vtemp_6;
    VlWide<3>/*95:0*/ __Vtemp_7;
    VlWide<3>/*95:0*/ __Vtemp_8;
    // Body
    VL_EXTENDS_WQ(66,33, __Vtemp_3, (((QData)((IData)(
                                                      ((2U 
                                                        != (IData)(vlSelfRef.op)) 
                                                       & (vlSelfRef.a 
                                                          >> 0x1fU)))) 
                                      << 0x20U) | (QData)((IData)(vlSelfRef.a))));
    __Vtemp_4[0U] = __Vtemp_3[0U];
    __Vtemp_4[1U] = __Vtemp_3[1U];
    __Vtemp_4[2U] = (3U & __Vtemp_3[2U]);
    VL_EXTENDS_WQ(66,33, __Vtemp_6, (((QData)((IData)(
                                                      ((~ 
                                                        ((IData)(vlSelfRef.op) 
                                                         >> 1U)) 
                                                       & (vlSelfRef.b 
                                                          >> 0x1fU)))) 
                                      << 0x20U) | (QData)((IData)(vlSelfRef.b))));
    __Vtemp_7[0U] = __Vtemp_6[0U];
    __Vtemp_7[1U] = __Vtemp_6[1U];
    __Vtemp_7[2U] = (3U & __Vtemp_6[2U]);
    VL_MULS_WWW(66, __Vtemp_8, __Vtemp_4, __Vtemp_7);
    vlSelfRef.mul__DOT__result[0U] = __Vtemp_8[0U];
    vlSelfRef.mul__DOT__result[1U] = __Vtemp_8[1U];
    vlSelfRef.mul__DOT__result[2U] = (3U & __Vtemp_8[2U]);
    vlSelfRef.res = ((0U == (IData)(vlSelfRef.op)) ? 
                     vlSelfRef.mul__DOT__result[0U]
                      : vlSelfRef.mul__DOT__result[1U]);
}

void Vmul___024root___eval_triggers__ico(Vmul___024root* vlSelf);

bool Vmul___024root___eval_phase__ico(Vmul___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmul___024root___eval_phase__ico\n"); );
    Vmul__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vmul___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelfRef.__VicoTriggered.any();
    if (__VicoExecute) {
        Vmul___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vmul___024root___eval_act(Vmul___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmul___024root___eval_act\n"); );
    Vmul__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vmul___024root___eval_nba(Vmul___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmul___024root___eval_nba\n"); );
    Vmul__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vmul___024root___eval_triggers__act(Vmul___024root* vlSelf);

bool Vmul___024root___eval_phase__act(Vmul___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmul___024root___eval_phase__act\n"); );
    Vmul__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<0> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vmul___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vmul___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vmul___024root___eval_phase__nba(Vmul___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmul___024root___eval_phase__nba\n"); );
    Vmul__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vmul___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vmul___024root___dump_triggers__ico(Vmul___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vmul___024root___dump_triggers__nba(Vmul___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vmul___024root___dump_triggers__act(Vmul___024root* vlSelf);
#endif  // VL_DEBUG

void Vmul___024root___eval(Vmul___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmul___024root___eval\n"); );
    Vmul__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VicoIterCount;
    CData/*0:0*/ __VicoContinue;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VicoIterCount = 0U;
    vlSelfRef.__VicoFirstIteration = 1U;
    __VicoContinue = 1U;
    while (__VicoContinue) {
        if (VL_UNLIKELY(((0x64U < __VicoIterCount)))) {
#ifdef VL_DEBUG
            Vmul___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("rtl/mathSystem/mul.sv", 1, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vmul___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vmul___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("rtl/mathSystem/mul.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vmul___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("rtl/mathSystem/mul.sv", 1, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vmul___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vmul___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vmul___024root___eval_debug_assertions(Vmul___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vmul___024root___eval_debug_assertions\n"); );
    Vmul__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY(((vlSelfRef.op & 0xfcU)))) {
        Verilated::overWidthError("op");}
}
#endif  // VL_DEBUG
