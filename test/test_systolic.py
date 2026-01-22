import os
from pathlib import Path
from cocotb.runner import get_runner

PROJ_ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = PROJ_ROOT / "src/systemverilog"

def test_systolic_runner():
    # Scegli il simulatore (icarus, verilator, questasim, vcs, etc.)
    sim = os.getenv("SIM", "icarus")

    # Percorsi dei file
    proj_path = Path(__file__).resolve().parent
    sources = list((SRC_DIR).rglob("*.sv"))
    sources.append(PROJ_ROOT / "sim_build" / "dump_systolic.sv")  # Aggiungi il modulo di dump delle waveform

    # Configura il Runner
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="systolic",                # Nome del modulo Verilog top-level
        always=True,                            # Forza la ricompilazione
        build_args=["-g2012", "-s", "dump"],
        parameters={"SYSTOLIC_ARRAY_WIDTH": 2}  # Parametro Verilog
    )

    runner.test(
        hdl_toplevel="systolic",
        test_module="tb_systolic", # Il nome del file .py (senza .py)
        # testcase="systolic_matrix_mul_test", # La funzione specifica con @cocotb.test()
    )

if __name__ == "__main__":
    test_systolic_runner()