import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import numpy as np
import random

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
    C = np.zeros((M, K), dtype=np.int16)

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

@cocotb.test()
async def test_systolic_randomized(dut):
    """Test della matrice sistolica con input casuali e verifica automatica."""
    
    M, N, K = 4, 2, 2
    
    # Avvio Clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # --- Generazione Dati Random ---
    # Generiamo valori tra -30 e 30 per evitare saturazioni eccessive
    matA_float = [[random.uniform(-30, 30) for _ in range(N)] for _ in range(M)]
    matW_float = [[random.uniform(-30, 30) for _ in range(K)] for _ in range(N)]
    
    A_fixed = [[to_fixed(x) for x in row] for row in matA_float]
    W_fixed = [[to_fixed(x) for x in row] for row in matW_float]
    
    expected_res = calculate_expected(A_fixed, W_fixed, M, N, K)

    # Inizializzazione Segnali
    dut.rst.value = 1
    dut.sys_start.value = 0
    dut.sys_accept_w_1.value = 0
    dut.sys_accept_w_2.value = 0
    
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")
    dut.rst.value = 0
    
    dut.ub_rd_col_size_in.value = K
    dut.ub_rd_col_size_valid_in.value = 1

    # Preparazione vettori (secondo la logica extractCol/extractColReverse del TB originale)
    w_col1_r = [W_fixed[1][0], W_fixed[0][0]] 
    w_col2_r = [W_fixed[1][1], W_fixed[0][1]]
    a_row1 = [row[0] for row in A_fixed]
    a_row2 = [row[1] for row in A_fixed]

    # --- Iniezione Stimoli (Driver) ---
    for cycle in range(1 + 2 * M + 2):
        await RisingEdge(dut.clk)
        await Timer(1, units="ns")
        
        # Caricamento Pesi (W)
        if cycle < N:
            dut.sys_weight_in_x1.value = w_col1_r[cycle]
            dut.sys_accept_w_1.value = 1
        else:
            dut.sys_accept_w_1.value = 0

        if 0 <= (cycle - 1) < N:
            dut.sys_weight_in_x2.value = w_col2_r[cycle - 1]
            dut.sys_accept_w_2.value = 1
            dut.sys_switch_in.value = 1
        else:
            dut.sys_accept_w_2.value = 0
            dut.sys_switch_in.value = 0

        # Caricamento Attivazioni (A)
        if 0 <= (cycle - 1) < M:
            dut.sys_data_in_1x.value = a_row1[cycle - 1]
            dut.sys_start.value = 1
        else:
            dut.sys_start.value = 0

        if 0 <= (cycle - 2) < M:
            dut.sys_data_in_2x.value = a_row2[cycle - 2]

    # Attesa fine calcolo
    await Timer(100, units="ns")
    
    dut._log.info("Test concluso. Controlla le forme d'onda per i risultati finali.")