import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Timer

def to_fixed(val, frac_bits=8):
    return int(round(val * (1 << frac_bits))) & 0xFFFF

def from_fixed(val, frac_bits=8):
    if val >= (1 << 15):
        val -= (1 << 16)
    return float(val) / (1 << frac_bits)

@cocotb.test()
async def test_pe(dut):
    """Test the PE module with a variety of fixed-point inputs."""

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    await RisingEdge(dut.clk)

    # Reset
    dut.rst.value = 1
    
    dut.pe_psum_in.value = to_fixed(0.0)
    dut.pe_weight_in.value = to_fixed(0.0)
    dut.pe_accept_w_in.value = 0
    
    dut.pe_input_in.value = to_fixed(0.0)
    dut.pe_valid_in.value = 0
    dut.pe_switch_in.value = 0
    dut.pe_enabled.value = 0    

    await RisingEdge(dut.clk)
    await Timer(1, "ns")

    # Release reset
    dut.rst.value = 0
    dut.pe_enabled.value = 1
    dut.pe_accept_w_in.value = 1
    dut.pe_weight_in.value = to_fixed(4.34765625)
    await Timer(1, "ns")
    #Test #0
    assert dut.weight_reg_inactive.value == to_fixed(0.0), f"dut.weight_reg_inactive was {from_fixed(dut.weight_reg_inactive.value)}, expected 0.0"
    assert dut.pe_weight_out.value == to_fixed(0.0), f"dut.pe_weight_out was {from_fixed(dut.pe_weight_out.value)}, expected 0.0"
    
    await RisingEdge(dut.clk)
    await Timer(1, "ns")
    dut.pe_enabled.value = 1
    dut.pe_accept_w_in.value = 1
    dut.pe_weight_in.value = to_fixed(10.6015625)
    dut.pe_valid_in.value = 1
    dut.pe_input_in.value = to_fixed(2.0)
    dut.pe_switch_in.value = 1
    await Timer(1, "ns")
    #Test #1
    assert dut.weight_reg_inactive.value == to_fixed(4.34765625), f"dut.weight_reg_inactive was {from_fixed(dut.weight_reg_inactive.value)}, expected 4.34765625"
    assert dut.weight_reg_active.value == to_fixed(0.0), f"dut.weight_reg_active was {from_fixed(dut.weight_reg_active.value)}, expected 0.0"
    assert dut.pe_weight_out.value == to_fixed(4.34765625), f"dut.pe_weight_out was {from_fixed(dut.pe_weight_out.value)}, expected 4.34765625"
    
    await RisingEdge(dut.clk)
    await Timer(1, "ns")
    dut.pe_enabled.value = 1
    dut.pe_accept_w_in.value = 1
    dut.pe_weight_in.value = to_fixed(5.75)
    dut.pe_valid_in.value = 1
    dut.pe_input_in.value = to_fixed(-3.3984375)
    dut.pe_switch_in.value = 1
    await Timer(1, "ns")
    #Test #2
    assert dut.weight_reg_inactive.value == to_fixed(10.6015625), f"dut.weight_reg_inactive was {from_fixed(dut.weight_reg_inactive.value)}, expected 10.6015625"
    assert dut.weight_reg_active.value == to_fixed(4.34765625), f"dut.weight_reg_active was {from_fixed(dut.weight_reg_active.value)}, expected 4.34765625"
    assert dut.pe_weight_out.value == to_fixed(10.6015625), f"dut.pe_weight_out was {from_fixed(dut.pe_weight_out.value)}, expected 10.6015625"
    assert dut.pe_psum_out.value == to_fixed(0.0), f"dut.pe_psum_out was {from_fixed(dut.pe_psum_out.value)}, expected 0.0"
    assert dut.pe_input_out.value == to_fixed(2.0), f"dut.pe_input_out was {from_fixed(dut.pe_input_out.value)}, expected 2.0"
    
    await RisingEdge(dut.clk)
    await Timer(1, "ns")
    dut.pe_enabled.value = 1
    dut.pe_accept_w_in.value = 0
    dut.pe_weight_in.value = to_fixed(0.0)
    dut.pe_valid_in.value = 1
    dut.pe_input_in.value = to_fixed(19.359375)
    dut.pe_switch_in.value = 1
    await Timer(1, "ns")
    #Test #3
    assert dut.weight_reg_inactive.value == to_fixed(5.75), f"dut.weight_reg_inactive was {from_fixed(dut.weight_reg_inactive.value)}, expected 5.75"
    assert dut.weight_reg_active.value == to_fixed(10.6015625), f"dut.weight_reg_active was {from_fixed(dut.weight_reg_active.value)}, expected 10.6015625"
    assert dut.pe_weight_out.value == to_fixed(5.75), f"dut.pe_weight_out was {from_fixed(dut.pe_weight_out.value)}, expected 5.75"
    assert dut.pe_psum_out.value == to_fixed(8.6953125), f"dut.pe_psum_out was {from_fixed(dut.pe_psum_out.value)}, expected 8.6953125"
    assert dut.pe_input_out.value == to_fixed(-3.3984375), f"dut.pe_input_out was {from_fixed(dut.pe_input_out.value)}, expected -3.3984375"
    
    await RisingEdge(dut.clk)
    await Timer(1, "ns")
    dut.pe_enabled.value = 1
    dut.pe_accept_w_in.value = 0
    dut.pe_weight_in.value = to_fixed(0.0)
    dut.pe_valid_in.value = 0
    dut.pe_input_in.value = to_fixed(0)
    dut.pe_switch_in.value = 0
    await Timer(1, "ns")
    #Test #4
    assert dut.weight_reg_inactive.value == to_fixed(5.75), f"dut.weight_reg_inactive was {from_fixed(dut.weight_reg_inactive.value)}, expected 5.75"
    assert dut.weight_reg_active.value == to_fixed(5.75), f"dut.weight_reg_active was {from_fixed(dut.weight_reg_active.value)}, expected 5.75"
    assert dut.pe_weight_out.value == to_fixed(0.0), f"dut.pe_weight_out was {from_fixed(dut.pe_weight_out.value)}, expected 0.0"
    assert dut.pe_psum_out.value == to_fixed(-36.027344), f"dut.pe_psum_out was {from_fixed(dut.pe_psum_out.value)}, expected -36.027344"
    assert dut.pe_input_out.value == to_fixed(19.359375), f"dut.pe_input_out was {from_fixed(dut.pe_input_out.value)}, expected 19.359375"
        
    await RisingEdge(dut.clk)
    await Timer(1, "ns")
    dut.pe_enabled.value = 1
    dut.pe_accept_w_in.value = 0
    dut.pe_weight_in.value = to_fixed(0.0)
    dut.pe_valid_in.value = 0
    dut.pe_input_in.value = to_fixed(0)
    dut.pe_switch_in.value = 0
    await Timer(1, "ns")
    #Test #5
    assert dut.weight_reg_inactive.value == to_fixed(5.75), f"dut.weight_reg_inactive was {from_fixed(dut.weight_reg_inactive.value)}, expected 5.75"
    assert dut.weight_reg_active.value == to_fixed(5.75), f"dut.weight_reg_active was {from_fixed(dut.weight_reg_active.value)}, expected 5.75" 
    assert dut.pe_weight_out.value == to_fixed(0.0), f"dut.pe_weight_out was {from_fixed(dut.pe_weight_out.value)}, expected 0.0"
    assert dut.pe_psum_out.value == to_fixed(111.31640625), f"dut.pe_psum_out was {from_fixed(dut.pe_psum_out.value)}, expected 111.31640625"
    assert dut.pe_input_out.value == to_fixed(19.359375), f"dut.pe_input_out was {from_fixed(dut.pe_input_out.value)}, expected 19.359375"
    # End of test