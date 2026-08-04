# Kernel: Hardware Supplements

- MMIO: `readl()` / `writel()` / `ioread32()` / `iowrite32()` for
  register access; raw variants `__raw_readl()` etc. skip barriers
- DMA: `dma_map_single()` / `dma_unmap_single()` must be paired;
  direction must be correct (`DMA_TO_DEVICE`, `DMA_FROM_DEVICE`, etc.)
- Memory barriers: `mb()`, `rmb()`, `wmb()`, `smp_mb()`, `smp_rmb()`,
  `smp_wmb()`, `dma_wmb()`
- Endianness: `cpu_to_le32()` / `le32_to_cpu()` / `cpu_to_be16()` etc.
- IRQ: `request_irq()` / `free_irq()` must be paired; `IRQF_SHARED`
  handlers must check if the device actually raised the interrupt
- Clock/power: enable clocks before register access, disable in reverse
  order during shutdown
