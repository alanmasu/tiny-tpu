import os
import pytest
import importlib
from pathlib import Path
from cocotb.runner import get_runner

# Percorsi relativi
PROJ_ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = PROJ_ROOT / "src/systemverilog"

UNITS = [
    "pe",
    "systolic"
]

@pytest.mark.parametrize("unit_name", UNITS)
def test_module(unit_name):
    print(f"Running tests for unit: {unit_name}")
    module_name = f"test_{unit_name}"
    mod = importlib.import_module(module_name)
    cfg = getattr(mod, "CONFIG", {})

    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)

    sources = list(SRC_DIR.rglob("*.sv"))
    # sources.append(PROJ_ROOT / "sim_build" / f"dump_{unit_name}.sv")

    runner.build(
        sources=sources,
        hdl_toplevel=cfg["hdl_toplevel"],
        always=True,
        parameters=cfg.get("parameters", {}),
    )

    runner.test(
        hdl_toplevel=cfg["hdl_toplevel"],
        test_module=module_name,
    )

if __name__ == "__main__":
    for unit in UNITS:
        test_module(unit)