import os
import importlib
from pathlib import Path
import cocotb
from cocotb.runner import get_runner
from cocotb.triggers import Timer, RisingEdge, FallingEdge, ReadOnly
from cocotb.utils import get_sim_time
from cocotb.clock import Clock
from cocotb.triggers import Edge
import numpy as np

CONFIG = {
    "hdl_toplevel": "systolic",
    "parameters": {"SYSTOLIC_ARRAY_WIDTH": 2}
}

# --- Utility per Virgola Fissa (Q8.8) ---
def to_fixed(val: float) -> int:
    """Converte un float in un intero signed 16-bit (Q8.8) compatibile con NumPy."""
    scaled = int(round(val * 256.0))
    val_16bit = scaled & 0xFFFF
    # Gestione del segno per evitare OverflowError in np.int16
    if val_16bit >= 0x8000:
        return val_16bit - 0x10000
    return val_16bit

def from_fixed(val: int) -> float:
    """Converte un intero 16-bit in float."""
    if val >= 0x8000:
        val -= 0x10000
    return val / 256.0

def calculate_expected(A_raw, W_raw, M, N, K):
    """Calcola il risultato atteso con la stessa precisione del pacchetto SV."""
    A = np.array(A_raw, dtype=np.int16)
    W = np.array(W_raw, dtype=np.int16)
    C = np.zeros((M, K), dtype=np.int32)

    for i in range(M):
        for j in range(K):
            acc = 0
            for k in range(N):
                # Moltiplicazione signed e arrotondamento ( +0x80 >> 8 )
                mult = int(A[i][k]) * int(W[k][j])
                mult_rounded = (mult + 0x80) >> 8
                acc = (acc + mult_rounded) & 0xFFFF
            if acc >= 0x8000: acc -= 0x10000
            C[i, j] = acc
    return C

def printMat(mat, M, N):
    for i in range(M):
        cocotb.log.info("".join(f"{from_fixed(mat[i][j]):8.4f} " for j in range(N)))
    cocotb.log.info("")

def printMatNp(mat, M, N):
    for i in range(M):
        cocotb.log.info("".join(f"{(mat[i][j]):8.4f} " for j in range(N)))
    cocotb.log.info("")
    
