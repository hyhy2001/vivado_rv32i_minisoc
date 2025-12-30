import argparse
import struct
from dataclasses import dataclass


@dataclass(frozen=True)
class Elf32Phdr:
  p_type: int
  p_offset: int
  p_vaddr: int
  p_paddr: int
  p_filesz: int
  p_memsz: int
  p_flags: int
  p_align: int


def read_elf32_phdrs(data: bytes) -> list[Elf32Phdr]:
  if data[:4] != b"\x7fELF":
    raise ValueError("Not an ELF file")
  ei_class = data[4]
  ei_data = data[5]
  if ei_class != 1:
    raise ValueError("Expected ELF32")
  if ei_data != 1:
    raise ValueError("Expected little-endian")

  (e_type, e_machine, e_version, e_entry, e_phoff, e_shoff, e_flags, e_ehsize,
   e_phentsize, e_phnum, e_shentsize, e_shnum, e_shstrndx) = struct.unpack_from(
      "<HHIIIIIHHHHHH", data, 16
  )
  if e_phentsize != 32:
    raise ValueError(f"Unexpected e_phentsize={e_phentsize}")

  phdrs: list[Elf32Phdr] = []
  for i in range(e_phnum):
    off = e_phoff + i * e_phentsize
    (p_type, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_flags, p_align) = struct.unpack_from(
        "<IIIIIIII", data, off
    )
    phdrs.append(
        Elf32Phdr(
            p_type=p_type,
            p_offset=p_offset,
            p_vaddr=p_vaddr,
            p_paddr=p_paddr,
            p_filesz=p_filesz,
            p_memsz=p_memsz,
            p_flags=p_flags,
            p_align=p_align,
        )
    )
  return phdrs


def write_words_hex(path: str, mem: bytearray) -> None:
  if len(mem) % 4 != 0:
    mem.extend(b"\x00" * (4 - (len(mem) % 4)))
  with open(path, "w", encoding="utf-8") as f:
    for i in range(0, len(mem), 4):
      word = mem[i : i + 4]
      f.write(f"{word[3]:02x}{word[2]:02x}{word[1]:02x}{word[0]:02x}\n")


def main() -> None:
  ap = argparse.ArgumentParser()
  ap.add_argument("elf", help="input ELF32 (rv32) file")
  ap.add_argument("--rom-base", type=lambda x: int(x, 0), default=0x00000000)
  ap.add_argument("--rom-bytes", type=lambda x: int(x, 0), default=16 * 1024)
  ap.add_argument("--out", default="rom.hex")
  args = ap.parse_args()

  data = open(args.elf, "rb").read()
  phdrs = read_elf32_phdrs(data)

  rom = bytearray(b"\x00" * args.rom_bytes)

  PT_LOAD = 1
  for ph in phdrs:
    if ph.p_type != PT_LOAD or ph.p_filesz == 0:
      continue
    start = ph.p_paddr - args.rom_base
    end = start + ph.p_filesz
    if start < 0 or end > len(rom):
      raise ValueError(
          f"Segment out of ROM range: p_paddr=0x{ph.p_paddr:08x}, size={ph.p_filesz}"
      )
    rom[start:end] = data[ph.p_offset : ph.p_offset + ph.p_filesz]

  write_words_hex(args.out, rom)


if __name__ == "__main__":
  main()

