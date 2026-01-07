import os
import pytest
from pathlib import Path
from cocotb.runner import get_runner

# Percorsi relativi
PROJ_ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = PROJ_ROOT / "src/systemverilog"

# Lista dei moduli da testare
@pytest.mark.parametrize("unit", ["pe", "systolic"])
def test_regression(unit):
    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)

    sources = list((PROJ_ROOT / "src/systemverilog").rglob("*.sv"))
    # 1. Compilazione: punta a src/ per i sorgenti SV
    runner.build(
        verilog_sources=sources,
        hdl_toplevel=unit,
        build_dir=PROJ_ROOT / "sim_build", # Cartella di build dedicata
        always=True
    )

    # 2. Esecuzione: punta alla cartella test/ per i moduli Python
    runner.test(
        hdl_toplevel=unit,
        test_module=f"test_{unit}", # Cerca test_alu.py o test_fifo.py
    )