async def setup_dut(dut, K):
    """Inizializza i segnali e avvia il clock"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await RisingEdge(dut.clk)
    
    dut.rst.value = 1
    dut.sys_data_in.value = 0
    dut.sys_weight_in.value = 0
    dut.sys_accept_w.value = 0
    dut.sys_switch_in.value = 0
    dut.ub_rd_col_size_in.value = int(K)
    dut.ub_rd_col_size_valid_in.value = 1
    
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")
    dut.rst.value = 0

async def monitor_fixed_signal(sig):
    while True:
        await Edge(sig)
        cocotb.log.info(
            f"{sig._path} -> {from_fixed(int(sig.value))}"
        )    

@cocotb.test()
async def systolic_matrix_mul_test(dut):
    # assert False
    # Parametri
    WIDTH = dut.SYSTOLIC_ARRAY_WIDTH.value
    M, N, K = 2, 2, WIDTH
    
    assert K <= WIDTH, "K should be less than or equal to SYSTOLIC_ARRAY_WIDTH."
    assert N <= K, "N should be less than or equal to K for this test."
    
    # cocotb.log.info("SYSTOLIC_ARRAY_WIDTH: %d", dut.SYSTOLIC_ARRAY_WIDTH.value)
    
    # Generazione matrici random (Golden Model)
    matA = np.random.uniform(-5, 5, (M, N))
    matW = np.random.uniform(-10, 10, (N, K))
    
    # # Generazione matrici fisse per test deterministico
    # matA = np.zeros((M, N))
    # matW = np.zeros((N, K))
    
    # for row in range(M):
    #     for col in range(N):
    #         matA[row, col] = -(row * M + col)  # Valori fissi per A
    
    # for row in range(N):
    #     for col in range(K):
    #         matW[row, col] = (row * M + col) + 5 # Valori fissi per W
    
    
    # Calcola la matrice risultato non quantizzata per confronto
    matC = np.dot(matA, matW)
    
    # Calcolo risultato atteso (usando logica fixed point)
    # Nota: Per precisione estrema dovresti simulare il troncamento MAC
    matA_fixed = np.vectorize(to_fixed)(matA)
    matW_fixed = np.vectorize(to_fixed)(matW)
    
    # Estraggo le colonne di W in ordine inverso per il caricamento
    w_col_r = np.zeros((N, K), dtype=np.int16)
    for col in range(K):
        for row in range(N):
            w_col_r[row, col] = matW_fixed[(N - 1) - row, col]
        
    # print(w_col_r)
    # for row in range(N):
    #     for col in range(K):
    #         print(f"{from_fixed(w_col_r[row, col])} ", end="")
    #     print("")
    # Allocazione matrice risultato atteso
    expected_res = np.zeros((M, K), dtype=np.int16)
    expected_res = calculate_expected(matA_fixed, matW_fixed, M, N, K)
    
    cocotb.log.info("Matrice A (Input):")
    printMat(matA_fixed, M, N)
    
    cocotb.log.info("Matrice W (Weights):")
    printMat(matW_fixed, N, K)
    
    cocotb.log.info("Matrice C (Expected Result):")
    printMat(expected_res, M, K)
    
    cocotb.log.info("Matrice C (Floating Point Result):")
    printMatNp(matC, M, K)
    
    # Task per pilotare i segnali (sostituisce i blocchi generate)
    async def drive_inputs():
        # Configurazione iniziale
        dut.ub_rd_col_size_in.value = K
        dut.ub_rd_col_size_valid_in.value = 1
        
        # Simuliamo il ciclo di calcolo (cycle_count del tuo SV)
        total_cycles = M + 2*N + K + 10
        await RisingEdge(dut.rst)  
        await FallingEdge(dut.rst)
        await RisingEdge(dut.clk)
        
        cocotb.log.info(f"Inizio Drive Input @ {get_sim_time(units='ns')} ns")
        for cycle in range(total_cycles):
            
            # Logica Weights (Top side)
            weight_bus = 0
            accept_w = 0
            weightStr = ""
            for col in range(K):
                if col <= cycle < col + N:
                    val = int(w_col_r[cycle - col, col]) & 0xFFFF
                    weightStr += f"{from_fixed(val)} "
                    # val = w_col_r[cycle - col, col] & 0xFFFF
                    weight_bus |= (val << (16 * col))
                    accept_w |= (1 << col)
            
            # Logica Data (Left side)
            data_bus = 0
            dataStr = ""
            for row in range(WIDTH):
                # Traduzione della condizione SV: cycle_count >= (WIDTH-1) + row
                start_cycle = (WIDTH - 1) + row
                if start_cycle <= cycle < start_cycle + M:
                    val = int(matA_fixed[cycle - start_cycle, row]) & 0xFFFF
                    dataStr += f"{from_fixed(val)} "
                    data_bus |= (val << (16 * row))

            # # Debug: 
            # cocotb.log.info(f"Cycle {cycle}:")
            # cocotb.log.info(f"\tWeighs: {weightStr}")
            # cocotb.log.info(f"\tData: {dataStr}")
            
            # Switch e Start
            dut.sys_switch_in.value = 1 if cycle == (WIDTH - 1) else 0
            sys_start = 1 if (WIDTH - 1) <= cycle < (WIDTH - 1) + M else 0
            dut.sys_start.value = sys_start
            
            dut.sys_weight_in.value = int(weight_bus)
            dut.sys_accept_w.value = int(accept_w)
            dut.sys_data_in.value = int(data_bus)
            
            await RisingEdge(dut.clk)

    # Task per monitorare le uscite
    systolic_output = np.zeros((M, K), dtype=np.int32)
    async def monitor_outputs():
        await RisingEdge(dut.rst)  
        await FallingEdge(dut.rst)
        await RisingEdge(dut.clk)
        cocotb.log.info(f"Inizio Monitoraggio Uscite @ {get_sim_time(units='ns')} ns")
        for cycle in range(M + 2*N + K + 10):
            await ReadOnly() # Leggi dopo che i segnali si sono stabilizzati
            for col in range(K):
                # Condizione di cattura basata sul tuo SV: 2*N + col
                if 2*N + col <= cycle < 2*N + col + M:
                    row = cycle - (2*N + col)
                    # Estrai i 16 bit corrispondenti alla colonna
                    raw = ((int(dut.sys_data_out.value)) >> (16 * col)) & 0xFFFF
                    val = raw - 0x10000 if raw & 0x8000 else raw
                    systolic_output[row, col] = val
            await RisingEdge(dut.clk)
            
    # pe10 = (
    #     dut
    #     .pe_rows[1]
    #     .pe_cols[0]
    #     .genblk1
    #     .genblk1
    #     .pe_inst
    # ) 
    
    # Eseguiamo drive e monitor in parallelo
    drive_task = cocotb.start_soon(drive_inputs())
    monitor_task = cocotb.start_soon(monitor_outputs()) 
    # # Print PE(0,0) weight e data when they change 
    # monitor_pe10_task = cocotb.start_soon(monitor_fixed_signal(pe10.pe_psum_out))
    # monitor_pe11_task = cocotb.start_soon(monitor_fixed_signal(pe11.pe_psum_out))
    
    await setup_dut(dut, K)
    await monitor_task
    # await drive_task

    # Verifica Risultati
    cocotb.log.info("Verifica Matrice...")
    
    # --- Verifica Risultati (Monitor) ---
    for i in range(M):
        for j in range(K):
            dut_val = systolic_output[i][j]
            exp_val = expected_res[i][j]
            try:
                assert dut_val == exp_val, f"Mismatch at ({i},{j}): DUT={from_fixed(dut_val)}, EXP={from_fixed(exp_val)}" 
            except AssertionError as e:
                cocotb.log.error("Test Failed: Matrice C Mismatch - C was: ")
                for row in range(M):
                    cocotb.log.error("".join(f"{from_fixed(systolic_output[row][col]):8.4f} " for col in range(K)))
                raise e

## --- Test Runner per esecuzione standalone ---
def test_module():
    module_name = "test_systolic"
    mod = importlib.import_module(module_name)
    cfg = getattr(mod, "CONFIG", {})

    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)
    PROJ_ROOT = Path(__file__).resolve().parent.parent
    SRC_DIR = PROJ_ROOT / "src/systemverilog"
    sources = list(SRC_DIR.rglob("*.sv"))
    sources.append(PROJ_ROOT / "sim_build" / f"dump_systolic.sv")

    runner.build(
        sources=sources,
        hdl_toplevel=cfg["hdl_toplevel"],
        always=True,
        build_args=["-g2012", "-s", "dump"],
        parameters=cfg.get("parameters", {}),
    )

    runner.test(
        hdl_toplevel=cfg["hdl_toplevel"],
        test_module=module_name,
    )

if __name__ == "__main__":
    test_module()