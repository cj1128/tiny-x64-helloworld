ENTRY(nomain)

SECTIONS
{
  . = 0x8048000 + SIZEOF_HEADERS;

  tiny : { *(.text) *(.data) *(.rodata*) }

  /DISCARD/ : { *(*) }
}
