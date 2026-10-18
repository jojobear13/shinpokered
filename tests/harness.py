"""Emulator test harness for calling game routines directly.

Boots a built ROM in PyBoy, keeps a snapshot of the booted machine, and lets a
test write inputs into RAM by symbol name, call any routine by symbol, and read
the results back. Interrupts are disabled while a routine runs, and Random can
be replaced by a queue of chosen values, so calls are deterministic and do not
depend on how many cycles the code takes.
"""

import io
import os
import sys

# PyBoy prints an SDL notice on import; keep test output clean
os.environ.setdefault("PYSDL2_DLL_PATH", "")
import warnings

warnings.filterwarnings("ignore")
from pyboy import PyBoy  # noqa: E402

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_ROM = os.path.join(REPO_ROOT, "pokered.gbc")

# Harness scratch space at the bottom of the stack section ($df00-$dfff).
# The game's stack starts at $dfff and grows down; the harness checks that its
# code is still intact after every call.
LAUNCHER = 0xDF00  # bank switch + call + restore + spin loop
RANDOM_STUB = 0xDF18  # replacement for Random that reads RANDOM_QUEUE
RANDOM_INDEX = 0xDF2F
RANDOM_QUEUE = 0xDF30  # up to 64 queued values
RANDOM_QUEUE_LEN = 64
HARNESS_END = 0xDF70

H_LOADEDROMBANK = 0xFFB8
H_JOY_PRESSED = 0xFFB3
H_JOY_HELD = 0xFFB4
H_JOY_5 = 0xFFB5
A_AND_B_BUTTONS = 0x03
MBC_ROM_BANK = 0x2000
REG_IE = 0xFFFF

WRAM = (0xC000, 0xDF00)  # everything below the stack section
HRAM = (0xFF80, 0xFFFF)


class HarnessError(Exception):
    pass


def load_symbols(sym_path):
    symbols = {}
    with open(sym_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith(";"):
                continue
            addr, name = line.split()[:2]
            bank, offset = addr.split(":")
            symbols[name] = (int(bank, 16), int(offset, 16))
    return symbols


class Game:
    """A booted ROM that routines can be called on.

    Each call to reset() restores the booted snapshot, so tests do not leak
    state into one another.
    """

    def __init__(self, rom_path=None, sym_path=None):
        self.rom_path = rom_path or os.environ.get("SHIN_ROM", DEFAULT_ROM)
        self.sym_path = sym_path or os.path.splitext(self.rom_path)[0] + ".sym"
        if not os.path.exists(self.rom_path):
            raise HarnessError(
                f"ROM not found: {self.rom_path}\n"
                "Build it first (make red) or set SHIN_ROM to a built ROM."
            )
        self.symbols = load_symbols(self.sym_path)
        self.pyboy = PyBoy(self.rom_path, window="null", sound_emulated=False)
        self.pyboy.set_emulation_speed(0)
        self.memory = self.pyboy.memory
        self.regs = self.pyboy.register_file
        self._patches = []  # (bank, addr, original bytes), undone by reset()
        self._random_patched = False
        self._boot()

    # ------------------------------------------------------------------ setup

    def _boot(self):
        """Run until the game is initialised and find a snapshot the harness
        can safely take control from."""
        self.pyboy.tick(200)
        for _ in range(60):
            snapshot = io.BytesIO()
            self.pyboy.save_state(snapshot)
            self._snapshot = snapshot.getvalue()
            try:
                self.reset()
                result = self.call("AddNTimes", a=3, bc=7, hl=0x100)
            except HarnessError:
                result = None
            if result is not None and result["hl"] == 0x115:
                self.reset()
                return
            self._load_snapshot()
            self.pyboy.tick(1)
        raise HarnessError("could not find a usable boot snapshot")

    def _load_snapshot(self):
        self.pyboy.load_state(io.BytesIO(self._snapshot))

    def reset(self):
        """Restore the booted machine and reinstall the harness code."""
        self._load_snapshot()
        self.unpatch_all()
        self._random_patched = False
        self._random_queue = []
        for addr in range(LAUNCHER, HARNESS_END):
            self.memory[addr] = 0

    # ---------------------------------------------------------------- symbols

    def addr(self, name):
        try:
            return self.symbols[name][1]
        except KeyError:
            raise HarnessError(f"unknown symbol: {name}") from None

    def bank(self, name):
        return self.symbols[name][0]

    def _resolve(self, where):
        if isinstance(where, int):
            return where
        name, _, offset = where.partition("+")
        return self.addr(name) + (int(offset, 0) if offset else 0)

    # ----------------------------------------------------------------- memory

    def peek(self, where, length=1):
        base = self._resolve(where)
        if length == 1:
            return self.memory[base]
        return [self.memory[base + i] for i in range(length)]

    def poke(self, where, *values):
        base = self._resolve(where)
        for i, value in enumerate(values):
            self.memory[base + i] = value & 0xFF

    def peek16(self, where):
        """Read a big-endian 16-bit value (the game's usual byte order)."""
        hi, lo = self.peek(where, 2)
        return hi << 8 | lo

    def poke16(self, where, value):
        self.poke(where, value >> 8, value)

    def snapshot_ram(self):
        """WRAM below the stack section plus HRAM, for whole-state diffs."""
        wram = bytes(self.memory[a] for a in range(*WRAM))
        hram = bytes(self.memory[a] for a in range(*HRAM))
        return wram + hram

    # ------------------------------------------------------------ ROM patches

    def patch(self, where, *values):
        """Overwrite ROM bytes at a symbol (or a (bank, addr) pair). Undone by
        reset(), since ROM patches are not part of the saved snapshot."""
        bank, addr = self.symbols[where] if isinstance(where, str) else where
        original = [self.memory[bank, addr + i] for i in range(len(values))]
        self._patches.append((bank, addr, original))
        for i, value in enumerate(values):
            self.memory[bank, addr + i] = value & 0xFF

    def unpatch_all(self):
        for bank, addr, original in reversed(self._patches):
            for i, value in enumerate(original):
                self.memory[bank, addr + i] = value
        self._patches = []

    def skip_sound_waits(self):
        """Make WaitForSoundToFinish return at once. Sound only advances in
        the V-blank interrupt, which is off while a routine runs."""
        self.patch("WaitForSoundToFinish", 0xC9)  # ret

    def skip_delays(self):
        """Make DelayFrame return at once, so routines that animate (HP bars,
        sliding pictures) can run with interrupts off. Everything they write
        to RAM, including the tile map, is unaffected."""
        self.patch("DelayFrame", 0xC9)  # ret

    def auto_buttons(self):
        """Make Joypad report A and B held and newly pressed on every call, so
        text boxes print instantly and don't wait for the player."""
        self.patch(
            "Joypad",
            0x3E, A_AND_B_BUTTONS,  # ld a, A_BUTTON | B_BUTTON
            0xE0, H_JOY_PRESSED & 0xFF,  # ldh [hJoyPressed], a
            0xE0, H_JOY_HELD & 0xFF,  # ldh [hJoyHeld], a
            0xE0, H_JOY_5 & 0xFF,  # ldh [hJoy5], a
            0xC9,  # ret
        )

    # ----------------------------------------------------------------- random

    def queue_random(self, *values):
        """Make the next calls to Random return these values, in order.

        Once the queue is exhausted the call fails, so a test always knows
        exactly how much randomness a routine consumed.
        """
        if len(self._random_queue) + len(values) > RANDOM_QUEUE_LEN:
            raise HarnessError("random queue is full")
        self._random_queue.extend(v & 0xFF for v in values)
        self._patch_random()
        self._install_random_stub()

    def _patch_random(self):
        if self._random_patched:
            return
        self.patch("Random", 0xC3, RANDOM_STUB & 0xFF, RANDOM_STUB >> 8)  # jp RANDOM_STUB
        self._random_patched = True

    def _install_random_stub(self):
        # push hl / ld hl, RANDOM_INDEX / ld a, [hl] / (spin if exhausted)
        # inc [hl] / add RANDOM_QUEUE low byte / ld l, a / ld a, [hl] / pop hl / ret
        # When the queue runs out the stub spins forever, which call()
        # reports as an error.
        stub = [
            0xE5,
            0x21, RANDOM_INDEX & 0xFF, RANDOM_INDEX >> 8,
            0x7E,
            0xFE, len(self._random_queue),  # cp queue length
            0x28, 0xFE,  # jr z, @ (queue exhausted: spin)
            0x34,
            0xC6, RANDOM_QUEUE & 0xFF,
            0x6F,
            0x7E,
            0xE1,
            0xC9,
        ]
        assert RANDOM_STUB + len(stub) <= RANDOM_INDEX
        for i, b in enumerate(stub):
            self.memory[RANDOM_STUB + i] = b
        # the read position (RANDOM_INDEX) is zeroed by reset() and only
        # advanced by the stub, so values queued later append to the queue
        for i, v in enumerate(self._random_queue):
            self.memory[RANDOM_QUEUE + i] = v

    def random_used(self):
        """How many queued random values the last call consumed."""
        return self.memory[RANDOM_INDEX]

    # ------------------------------------------------------------------- call

    def call(self, name, a=0, f=0, bc=0, de=0, hl=0, max_frames=300):
        """Call a routine by symbol and return the registers it left behind.

        The routine runs with interrupts off, from a launcher that switches to
        the routine's ROM bank first and restores the previous bank after.
        """
        bank, addr = self.symbols[name] if isinstance(name, str) else name
        old_bank = self.memory[H_LOADEDROMBANK]
        launch_bank = bank if bank else old_bank
        launcher = [
            0xF3,  # di
            0x3E, launch_bank,  # ld a, bank
            0xEA, MBC_ROM_BANK & 0xFF, MBC_ROM_BANK >> 8,  # ld [MBC1RomBank], a
            0xE0, H_LOADEDROMBANK & 0xFF,  # ldh [H_LOADEDROMBANK], a
            0xF1,  # pop af (caller's a and f, pushed below)
            0xCD, addr & 0xFF, addr >> 8,  # call routine
            0xF5,  # push af
            0x3E, old_bank,  # ld a, old bank
            0xEA, MBC_ROM_BANK & 0xFF, MBC_ROM_BANK >> 8,
            0xE0, H_LOADEDROMBANK & 0xFF,
            0x18, 0xFE,  # jr @ (done)
        ]
        done = LAUNCHER + len(launcher) - 2
        assert done < RANDOM_STUB
        for i, b in enumerate(launcher):
            self.memory[LAUNCHER + i] = b
        expected = [self.memory[LAUNCHER + i] for i in range(len(launcher))]
        harness_area = [self.memory[a] for a in range(RANDOM_STUB, HARNESS_END)]

        self.memory[REG_IE] = 0
        # a and f go through the stack so the launcher's bank switch
        # doesn't clobber them
        sp = self.regs.SP - 2
        self.memory[sp] = f & 0xF0
        self.memory[sp + 1] = a & 0xFF
        self.regs.SP = sp
        self.regs.B, self.regs.C = bc >> 8, bc & 0xFF
        self.regs.D, self.regs.E = de >> 8, de & 0xFF
        self.regs.HL = hl & 0xFFFF
        self.regs.PC = LAUNCHER

        for _ in range(max_frames):
            self.pyboy.tick(1, False)
            if self.regs.PC in (done, done + 1):
                break
        else:
            if RANDOM_STUB <= self.regs.PC < RANDOM_INDEX:
                raise HarnessError(f"{name} used more random values than were queued")
            raise HarnessError(
                f"{name} did not return within {max_frames} frames "
                f"(PC={self.regs.PC:#06x})"
            )

        if [self.memory[LAUNCHER + i] for i in range(len(launcher))] != expected:
            raise HarnessError(f"{name} overwrote the harness launcher")
        current = [self.memory[a] for a in range(RANDOM_STUB, HARNESS_END)]
        index = RANDOM_INDEX - RANDOM_STUB
        if current[:index] + current[index + 1:] != harness_area[:index] + harness_area[index + 1:]:
            raise HarnessError(f"{name} overwrote the harness's random queue (stack too deep?)")

        # the routine's a and f were pushed by the launcher
        sp = self.regs.SP
        f_out = self.memory[sp]
        a_out = self.memory[sp + 1]
        self.regs.SP = sp + 2
        return {
            "a": a_out,
            "f": f_out,
            "z": bool(f_out & 0x80),
            "carry": bool(f_out & 0x10),
            "b": self.regs.B,
            "c": self.regs.C,
            "d": self.regs.D,
            "e": self.regs.E,
            "bc": self.regs.B << 8 | self.regs.C,
            "de": self.regs.D << 8 | self.regs.E,
            "hl": self.regs.HL,
        }


_shared = None


def shared_game():
    """One booted Game per process; reset() it between tests."""
    global _shared
    if _shared is None:
        _shared = Game()
    return _shared


if __name__ == "__main__":
    game = Game(*sys.argv[1:2])
    print("booted", game.rom_path)
    print(game.call("AddNTimes", a=3, bc=7, hl=0x100))
