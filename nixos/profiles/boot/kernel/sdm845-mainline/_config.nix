{ lib }:
let
  inherit (lib.kernel)
    yes
    no
    module
    freeform
    ;
in
{
  # Linux/arm64 6.16.0-rc2 Kernel Configuration

  ## General setup
  "COMPILE_TEST" = no; # Compile also drivers which will not load
  "WERROR" = no; # Compile the kernel with warnings as errors
  "LOCALVERSION" = freeform "-sdm845"; # Local version - append to kernel release
  "LOCALVERSION_AUTO" = yes; # Automatically append version information to the version string
  "KERNEL_GZIP" = yes; # Gzip
  "KERNEL_ZSTD" = no; # ZSTD
  "DEFAULT_HOSTNAME" = freeform "(none)"; # Default hostname
  "SYSVIPC" = yes; # System V IPC
  "POSIX_MQUEUE" = yes; # POSIX Message Queues
  "WATCH_QUEUE" = no; # General notification queue
  "CROSS_MEMORY_ATTACH" = yes; # Enable process_vm_readv/writev syscalls
  "AUDIT" = yes; # Auditing support

  ### General setup -> IRQ subsystem
  "GENERIC_IRQ_DEBUGFS" = no; # Expose irq internals in debugfs
  ### General setup: end of IRQ subsystem

  ### General setup -> Timers subsystem
  "HZ_PERIODIC" = no; # Periodic timer ticks (constant rate, no dynticks)
  "NO_HZ_IDLE" = yes; # Idle dynticks system (tickless idle)
  "NO_HZ_FULL" = no; # Full dynticks system (tickless)
  "NO_HZ" = no; # Old Idle dynticks config
  "HIGH_RES_TIMERS" = yes; # High Resolution Timer Support
  ### General setup: end of Timers subsystem

  ### General setup -> BPF subsystem
  "BPF_SYSCALL" = yes; # Enable bpf() system call
  "BPF_JIT" = yes; # Enable BPF Just In Time compiler
  "BPF_JIT_ALWAYS_ON" = no; # Permanently enable BPF JIT and remove BPF interpreter
  "BPF_UNPRIV_DEFAULT_OFF" = yes; # Disable unprivileged BPF by default
  "BPF_PRELOAD" = no; # Preload BPF file system with kernel specific program and map iterators
  "BPF_LSM" = no; # Enable BPF LSM Instrumentation
  ### General setup: end of BPF subsystem

  "PREEMPT_NONE" = no; # No Forced Preemption (Server)
  "PREEMPT_VOLUNTARY" = no; # Voluntary Kernel Preemption (Desktop)
  "PREEMPT" = yes; # Preemptible Kernel (Low-Latency Desktop)
  "PREEMPT_LAZY" = no; # Scheduler controlled preemption model
  "PREEMPT_DYNAMIC" = no; # Preemption behaviour defined on boot
  "SCHED_CORE" = no; # Core Scheduling for SMT

  ### General setup -> CPU/Task time and stats accounting
  "TICK_CPU_ACCOUNTING" = yes; # Simple tick based cputime accounting
  "VIRT_CPU_ACCOUNTING_GEN" = no; # Full dynticks CPU time accounting
  "IRQ_TIME_ACCOUNTING" = yes; # Fine granularity task level IRQ time accounting
  "BSD_PROCESS_ACCT" = yes; # BSD Process Accounting
  "BSD_PROCESS_ACCT_V3" = yes; # BSD Process Accounting version 3 file format
  "TASKSTATS" = yes; # Export task/process statistics through netlink
  "TASK_DELAY_ACCT" = no; # Enable per-task delay accounting
  "TASK_XACCT" = yes; # Enable extended accounting over taskstats
  "TASK_IO_ACCOUNTING" = yes; # Enable per-task storage I/O accounting
  "PSI" = yes; # Pressure stall information tracking
  "PSI_DEFAULT_DISABLED" = no; # Require boot parameter to enable pressure stall information tracking
  ### General setup: end of CPU/Task time and stats accounting

  "CPU_ISOLATION" = yes; # CPU isolation

  ### General setup -> RCU Subsystem
  "RCU_EXPERT" = no; # Make expert-level adjustments to RCU configuration
  ### General setup: end of RCU Subsystem

  "IKCONFIG" = yes; # Kernel .config support
  "IKCONFIG_PROC" = yes; # Enable access to .config through /proc/config.gz
  "IKHEADERS" = no; # Enable kernel headers through /sys/kernel/kheaders.tar.xz
  "LOG_BUF_SHIFT" = freeform "17"; # Kernel log buffer size (16 => 64KB, 17 => 128KB)
  "LOG_CPU_MAX_BUF_SHIFT" = freeform "12"; # CPU kernel log buffer size contribution (13 => 8 KB, 17 => 128KB)
  "PRINTK_INDEX" = no; # Printk indexing debugfs interface

  ### General setup -> Scheduler features
  "UCLAMP_TASK" = yes; # Enable utilization clamping for RT/FAIR tasks
  "UCLAMP_BUCKETS_COUNT" = freeform "5"; # Number of supported utilization clamp buckets
  ### General setup: end of Scheduler features

  "NUMA_BALANCING" = yes; # Memory placement aware NUMA scheduler
  "NUMA_BALANCING_DEFAULT_ENABLED" = yes; # Automatically enable NUMA aware memory/task placement
  "CGROUPS" = yes; # Control Group support
  "CGROUP_FAVOR_DYNMODS" = no; # Favor dynamic modification latency reduction by default
  "MEMCG" = yes; # Memory controller
  "MEMCG_V1" = no; # Legacy cgroup v1 memory controller
  "BLK_CGROUP" = yes; # IO controller
  "CGROUP_SCHED" = yes; # CPU controller
  "FAIR_GROUP_SCHED" = yes; # Group scheduling for SCHED_OTHER
  "CFS_BANDWIDTH" = yes; # CPU bandwidth provisioning for FAIR_GROUP_SCHED
  "RT_GROUP_SCHED" = no; # Group scheduling for SCHED_RR/FIFO
  "UCLAMP_TASK_GROUP" = yes; # Utilization clamping per group of tasks
  "CGROUP_PIDS" = yes; # PIDs controller
  "CGROUP_RDMA" = no; # RDMA controller
  "CGROUP_DMEM" = no; # Device memory controller (DMEM)
  "CGROUP_FREEZER" = yes; # Freezer controller
  "CGROUP_HUGETLB" = yes; # HugeTLB controller
  "CPUSETS" = yes; # Cpuset controller
  "CPUSETS_V1" = no; # Legacy cgroup v1 cpusets controller
  "CGROUP_DEVICE" = yes; # Device controller
  "CGROUP_CPUACCT" = yes; # Simple CPU accounting controller
  "CGROUP_PERF" = yes; # Perf controller
  "CGROUP_BPF" = yes; # Support for eBPF programs attached to cgroups
  "CGROUP_MISC" = no; # Misc resource controller
  "CGROUP_DEBUG" = no; # Debug controller
  "NAMESPACES" = yes; # Namespaces support
  "UTS_NS" = yes; # UTS namespace
  "TIME_NS" = yes; # TIME namespace
  "IPC_NS" = yes; # IPC namespace
  "USER_NS" = yes; # User namespace
  "PID_NS" = yes; # PID Namespaces
  "NET_NS" = yes; # Network namespace
  "CHECKPOINT_RESTORE" = yes; # Checkpoint/restore support
  "SCHED_AUTOGROUP" = yes; # Automatic process group scheduling
  "RELAY" = yes; # Kernel->user space relay support (formerly relayfs)
  "BLK_DEV_INITRD" = yes; # Initial RAM filesystem and RAM disk (initramfs/initrd) support
  "RD_GZIP" = yes; # Support initial ramdisk/ramfs compressed using gzip
  "RD_BZIP2" = yes; # Support initial ramdisk/ramfs compressed using bzip2
  "RD_LZMA" = yes; # Support initial ramdisk/ramfs compressed using LZMA
  "RD_XZ" = yes; # Support initial ramdisk/ramfs compressed using XZ
  "RD_LZO" = yes; # Support initial ramdisk/ramfs compressed using LZO
  "RD_LZ4" = yes; # Support initial ramdisk/ramfs compressed using LZ4
  "RD_ZSTD" = yes; # Support initial ramdisk/ramfs compressed using ZSTD
  "BOOT_CONFIG" = no; # Boot config support
  "INITRAMFS_PRESERVE_MTIME" = yes; # Preserve cpio archive mtimes in initramfs
  "CC_OPTIMIZE_FOR_PERFORMANCE" = yes; # Optimize for performance (-O2)
  "CC_OPTIMIZE_FOR_SIZE" = no; # Optimize for size (-Os)
  "SYSFS_SYSCALL" = no; # Sysfs syscall support
  "EXPERT" = no; # Configure standard kernel features (expert users)
  "KALLSYMS" = yes; # Load all symbols for debugging/ksymoops
  "KALLSYMS_SELFTEST" = no; # Test the basic functions and performance of kallsyms
  "KALLSYMS_ALL" = yes; # Include all symbols in kallsyms

  ### General setup -> Kernel Performance Events And Counters
  "PERF_EVENTS" = yes; # Kernel performance events and counters
  "DEBUG_PERF_USE_VMALLOC" = no; # Debug: use vmalloc to back perf mmap() buffers
  ### General setup: end of Kernel Performance Events And Counters

  "PROFILING" = yes; # Profiling support
  "RUST" = no; # Rust support

  ### General setup -> Kexec and crash features
  "KEXEC" = yes; # Enable kexec system call
  "KEXEC_FILE" = yes; # Enable kexec file based system call
  "KEXEC_SIG" = no; # Verify kernel signature during kexec_file_load() syscall
  "KEXEC_HANDOVER" = no; # kexec handover
  "CRASH_DUMP" = yes; # kernel crash dumps
  "CRASH_DM_CRYPT" = no; # Support saving crash dump to dm-crypt encrypted volume
  ### General setup: end of Kexec and crash features
  ## end of General setup

  ## Platform selection
  "ARCH_ACTIONS" = no; # Actions Semi Platforms
  "ARCH_AIROHA" = yes; # Airoha SoC Support
  "ARCH_SUNXI" = no; # Allwinner sunxi 64-bit SoC Family
  "ARCH_ALPINE" = no; # Annapurna Labs Alpine platform
  "ARCH_APPLE" = no; # Apple Silicon SoC family
  "ARCH_BCM" = no; # Broadcom SoC Support
  "ARCH_BERLIN" = no; # Marvell Berlin SoC Family
  "ARCH_BITMAIN" = no; # Bitmain SoC Platforms
  "ARCH_BLAIZE" = no; # Blaize SoC Platforms
  "ARCH_EXYNOS" = no; # Samsung Exynos SoC family
  "ARCH_SPARX5" = no; # Microchip Sparx5 SoC family
  "ARCH_K3" = no; # Texas Instruments Inc. K3 multicore SoC architecture
  "ARCH_LG1K" = no; # LG Electronics LG1K SoC Family
  "ARCH_HISI" = no; # Hisilicon SoC Family
  "ARCH_KEEMBAY" = no; # Keem Bay SoC
  "ARCH_MEDIATEK" = no; # MediaTek SoC Family
  "ARCH_MESON" = no; # Amlogic Platforms
  "ARCH_MVEBU" = no; # Marvell EBU SoC Family
  "ARCH_NXP" = no; # NXP SoC support
  "ARCH_MA35" = yes; # Nuvoton MA35 Architecture
  "ARCH_NPCM" = no; # Nuvoton NPCM Architecture
  "ARCH_PENSANDO" = no; # AMD Pensando Platforms
  "ARCH_QCOM" = yes; # Qualcomm Platforms
  "ARCH_REALTEK" = yes; # Realtek Platforms
  "ARCH_RENESAS" = no; # Renesas SoC Platforms
  "ARCH_ROCKCHIP" = no; # Rockchip Platforms
  "ARCH_SEATTLE" = no; # AMD Seattle SoC Family
  "ARCH_INTEL_SOCFPGA" = no; # Intel's SoCFPGA ARMv8 Families
  "ARCH_STM32" = yes; # STMicroelectronics STM32 SoC Family
  "ARCH_SYNQUACER" = no; # Socionext SynQuacer SoC Family
  "ARCH_TEGRA" = no; # NVIDIA Tegra SoC Family
  "ARCH_SPRD" = no; # Spreadtrum SoC platform
  "ARCH_THUNDER" = no; # Cavium Inc. Thunder SoC Family
  "ARCH_THUNDER2" = no; # Cavium ThunderX2 Server Processors
  "ARCH_UNIPHIER" = no; # Socionext UniPhier SoC Family
  "ARCH_VEXPRESS" = no; # ARM Ltd Platforms
  "ARCH_VISCONTI" = no; # Toshiba Visconti SoC Family
  "ARCH_XGENE" = no; # AppliedMicro X-Gene SOC Family
  "ARCH_ZYNQMP" = no; # Xilinx ZynqMP Family
  ## end of Platform selection

  ## Kernel Features

  ### Kernel Features -> ARM errata workarounds via the alternatives framework
  "AMPERE_ERRATUM_AC03_CPU_38" = yes; # AmpereOne: AC03_CPU_38: Certain bits in the Virtualization Translation Control Register and Translation Control Registers do not follow RES0 semantics
  "AMPERE_ERRATUM_AC04_CPU_23" = yes; # AmpereOne: AC04_CPU_23:  Failure to synchronize writes to HCR_EL2 may corrupt address translations.
  "ARM64_ERRATUM_826319" = yes; # Cortex-A53: 826319: System might deadlock if a write cannot complete until read data is accepted
  "ARM64_ERRATUM_827319" = yes; # Cortex-A53: 827319: Data cache clean instructions might cause overlapping transactions to the interconnect
  "ARM64_ERRATUM_824069" = yes; # Cortex-A53: 824069: Cache line might not be marked as clean after a CleanShared snoop
  "ARM64_ERRATUM_819472" = yes; # Cortex-A53: 819472: Store exclusive instructions might cause data corruption
  "ARM64_ERRATUM_832075" = yes; # Cortex-A57: 832075: possible deadlock on mixing exclusive memory accesses with device loads
  "ARM64_ERRATUM_834220" = no; # Cortex-A57: 834220: Stage 2 translation fault might be incorrectly reported in presence of a Stage 1 fault (rare)
  "ARM64_ERRATUM_1742098" = yes; # Cortex-A57/A72: 1742098: ELR recorded incorrectly on interrupt taken between cryptographic instructions in a sequence
  "ARM64_ERRATUM_845719" = yes; # Cortex-A53: 845719: a load might read incorrect data
  "ARM64_ERRATUM_843419" = yes; # Cortex-A53: 843419: A load or store might access an incorrect address
  "ARM64_ERRATUM_1024718" = yes; # Cortex-A55: 1024718: Update of DBM/AP bits without break before make might result in incorrect update
  "ARM64_ERRATUM_1418040" = yes; # Cortex-A76/Neoverse-N1: MRC read following MRRC read of specific Generic Timer in AArch32 might give incorrect result
  "ARM64_ERRATUM_1165522" = yes; # Cortex-A76: 1165522: Speculative AT instruction using out-of-context translation regime could cause subsequent request to generate an incorrect translation
  "ARM64_ERRATUM_1319367" = yes; # Cortex-A57/A72: 1319537: Speculative AT instruction using out-of-context translation regime could cause subsequent request to generate an incorrect translation
  "ARM64_ERRATUM_1530923" = yes; # Cortex-A55: 1530923: Speculative AT instruction using out-of-context translation regime could cause subsequent request to generate an incorrect translation
  "ARM64_ERRATUM_2441007" = no; # Cortex-A55: Completion of affected memory accesses might not be guaranteed by completion of a TLBI (rare)
  "ARM64_ERRATUM_1286807" = no; # Cortex-A76: Modification of the translation table for a virtual address might lead to read-after-read ordering violation (rare)
  "ARM64_ERRATUM_1463225" = yes; # Cortex-A76: Software Step might prevent interrupt recognition
  "ARM64_ERRATUM_1542419" = no; # Neoverse-N1: workaround mis-ordering of instruction fetches (rare)
  "ARM64_ERRATUM_1508412" = yes; # Cortex-A77: 1508412: workaround deadlock on sequence of NC/Device load and store exclusive or PAR read
  "ARM64_ERRATUM_2051678" = yes; # Cortex-A510: 2051678: disable Hardware Update of the page table dirty bit
  "ARM64_ERRATUM_2077057" = yes; # Cortex-A510: 2077057: workaround software-step corrupting SPSR_EL2
  "ARM64_ERRATUM_2658417" = yes; # Cortex-A510: 2658417: remove BF16 support due to incorrect result
  "ARM64_ERRATUM_2054223" = yes; # Cortex-A710: 2054223: workaround TSB instruction failing to flush trace
  "ARM64_ERRATUM_2067961" = yes; # Neoverse-N2: 2067961: workaround TSB instruction failing to flush trace
  "ARM64_ERRATUM_2441009" = no; # Cortex-A510: Completion of affected memory accesses might not be guaranteed by completion of a TLBI (rare)
  "ARM64_ERRATUM_2457168" = yes; # Cortex-A510: 2457168: workaround for AMEVCNTR01 incrementing incorrectly
  "ARM64_ERRATUM_2645198" = yes; # Cortex-A715: 2645198: Workaround possible [ESR|FAR]_ELx corruption
  "ARM64_ERRATUM_2966298" = yes; # Cortex-A520: 2966298: workaround for speculatively executed unprivileged load
  "ARM64_ERRATUM_3117295" = yes; # Cortex-A510: 3117295: workaround for speculatively executed unprivileged load
  "ARM64_ERRATUM_3194386" = yes; # Cortex-*/Neoverse-*: workaround for MSR SSBS not self-synchronizing
  "CAVIUM_ERRATUM_22375" = no; # Cavium erratum 22375, 24313
  "CAVIUM_ERRATUM_23144" = yes; # Cavium erratum 23144: ITS SYNC hang on dual socket system
  "CAVIUM_ERRATUM_23154" = no; # Cavium errata 23154 and 38545: GICv3 lacks HW synchronisation
  "CAVIUM_ERRATUM_27456" = no; # Cavium erratum 27456: Broadcast TLBI instructions may cause icache corruption
  "CAVIUM_ERRATUM_30115" = no; # Cavium erratum 30115: Guest may disable interrupts in host
  "CAVIUM_TX2_ERRATUM_219" = no; # Cavium ThunderX2 erratum 219: PRFM between TTBR change and ISB fails
  "FUJITSU_ERRATUM_010001" = no; # Fujitsu-A64FX erratum E#010001: Undefined fault may occur wrongly
  "HISILICON_ERRATUM_161600802" = yes; # Hip07 161600802: Erroneous redistributor VLPI base
  "HISILICON_ERRATUM_162100801" = yes; # Hip09 162100801 erratum support
  "QCOM_FALKOR_ERRATUM_1003" = yes; # Falkor E1003: Incorrect translation due to ASID change
  "QCOM_FALKOR_ERRATUM_1009" = yes; # Falkor E1009: Prematurely complete a DSB after a TLBI
  "QCOM_QDF2400_ERRATUM_0065" = yes; # QDF2400 E0065: Incorrect GITS_TYPER.ITT_Entry_size
  "QCOM_FALKOR_ERRATUM_E1041" = yes; # Falkor E1041: Speculative instruction fetches might cause errant memory access
  "NVIDIA_CARMEL_CNP_ERRATUM" = yes; # NVIDIA Carmel CNP: CNP on Carmel semantically different than ARM cores
  "ROCKCHIP_ERRATUM_3568002" = yes; # Rockchip 3568002: GIC600 can not access physical addresses higher than 4GB
  "ROCKCHIP_ERRATUM_3588001" = yes; # Rockchip 3588001: GIC600 can not support shareability attributes
  "SOCIONEXT_SYNQUACER_PREITS" = no; # Socionext Synquacer: Workaround for GICv3 pre-ITS
  ### Kernel Features: end of ARM errata workarounds via the alternatives framework

  "ARM64_4K_PAGES" = yes; # 4KB
  "ARM64_16K_PAGES" = no; # 16KB
  "ARM64_64K_PAGES" = no; # 64KB
  "ARM64_VA_BITS_39" = no; # 39-bit
  "ARM64_VA_BITS_48" = no; # 48-bit
  "ARM64_VA_BITS_52" = yes; # 52-bit
  "ARM64_PA_BITS_52" = yes; # 52-bit
  "CPU_BIG_ENDIAN" = no; # Build big-endian kernel
  "CPU_LITTLE_ENDIAN" = yes; # Build little-endian kernel
  "SCHED_MC" = yes; # Multi-core scheduler support
  "SCHED_CLUSTER" = yes; # Cluster scheduler support
  "SCHED_SMT" = yes; # SMT scheduler support
  "NR_CPUS" = freeform "8"; # Maximum number of CPUs (2-4096)
  "HOTPLUG_CPU" = yes; # Support for hot-pluggable CPUs
  "NUMA" = yes; # NUMA Memory Allocation and Scheduler Support
  "NODES_SHIFT" = freeform "4"; # Maximum NUMA Nodes (as a power of 2)
  "HZ_100" = no; # 100 HZ
  "HZ_250" = no; # 250 HZ
  "HZ_300" = no; # 300 HZ
  "HZ_1000" = yes; # 1000 HZ
  "PARAVIRT" = yes; # Enable paravirtualization code
  "PARAVIRT_TIME_ACCOUNTING" = no; # Paravirtual steal time accounting
  "XEN" = yes; # Xen guest support on ARM64
  "RODATA_FULL_DEFAULT_ENABLED" = yes; # Apply r/o permissions of VM areas also to their linear aliases
  "ARM64_SW_TTBR0_PAN" = no; # Emulate Privileged Access Never using TTBR0_EL1 switching
  "ARM64_TAGGED_ADDR_ABI" = yes; # Enable the tagged user addresses syscall ABI
  "COMPAT" = yes; # Kernel support for 32-bit EL0
  "KUSER_HELPERS" = yes; # Enable kuser helpers page for 32-bit applications
  "COMPAT_ALIGNMENT_FIXUPS" = no; # Fix up misaligned multi-word loads and stores in user space
  "ARMV8_DEPRECATED" = no; # Emulate deprecated/obsolete ARMv8 instructions

  ### Kernel Features -> ARMv8.1 architectural features
  "ARM64_HW_AFDBM" = yes; # Support for hardware updates of the Access and Dirty page flags
  "ARM64_PAN" = yes; # Enable support for Privileged Access Never (PAN)
  "ARM64_USE_LSE_ATOMICS" = yes; # Atomic instructions
  ### Kernel Features: end of ARMv8.1 architectural features

  ### Kernel Features -> ARMv8.2 architectural features
  "ARM64_PMEM" = no; # Enable support for persistent memory
  "ARM64_RAS_EXTN" = yes; # Enable support for RAS CPU Extensions
  "ARM64_CNP" = yes; # Enable support for Common Not Private (CNP) translations
  ### Kernel Features: end of ARMv8.2 architectural features

  ### Kernel Features -> ARMv8.3 architectural features
  "ARM64_PTR_AUTH" = yes; # Enable support for pointer authentication
  "ARM64_PTR_AUTH_KERNEL" = yes; # Use pointer authentication for kernel
  ### Kernel Features: end of ARMv8.3 architectural features

  ### Kernel Features -> ARMv8.4 architectural features
  "ARM64_AMU_EXTN" = yes; # Enable support for the Activity Monitors Unit CPU extension
  "ARM64_TLB_RANGE" = yes; # Enable support for tlbi range feature
  ### Kernel Features: end of ARMv8.4 architectural features

  ### Kernel Features -> ARMv8.5 architectural features
  "ARM64_BTI" = yes; # Branch Target Identification support
  "ARM64_E0PD" = yes; # Enable support for E0PD
  "ARM64_MTE" = yes; # Memory Tagging Extension support
  ### Kernel Features: end of ARMv8.5 architectural features

  ### Kernel Features -> ARMv8.7 architectural features
  "ARM64_EPAN" = yes; # Enable support for Enhanced Privileged Access Never (EPAN)
  ### Kernel Features: end of ARMv8.7 architectural features

  ### Kernel Features -> ARMv8.9 architectural features
  "ARM64_POE" = yes; # Permission Overlay Extension
  "ARM64_HAFT" = yes; # Support for Hardware managed Access Flag for Table Descriptors
  ### Kernel Features: end of ARMv8.9 architectural features
  "ARM64_SVE" = yes; # ARM Scalable Vector Extension support
  "ARM64_SME" = yes; # ARM Scalable Matrix Extension support
  "ARM64_PSEUDO_NMI" = no; # Support for NMI-like interrupts
  "RANDOMIZE_BASE" = yes; # Randomize the address of the kernel image
  "RANDOMIZE_MODULE_REGION_FULL" = yes; # Randomize the module region over a 2 GB range
  ## end of Kernel Features

  ## Boot options
  "ARM64_ACPI_PARKING_PROTOCOL" = no; # Enable support for the ARM64 ACPI parking protocol
  "EFI" = yes; # UEFI runtime support
  "COMPRESSED_INSTALL" = no; # Install compressed image by default
  "DMI" = yes; # Enable support for SMBIOS (DMI) tables
  ## end of Boot options

  ## Power management options
  "SUSPEND" = yes; # Suspend to RAM and standby
  "HIBERNATION" = no; # Hibernation (aka 'suspend to disk')
  "PM_AUTOSLEEP" = yes; # Opportunistic sleep
  "PM_USERSPACE_AUTOSLEEP" = no; # Userspace opportunistic sleep
  "PM_WAKELOCKS" = yes; # User space wakeup sources interface
  "PM_WAKELOCKS_LIMIT" = freeform "100"; # Maximum number of user space wakeup sources (0 = no limit)
  "PM_WAKELOCKS_GC" = yes; # Garbage collector for user space wakeup sources
  "PM" = yes; # Device power management core functionality
  "PM_DEBUG" = no; # Power Management Debug Support
  "WQ_POWER_EFFICIENT_DEFAULT" = yes; # Enable workqueue power-efficient mode by default
  "ENERGY_MODEL" = yes; # Energy Model for devices with DVFS (CPUs, GPUs, etc)
  ## end of Power management options

  ## CPU Power Management

  ### CPU Power Management -> CPU Idle
  "CPU_IDLE" = yes; # CPU idle PM support
  "CPU_IDLE_GOV_LADDER" = no; # Ladder governor (for periodic timer tick)
  "CPU_IDLE_GOV_MENU" = yes; # Menu governor (for tickless system)
  "CPU_IDLE_GOV_TEO" = no; # Timer events oriented (TEO) governor (for tickless systems)

  ##### ARM CPU Idle Drivers
  "ARM_PSCI_CPUIDLE" = yes; # PSCI CPU idle Driver
  "ARM_PSCI_CPUIDLE_DOMAIN" = yes; # PSCI CPU idle Domain
  ##### end of ARM CPU Idle Drivers
  ### CPU Power Management: end of CPU Idle

  ### CPU Power Management -> CPU Frequency scaling
  "CPU_FREQ" = yes; # CPU Frequency scaling
  "CPU_FREQ_STAT" = yes; # CPU frequency transition statistics
  "CPU_FREQ_DEFAULT_GOV_PERFORMANCE" = no; # performance
  "CPU_FREQ_DEFAULT_GOV_POWERSAVE" = no; # powersave
  "CPU_FREQ_DEFAULT_GOV_USERSPACE" = no; # userspace
  "CPU_FREQ_DEFAULT_GOV_ONDEMAND" = no; # ondemand
  "CPU_FREQ_DEFAULT_GOV_CONSERVATIVE" = no; # conservative
  "CPU_FREQ_DEFAULT_GOV_SCHEDUTIL" = yes; # schedutil
  "CPU_FREQ_GOV_PERFORMANCE" = yes; # 'performance' governor
  "CPU_FREQ_GOV_POWERSAVE" = yes; # 'powersave' governor
  "CPU_FREQ_GOV_USERSPACE" = yes; # 'userspace' governor for userspace frequency scaling
  "CPU_FREQ_GOV_ONDEMAND" = yes; # 'ondemand' cpufreq policy governor
  "CPU_FREQ_GOV_CONSERVATIVE" = module; # 'conservative' cpufreq governor
  "CPU_FREQ_GOV_SCHEDUTIL" = yes; # 'schedutil' cpufreq policy governor
  "CPUFREQ_DT" = yes; # Generic DT based cpufreq driver
  "CPUFREQ_VIRT" = no; # Virtual cpufreq driver
  "CPUFREQ_DT_PLATDEV" = yes; # Generic DT based cpufreq platdev driver
  "ARM_AIROHA_SOC_CPUFREQ" = yes; # Airoha EN7581 SoC CPUFreq support
  "ARM_SCPI_CPUFREQ" = yes; # SCPI based CPUfreq driver
  "ARM_QCOM_CPUFREQ_NVMEM" = yes; # Qualcomm nvmem based CPUFreq
  "ARM_QCOM_CPUFREQ_HW" = yes; # QCOM CPUFreq HW driver
  "ARM_SCMI_CPUFREQ" = yes; # SCMI based CPUfreq driver
  "ACPI_CPPC_CPUFREQ" = module; # CPUFreq driver based on the ACPI CPPC spec
  "ACPI_CPPC_CPUFREQ_FIE" = yes; # Frequency Invariance support for CPPC cpufreq driver
  ### CPU Power Management: end of CPU Frequency scaling
  ## end of CPU Power Management

  "ACPI" = yes; # ACPI (Advanced Configuration and Power Interface) Support
  "ACPI_DEBUGGER" = no; # AML debugger interface
  "ACPI_SPCR_TABLE" = yes; # ACPI Serial Port Console Redirection Support
  "ACPI_FPDT" = no; # ACPI Firmware Performance Data Table (FPDT) support
  "ACPI_EC" = no; # Embedded Controller
  "ACPI_AC" = yes; # AC Adapter
  "ACPI_BATTERY" = yes; # Battery
  "ACPI_BUTTON" = yes; # Button
  "ACPI_VIDEO" = no; # Video
  "ACPI_FAN" = yes; # Fan
  "ACPI_TAD" = no; # ACPI Time and Alarm (TAD) Device Support
  "ACPI_DOCK" = no; # Dock
  "ACPI_PROCESSOR" = yes; # Processor
  "ACPI_IPMI" = no; # IPMI
  "ACPI_THERMAL" = yes; # Thermal Zone
  "ACPI_TABLE_UPGRADE" = yes; # Allow upgrading ACPI tables via initrd
  "ACPI_DEBUG" = no; # Debug Statements
  "ACPI_PCI_SLOT" = no; # PCI slot detection driver
  "ACPI_CONTAINER" = yes; # Container and Module Devices
  "ACPI_HED" = yes; # Hardware Error Device
  "ACPI_BGRT" = no; # Boottime Graphics Resource Table support
  "ACPI_HMAT" = yes; # ACPI Heterogeneous Memory Attribute Table Support
  "ACPI_APEI" = yes; # ACPI Platform Error Interface (APEI)
  "ACPI_APEI_GHES" = yes; # APEI Generic Hardware Error Source
  "ACPI_APEI_PCIEAER" = yes; # APEI PCIe AER logging/recovering support
  "ACPI_APEI_MEMORY_FAILURE" = yes; # APEI memory error recovering support
  "ACPI_APEI_EINJ" = yes; # APEI Error INJection (EINJ)
  "ACPI_APEI_ERST_DEBUG" = no; # APEI Error Record Serialization Table (ERST) Debug Support
  "ACPI_CONFIGFS" = no; # ACPI configfs support
  "ACPI_PFRUT" = no; # ACPI Platform Firmware Runtime Update and Telemetry
  "ACPI_AGDI" = no; # Arm Generic Diagnostic Dump and Reset Device Interface
  "ACPI_PCC" = yes; # ACPI PCC Address Space
  "ACPI_FFH" = no; # ACPI FFH Address Space
  "PMIC_OPREGION" = no; # PMIC (Power Management Integrated Circuit) operation region support
  "ACPI_PRMT" = yes; # Platform Runtime Mechanism Support
  "VIRTUALIZATION" = yes; # Virtualization
  "KVM" = yes; # Kernel-based Virtual Machine (KVM) support
  "NVHE_EL2_DEBUG" = no; # Debug mode for non-VHE EL2 object
  "PTDUMP_STAGE2_DEBUGFS" = no; # Present the stage-2 pagetables to debugfs

  ## General architecture-dependent options
  "KPROBES" = no; # Kprobes
  "JUMP_LABEL" = yes; # Optimize very unlikely/likely branches
  "STATIC_KEYS_SELFTEST" = no; # Static key selftest
  "SECCOMP" = yes; # Enable seccomp to safely execute untrusted bytecode
  "SECCOMP_CACHE_DEBUG" = no; # Show seccomp filter cache status in /proc/pid/seccomp_cache
  "STACKPROTECTOR" = yes; # Stack Protector buffer overflow detection
  "STACKPROTECTOR_STRONG" = yes; # Strong Stack Protector
  "SHADOW_CALL_STACK" = no; # Shadow Call Stack
  "LTO_NONE" = yes; # None
  "PAGE_SIZE_4KB" = yes; # 4KiB pages
  "COMPAT_32BIT_TIME" = yes; # Provide system calls for 32-bit time_t
  "VMAP_STACK" = yes; # Use a virtually-mapped stack
  "RANDOMIZE_KSTACK_OFFSET" = yes; # Support for randomizing kernel stack offset on syscall entry
  "RANDOMIZE_KSTACK_OFFSET_DEFAULT" = no; # Default state of kernel stack offset randomization
  "LOCK_EVENT_COUNTS" = no; # Locking event counts collection
  "RELR" = yes; # Use RELR relocation packing

  ### General architecture-dependent options -> GCOV-based kernel profiling
  "GCOV_KERNEL" = no; # Enable gcov-based kernel profiling
  ### General architecture-dependent options: end of GCOV-based kernel profiling

  "GCC_PLUGINS" = yes; # GCC plugins
  "GCC_PLUGIN_LATENT_ENTROPY" = no; # Generate some entropy during boot and runtime
  ## end of General architecture-dependent options

  "MODULES" = yes; # Enable loadable module support
  "MODULE_DEBUG" = no; # Module debugging
  "MODULE_FORCE_LOAD" = no; # Forced module loading
  "MODULE_UNLOAD" = yes; # Module unloading
  "MODULE_FORCE_UNLOAD" = no; # Forced module unloading
  "MODULE_UNLOAD_TAINT_TRACKING" = no; # Tainted module unload tracking
  "MODVERSIONS" = no; # Module versioning support
  "MODULE_SRCVERSION_ALL" = no; # Source checksum for all modules
  "MODULE_SIG" = no; # Module signature verification
  "MODULE_COMPRESS" = yes; # Module compression
  "MODULE_COMPRESS_GZIP" = no; # GZIP
  "MODULE_COMPRESS_XZ" = no; # XZ
  "MODULE_COMPRESS_ZSTD" = yes; # ZSTD
  "MODULE_COMPRESS_ALL" = yes; # Automatically compress all modules
  "MODULE_DECOMPRESS" = yes; # Support in-kernel module decompression
  "MODULE_ALLOW_MISSING_NAMESPACE_IMPORTS" = no; # Allow loading of modules with missing namespace imports
  "MODPROBE_PATH" = freeform "/sbin/modprobe"; # Path to modprobe binary
  "TRIM_UNUSED_KSYMS" = no; # Trim unused exported kernel symbols
  "BLOCK" = yes; # Enable the block layer
  "BLOCK_LEGACY_AUTOLOAD" = yes; # Legacy autoloading support
  "BLK_DEV_BSGLIB" = yes; # Block layer SG support v4 helper lib
  "BLK_DEV_INTEGRITY" = yes; # Block layer data integrity support
  "BLK_DEV_WRITE_MOUNTED" = yes; # Allow writing to mounted block devices
  "BLK_DEV_ZONED" = no; # Zoned block device support
  "BLK_DEV_THROTTLING" = yes; # Block layer bio throttling support
  "BLK_WBT" = no; # Enable support for block device writeback throttling
  "BLK_CGROUP_IOLATENCY" = no; # Enable support for latency based cgroup IO protection
  "BLK_CGROUP_IOCOST" = no; # Enable support for cost model based cgroup IO controller
  "BLK_CGROUP_IOPRIO" = no; # Cgroup I/O controller for assigning an I/O priority class
  "BLK_DEBUG_FS" = yes; # Block layer debugging information in debugfs
  "BLK_SED_OPAL" = no; # Logic for interfacing with Opal enabled SEDs
  "BLK_INLINE_ENCRYPTION" = yes; # Enable inline encryption support in block layer
  "BLK_INLINE_ENCRYPTION_FALLBACK" = no; # Enable crypto API fallback for blk-crypto

  ### Partition Types
  "PARTITION_ADVANCED" = no; # Advanced partition selection
  ### end of Partition Types

  ### IO Schedulers
  "MQ_IOSCHED_DEADLINE" = yes; # MQ deadline I/O scheduler
  "MQ_IOSCHED_KYBER" = yes; # Kyber I/O scheduler
  "IOSCHED_BFQ" = yes; # BFQ I/O scheduler
  "BFQ_GROUP_IOSCHED" = yes; # BFQ hierarchical scheduling support
  "BFQ_CGROUP_DEBUG" = no; # BFQ IO controller debugging
  ### end of IO Schedulers

  ## Executable file formats
  "BINFMT_ELF" = yes; # Kernel support for ELF binaries
  "CORE_DUMP_DEFAULT_ELF_HEADERS" = no; # Write ELF core dumps with partial segments
  "BINFMT_SCRIPT" = yes; # Kernel support for scripts starting with #!
  "BINFMT_MISC" = module; # Kernel support for MISC binaries
  ## end of Executable file formats

  ## Memory Management options
  "SWAP" = yes; # Support for paging of anonymous memory (swap)
  "ZSWAP" = no; # Compressed cache for swap pages
  "ZSMALLOC" = module; # N:1 compression allocator (zsmalloc)
  "ZSMALLOC_STAT" = yes; # Export zsmalloc statistics
  "ZSMALLOC_CHAIN_SIZE" = freeform "8"; # Maximum number of physical pages per-zspage

  ### Memory Management options -> Slab allocator options
  "SLAB_MERGE_DEFAULT" = yes; # Allow slab caches to be merged
  "SLAB_FREELIST_RANDOM" = no; # Randomize slab freelist
  "SLAB_FREELIST_HARDENED" = no; # Harden slab freelist metadata
  "SLAB_BUCKETS" = no; # Support allocation from separate kmalloc buckets
  "SLUB_STATS" = no; # Enable performance statistics
  "SLUB_CPU_PARTIAL" = yes; # Enable per cpu partial caches
  "RANDOM_KMALLOC_CACHES" = no; # Randomize slab caches for normal kmalloc
  ### Memory Management options: end of Slab allocator options

  "SHUFFLE_PAGE_ALLOCATOR" = no; # Page allocator randomization
  "COMPAT_BRK" = no; # Disable heap randomization
  "SPARSEMEM_VMEMMAP" = yes; # Sparse Memory virtual memmap
  "MEMORY_HOTPLUG" = no; # Memory hotplug
  "BALLOON_COMPACTION" = yes; # Allow for balloon memory compaction/migration
  "COMPACTION" = yes; # Allow for memory compaction
  "PAGE_REPORTING" = yes; # Free page reporting
  "MIGRATION" = yes; # Page migration
  "PCP_BATCH_SCALE_MAX" = freeform "5"; # Maximum scale factor of PCP (Per-CPU pageset) batch allocate/free
  "KSM" = yes; # Enable KSM for page merging
  "DEFAULT_MMAP_MIN_ADDR" = freeform "4096"; # Low address space to protect from user allocation
  "MEMORY_FAILURE" = yes; # Enable recovery from hardware memory errors
  "HWPOISON_INJECT" = no; # HWPoison pages injector
  "TRANSPARENT_HUGEPAGE" = yes; # Transparent Hugepage Support
  "TRANSPARENT_HUGEPAGE_ALWAYS" = yes; # always
  "TRANSPARENT_HUGEPAGE_MADVISE" = no; # madvise
  "TRANSPARENT_HUGEPAGE_NEVER" = no; # never
  "READ_ONLY_THP_FOR_FS" = no; # Read-only THP for filesystems (EXPERIMENTAL)
  "NO_PAGE_MAPCOUNT" = no; # No per-page mapcount (EXPERIMENTAL)
  "CMA" = yes; # Contiguous Memory Allocator
  "CMA_DEBUGFS" = no; # CMA debugfs interface
  "CMA_SYSFS" = no; # CMA information through sysfs interface
  "CMA_AREAS" = freeform "20"; # Maximum count of the CMA areas
  "PAGE_BLOCK_ORDER" = freeform "10"; # Page Block Order
  "DEFERRED_STRUCT_PAGE_INIT" = no; # Defer initialisation of struct pages to kthreads
  "IDLE_PAGE_TRACKING" = no; # Enable idle page tracking
  "PERCPU_STATS" = no; # Collect percpu memory statistics
  "GUP_TEST" = no; # Enable infrastructure for get_user_pages()-related unit tests
  "DMAPOOL_TEST" = no; # Enable a module to run time tests on dma_pool
  "ANON_VMA_NAME" = no; # Anonymous VMA name support
  "USERFAULTFD" = no; # Enable userfaultfd() system call
  "LRU_GEN" = yes; # Multi-Gen LRU
  "LRU_GEN_ENABLED" = yes; # Enable by default
  "LRU_GEN_STATS" = no; # Full stats for debugging
  "NUMA_EMU" = no; # NUMA emulation

  ### Memory Management options -> Data Access Monitoring
  "DAMON" = no; # DAMON: Data Access Monitoring Framework
  ### Memory Management options: end of Data Access Monitoring
  ## end of Memory Management options

  "NET" = yes; # Networking support

  ### Networking options
  "PACKET" = yes; # Packet socket
  "PACKET_DIAG" = yes; # Packet: sockets monitoring interface
  "UNIX" = yes; # Unix domain sockets
  "AF_UNIX_OOB" = yes; # UNIX: out-of-bound messages
  "UNIX_DIAG" = yes; # UNIX: socket monitoring interface
  "TLS" = no; # Transport Layer Security support
  "XFRM_USER" = no; # Transformation user configuration interface
  "NET_KEY" = no; # PF_KEY sockets
  "XDP_SOCKETS" = no; # XDP sockets
  "INET" = yes; # TCP/IP networking
  "IP_MULTICAST" = yes; # IP: multicasting
  "IP_ADVANCED_ROUTER" = yes; # IP: advanced router
  "IP_FIB_TRIE_STATS" = no; # FIB TRIE statistics
  "IP_MULTIPLE_TABLES" = yes; # IP: policy routing
  "IP_ROUTE_MULTIPATH" = no; # IP: equal cost multipath
  "IP_ROUTE_VERBOSE" = no; # IP: verbose route monitoring
  "IP_PNP" = yes; # IP: kernel level autoconfiguration
  "IP_PNP_DHCP" = yes; # IP: DHCP support
  "IP_PNP_BOOTP" = yes; # IP: BOOTP support
  "IP_PNP_RARP" = no; # IP: RARP support
  "NET_IPIP" = no; # IP: tunneling
  "NET_IPGRE_DEMUX" = no; # IP: GRE demultiplexer
  "IP_MROUTE" = no; # IP: multicast routing
  "SYN_COOKIES" = yes; # IP: TCP syncookie support
  "NET_IPVTI" = no; # Virtual (secure) IP: tunneling
  "NET_FOU" = no; # IP: Foo (IP protocols) over UDP
  "NET_FOU_IP_TUNNELS" = no; # IP: FOU encapsulation of IP tunnels
  "INET_AH" = no; # IP: AH transformation
  "INET_ESP" = no; # IP: ESP transformation
  "INET_IPCOMP" = no; # IP: IPComp transformation
  "INET_DIAG" = yes; # INET: socket monitoring interface
  "INET_UDP_DIAG" = no; # UDP: socket monitoring interface
  "INET_RAW_DIAG" = no; # RAW: socket monitoring interface
  "INET_DIAG_DESTROY" = no; # INET: allow privileged process to administratively close sockets
  "TCP_CONG_ADVANCED" = yes; # TCP: advanced congestion control
  "TCP_CONG_BIC" = module; # Binary Increase Congestion (BIC) control
  "TCP_CONG_CUBIC" = yes; # CUBIC TCP
  "TCP_CONG_WESTWOOD" = yes; # TCP Westwood+
  "TCP_CONG_HTCP" = module; # H-TCP
  "TCP_CONG_HSTCP" = no; # High Speed TCP
  "TCP_CONG_HYBLA" = no; # TCP-Hybla congestion control algorithm
  "TCP_CONG_VEGAS" = no; # TCP Vegas
  "TCP_CONG_NV" = no; # TCP NV
  "TCP_CONG_SCALABLE" = no; # Scalable TCP
  "TCP_CONG_LP" = no; # TCP Low Priority
  "TCP_CONG_VENO" = no; # TCP Veno
  "TCP_CONG_YEAH" = no; # YeAH TCP
  "TCP_CONG_ILLINOIS" = no; # TCP Illinois
  "TCP_CONG_DCTCP" = no; # DataCenter TCP (DCTCP)
  "TCP_CONG_CDG" = no; # CAIA Delay-Gradient (CDG)
  "TCP_CONG_BBR" = no; # BBR TCP
  "DEFAULT_CUBIC" = no; # Cubic
  "DEFAULT_WESTWOOD" = yes; # Westwood
  "DEFAULT_RENO" = no; # Reno
  "TCP_MD5SIG" = no; # TCP: MD5 Signature Option support (RFC2385)
  "IPV6" = module; # The IPv6 protocol
  "IPV6_ROUTER_PREF" = no; # IPv6: Router Preference (RFC 4191) support
  "IPV6_OPTIMISTIC_DAD" = no; # IPv6: Enable RFC 4429 Optimistic DAD
  "INET6_AH" = no; # IPv6: AH transformation
  "INET6_ESP" = no; # IPv6: ESP transformation
  "INET6_IPCOMP" = no; # IPv6: IPComp transformation
  "IPV6_MIP6" = no; # IPv6: Mobility
  "IPV6_ILA" = no; # IPv6: Identifier Locator Addressing (ILA)
  "IPV6_VTI" = no; # Virtual (secure) IPv6: tunneling
  "IPV6_SIT" = module; # IPv6: IPv6-in-IPv4 tunnel (SIT driver)
  "IPV6_SIT_6RD" = no; # IPv6: IPv6 Rapid Deployment (6RD)
  "IPV6_TUNNEL" = no; # IPv6: IP-in-IPv6 tunnel (RFC2473)
  "IPV6_MULTIPLE_TABLES" = yes; # IPv6: Multiple Routing Tables
  "IPV6_SUBTREES" = no; # IPv6: source address based routing
  "IPV6_MROUTE" = no; # IPv6: multicast routing
  "IPV6_SEG6_LWTUNNEL" = no; # IPv6: Segment Routing Header encapsulation support
  "IPV6_SEG6_HMAC" = no; # IPv6: Segment Routing HMAC support
  "IPV6_RPL_LWTUNNEL" = no; # IPv6: RPL Source Routing Header support
  "IPV6_IOAM6_LWTUNNEL" = no; # IPv6: IOAM Pre-allocated Trace insertion support
  "NETLABEL" = no; # NetLabel subsystem support
  "MPTCP" = no; # MPTCP: Multipath TCP
  "NETWORK_SECMARK" = no; # Security Marking
  "NETWORK_PHY_TIMESTAMPING" = no; # Timestamping in PHY devices
  "NETFILTER" = yes; # Network packet filtering framework (Netfilter)
  "NETFILTER_ADVANCED" = yes; # Advanced netfilter configuration
  "BRIDGE_NETFILTER" = module; # Bridged IP/ARP packets filtering

  ##### Core Netfilter Configuration
  "NETFILTER_INGRESS" = yes; # Netfilter ingress support
  "NETFILTER_EGRESS" = yes; # Netfilter egress support
  "NETFILTER_NETLINK_HOOK" = no; # Netfilter base hook dump support
  "NETFILTER_NETLINK_ACCT" = no; # Netfilter NFACCT over NFNETLINK interface
  "NETFILTER_NETLINK_QUEUE" = no; # Netfilter NFQUEUE over NFNETLINK interface
  "NETFILTER_NETLINK_LOG" = no; # Netfilter LOG over NFNETLINK interface
  "NETFILTER_NETLINK_OSF" = no; # Netfilter OSF over NFNETLINK interface
  "NF_CONNTRACK" = module; # Netfilter connection tracking support
  "NF_LOG_SYSLOG" = module; # Syslog packet logging
  "NF_CONNTRACK_MARK" = yes; # Connection mark tracking support
  "NF_CONNTRACK_ZONES" = no; # Connection tracking zones
  "NF_CONNTRACK_PROCFS" = no; # Supply CT list in procfs (OBSOLETE)
  "NF_CONNTRACK_EVENTS" = yes; # Connection tracking events
  "NF_CONNTRACK_TIMEOUT" = no; # Connection tracking timeout
  "NF_CONNTRACK_TIMESTAMP" = no; # Connection tracking timestamping
  "NF_CONNTRACK_LABELS" = no; # Connection tracking labels
  "NF_CT_PROTO_DCCP" = yes; # DCCP protocol connection tracking support
  "NF_CT_PROTO_SCTP" = yes; # SCTP protocol connection tracking support
  "NF_CT_PROTO_UDPLITE" = yes; # UDP-Lite protocol connection tracking support
  "NF_CONNTRACK_AMANDA" = no; # Amanda backup protocol support
  "NF_CONNTRACK_FTP" = no; # FTP protocol support
  "NF_CONNTRACK_H323" = no; # H.323 protocol support
  "NF_CONNTRACK_IRC" = no; # IRC protocol support
  "NF_CONNTRACK_NETBIOS_NS" = no; # NetBIOS name service protocol support
  "NF_CONNTRACK_SNMP" = no; # SNMP service protocol support
  "NF_CONNTRACK_PPTP" = no; # PPtP protocol support
  "NF_CONNTRACK_SANE" = no; # SANE protocol support
  "NF_CONNTRACK_SIP" = no; # SIP protocol support
  "NF_CONNTRACK_TFTP" = no; # TFTP protocol support
  "NF_CT_NETLINK" = no; # Connection tracking netlink interface
  "NF_NAT" = module; # Network Address Translation support
  "NF_TABLES" = module; # Netfilter nf_tables support
  "NF_TABLES_INET" = yes; # Netfilter nf_tables mixed IPv4/IPv6 tables support
  "NF_TABLES_NETDEV" = no; # Netfilter nf_tables netdev tables support
  "NFT_NUMGEN" = no; # Netfilter nf_tables number generator module
  "NFT_CT" = module; # Netfilter nf_tables conntrack module
  "NFT_CONNLIMIT" = no; # Netfilter nf_tables connlimit module
  "NFT_LOG" = module; # Netfilter nf_tables log module
  "NFT_LIMIT" = module; # Netfilter nf_tables limit module
  "NFT_MASQ" = module; # Netfilter nf_tables masquerade support
  "NFT_REDIR" = no; # Netfilter nf_tables redirect support
  "NFT_NAT" = module; # Netfilter nf_tables nat module
  "NFT_TUNNEL" = no; # Netfilter nf_tables tunnel module
  "NFT_QUOTA" = no; # Netfilter nf_tables quota module
  "NFT_REJECT" = module; # Netfilter nf_tables reject support
  "NFT_COMPAT" = module; # Netfilter x_tables over nf_tables module
  "NFT_HASH" = no; # Netfilter nf_tables hash module
  "NFT_FIB_INET" = no; # Netfilter nf_tables fib inet support
  "NFT_SOCKET" = no; # Netfilter nf_tables socket match support
  "NFT_OSF" = no; # Netfilter nf_tables passive OS fingerprint support
  "NFT_TPROXY" = no; # Netfilter nf_tables tproxy support
  "NFT_SYNPROXY" = no; # Netfilter nf_tables SYNPROXY expression support
  "NF_FLOW_TABLE" = no; # Netfilter flow table module
  "NETFILTER_XTABLES" = module; # Netfilter Xtables support (required for ip_tables)
  "NETFILTER_XTABLES_COMPAT" = no; # Netfilter Xtables 32bit support
  "NETFILTER_XT_MARK" = module; # nfmark target and match support
  "NETFILTER_XT_CONNMARK" = no; # ctmark target and match support
  "NETFILTER_XT_TARGET_AUDIT" = no; # AUDIT target support
  "NETFILTER_XT_TARGET_CHECKSUM" = module; # CHECKSUM target support
  "NETFILTER_XT_TARGET_CLASSIFY" = no; # "CLASSIFY" target support
  "NETFILTER_XT_TARGET_CONNMARK" = no; # "CONNMARK" target support
  "NETFILTER_XT_TARGET_CT" = no; # "CT" target support
  "NETFILTER_XT_TARGET_DSCP" = no; # "DSCP" and "TOS" target support
  "NETFILTER_XT_TARGET_HL" = no; # "HL" hoplimit target support
  "NETFILTER_XT_TARGET_HMARK" = no; # "HMARK" target support
  "NETFILTER_XT_TARGET_IDLETIMER" = no; # IDLETIMER target support
  "NETFILTER_XT_TARGET_LED" = no; # "LED" target support
  "NETFILTER_XT_TARGET_LOG" = module; # LOG target support
  "NETFILTER_XT_TARGET_MARK" = no; # "MARK" target support
  "NETFILTER_XT_NAT" = module; # "SNAT and DNAT" targets support
  "NETFILTER_XT_TARGET_NETMAP" = no; # "NETMAP" target support
  "NETFILTER_XT_TARGET_NFLOG" = no; # "NFLOG" target support
  "NETFILTER_XT_TARGET_NFQUEUE" = no; # "NFQUEUE" target Support
  "NETFILTER_XT_TARGET_RATEEST" = no; # "RATEEST" target support
  "NETFILTER_XT_TARGET_REDIRECT" = module; # REDIRECT target support
  "NETFILTER_XT_TARGET_MASQUERADE" = module; # MASQUERADE target support
  "NETFILTER_XT_TARGET_TEE" = no; # "TEE" - packet cloning to alternate destination
  "NETFILTER_XT_TARGET_TPROXY" = no; # "TPROXY" target transparent proxying support
  "NETFILTER_XT_TARGET_TCPMSS" = module; # "TCPMSS" target support
  "NETFILTER_XT_TARGET_TCPOPTSTRIP" = no; # "TCPOPTSTRIP" target support
  "NETFILTER_XT_MATCH_ADDRTYPE" = module; # "addrtype" address type match support
  "NETFILTER_XT_MATCH_BPF" = no; # "bpf" match support
  "NETFILTER_XT_MATCH_CGROUP" = no; # "control group" match support
  "NETFILTER_XT_MATCH_CLUSTER" = no; # "cluster" match support
  "NETFILTER_XT_MATCH_COMMENT" = module; # "comment" match support
  "NETFILTER_XT_MATCH_CONNBYTES" = no; # "connbytes" per-connection counter match support
  "NETFILTER_XT_MATCH_CONNLABEL" = no; # "connlabel" match support
  "NETFILTER_XT_MATCH_CONNLIMIT" = no; # "connlimit" match support
  "NETFILTER_XT_MATCH_CONNMARK" = no; # "connmark" connection mark match support
  "NETFILTER_XT_MATCH_CONNTRACK" = module; # "conntrack" connection tracking match support
  "NETFILTER_XT_MATCH_CPU" = no; # "cpu" match support
  "NETFILTER_XT_MATCH_DCCP" = no; # "dccp" protocol match support
  "NETFILTER_XT_MATCH_DEVGROUP" = no; # "devgroup" match support
  "NETFILTER_XT_MATCH_DSCP" = no; # "dscp" and "tos" match support
  "NETFILTER_XT_MATCH_ECN" = no; # "ecn" match support
  "NETFILTER_XT_MATCH_ESP" = no; # "esp" match support
  "NETFILTER_XT_MATCH_HASHLIMIT" = no; # "hashlimit" match support
  "NETFILTER_XT_MATCH_HELPER" = no; # "helper" match support
  "NETFILTER_XT_MATCH_HL" = no; # "hl" hoplimit/TTL match support
  "NETFILTER_XT_MATCH_IPCOMP" = no; # "ipcomp" match support
  "NETFILTER_XT_MATCH_IPRANGE" = no; # "iprange" address range match support
  "NETFILTER_XT_MATCH_IPVS" = module; # "ipvs" match support
  "NETFILTER_XT_MATCH_L2TP" = no; # "l2tp" match support
  "NETFILTER_XT_MATCH_LENGTH" = no; # "length" match support
  "NETFILTER_XT_MATCH_LIMIT" = no; # "limit" match support
  "NETFILTER_XT_MATCH_MAC" = no; # "mac" address match support
  "NETFILTER_XT_MATCH_MARK" = module; # "mark" match support
  "NETFILTER_XT_MATCH_MULTIPORT" = module; # "multiport" Multiple port match support
  "NETFILTER_XT_MATCH_NFACCT" = no; # "nfacct" match support
  "NETFILTER_XT_MATCH_OSF" = no; # "osf" Passive OS fingerprint match
  "NETFILTER_XT_MATCH_OWNER" = no; # "owner" match support
  "NETFILTER_XT_MATCH_PHYSDEV" = no; # "physdev" match support
  "NETFILTER_XT_MATCH_PKTTYPE" = no; # "pkttype" packet type match support
  "NETFILTER_XT_MATCH_QUOTA" = no; # "quota" match support
  "NETFILTER_XT_MATCH_RATEEST" = no; # "rateest" match support
  "NETFILTER_XT_MATCH_REALM" = no; # "realm" match support
  "NETFILTER_XT_MATCH_RECENT" = no; # "recent" match support
  "NETFILTER_XT_MATCH_SCTP" = no; # "sctp" protocol match support
  "NETFILTER_XT_MATCH_SOCKET" = no; # "socket" match support
  "NETFILTER_XT_MATCH_STATE" = no; # "state" match support
  "NETFILTER_XT_MATCH_STATISTIC" = module; # "statistic" match support
  "NETFILTER_XT_MATCH_STRING" = no; # "string" match support
  "NETFILTER_XT_MATCH_TCPMSS" = module; # "tcpmss" match support
  "NETFILTER_XT_MATCH_TIME" = no; # "time" match support
  "NETFILTER_XT_MATCH_U32" = no; # "u32" match support
  ##### end of Core Netfilter Configuration

  "IP_SET" = no; # IP set support
  "IP_VS" = module; # IP virtual server support
  "IP_VS_IPV6" = no; # IPv6 support for IPVS
  "IP_VS_DEBUG" = no; # IP virtual server debugging
  "IP_VS_TAB_BITS" = freeform "12"; # IPVS connection table size (the Nth power of 2)
  "IP_VS_PROTO_TCP" = yes; # TCP load balancing support
  "IP_VS_PROTO_UDP" = yes; # UDP load balancing support
  "IP_VS_PROTO_ESP" = no; # ESP load balancing support
  "IP_VS_PROTO_AH" = no; # AH load balancing support
  "IP_VS_PROTO_SCTP" = no; # SCTP load balancing support
  "IP_VS_RR" = module; # round-robin scheduling
  "IP_VS_WRR" = no; # weighted round-robin scheduling
  "IP_VS_LC" = no; # least-connection scheduling
  "IP_VS_WLC" = no; # weighted least-connection scheduling
  "IP_VS_FO" = no; # weighted failover scheduling
  "IP_VS_OVF" = no; # weighted overflow scheduling
  "IP_VS_LBLC" = no; # locality-based least-connection scheduling
  "IP_VS_LBLCR" = no; # locality-based least-connection with replication scheduling
  "IP_VS_DH" = no; # destination hashing scheduling
  "IP_VS_SH" = no; # source hashing scheduling
  "IP_VS_MH" = no; # maglev hashing scheduling
  "IP_VS_SED" = no; # shortest expected delay scheduling
  "IP_VS_NQ" = no; # never queue scheduling
  "IP_VS_TWOS" = no; # weighted random twos choice least-connection scheduling
  "IP_VS_SH_TAB_BITS" = freeform "8"; # IPVS source hashing table size (the Nth power of 2)
  "IP_VS_MH_TAB_INDEX" = freeform "12"; # IPVS maglev hashing table index of size (the prime numbers)
  "IP_VS_NFCT" = yes; # Netfilter connection tracking

  ##### IP: Netfilter Configuration
  "IP_NF_IPTABLES_LEGACY" = module; # Legacy IP tables support
  "NF_SOCKET_IPV4" = no; # IPv4 socket lookup support
  "NF_TPROXY_IPV4" = no; # IPv4 tproxy support
  "NF_TABLES_IPV4" = yes; # IPv4 nf_tables support
  "NFT_DUP_IPV4" = no; # IPv4 nf_tables packet duplication support
  "NFT_FIB_IPV4" = module; # nf_tables fib / ip route lookup support
  "NF_TABLES_ARP" = no; # ARP nf_tables support
  "NF_DUP_IPV4" = no; # Netfilter IPv4 packet duplication to alternate destination
  "NF_LOG_ARP" = no; # ARP packet logging
  "NF_LOG_IPV4" = no; # IPv4 packet logging
  "NF_REJECT_IPV4" = module; # IPv4 packet rejection
  "IP_NF_IPTABLES" = module; # IP tables support (required for filtering/masq/NAT)
  "IP_NF_MATCH_AH" = no; # "ah" match support
  "IP_NF_MATCH_ECN" = no; # "ecn" match support
  "IP_NF_MATCH_RPFILTER" = no; # "rpfilter" reverse path filter match support
  "IP_NF_MATCH_TTL" = no; # "ttl" match support
  "IP_NF_FILTER" = module; # Packet filtering
  "IP_NF_TARGET_REJECT" = module; # REJECT target support
  "IP_NF_TARGET_SYNPROXY" = no; # SYNPROXY target support
  "IP_NF_NAT" = module; # iptables NAT support
  "IP_NF_TARGET_MASQUERADE" = module; # MASQUERADE target support
  "IP_NF_TARGET_NETMAP" = no; # NETMAP target support
  "IP_NF_TARGET_REDIRECT" = module; # REDIRECT target support
  "IP_NF_MANGLE" = module; # Packet mangling
  "IP_NF_TARGET_ECN" = no; # ECN target support
  "IP_NF_TARGET_TTL" = no; # "TTL" target support
  "IP_NF_RAW" = no; # raw table support (required for NOTRACK/TRACE)
  "IP_NF_SECURITY" = no; # Security table
  "IP_NF_ARPTABLES" = no; # Legacy ARPTABLES support
  "IP_NF_ARPFILTER" = no; # arptables-legacy packet filtering support
  ##### end of IP: Netfilter Configuration

  ##### IPv6: Netfilter Configuration
  "IP6_NF_IPTABLES_LEGACY" = module; # Legacy IP6 tables support
  "NF_SOCKET_IPV6" = no; # IPv6 socket lookup support
  "NF_TPROXY_IPV6" = no; # IPv6 tproxy support
  "NF_TABLES_IPV6" = yes; # IPv6 nf_tables support
  "NFT_DUP_IPV6" = no; # IPv6 nf_tables packet duplication support
  "NFT_FIB_IPV6" = module; # nf_tables fib / ipv6 route lookup support
  "NF_DUP_IPV6" = no; # Netfilter IPv6 packet duplication to alternate destination
  "NF_REJECT_IPV6" = module; # IPv6 packet rejection
  "NF_LOG_IPV6" = module; # IPv6 packet logging
  "IP6_NF_IPTABLES" = module; # IP6 tables support (required for filtering)
  "IP6_NF_MATCH_AH" = no; # "ah" match support
  "IP6_NF_MATCH_EUI64" = no; # "eui64" address check
  "IP6_NF_MATCH_FRAG" = no; # "frag" Fragmentation header match support
  "IP6_NF_MATCH_OPTS" = no; # "hbh" hop-by-hop and "dst" opts header match support
  "IP6_NF_MATCH_HL" = no; # "hl" hoplimit match support
  "IP6_NF_MATCH_IPV6HEADER" = no; # "ipv6header" IPv6 Extension Headers Match
  "IP6_NF_MATCH_MH" = no; # "mh" match support
  "IP6_NF_MATCH_RPFILTER" = no; # "rpfilter" reverse path filter match support
  "IP6_NF_MATCH_RT" = no; # "rt" Routing header match support
  "IP6_NF_MATCH_SRH" = no; # "srh" Segment Routing header match support
  "IP6_NF_TARGET_HL" = no; # "HL" hoplimit target support
  "IP6_NF_FILTER" = module; # Packet filtering
  "IP6_NF_TARGET_REJECT" = module; # REJECT target support
  "IP6_NF_TARGET_SYNPROXY" = no; # SYNPROXY target support
  "IP6_NF_MANGLE" = module; # Packet mangling
  "IP6_NF_RAW" = no; # raw table support (required for TRACE)
  "IP6_NF_SECURITY" = no; # Security table
  "IP6_NF_NAT" = module; # ip6tables NAT support
  "IP6_NF_TARGET_MASQUERADE" = module; # MASQUERADE target support
  "IP6_NF_TARGET_NPT" = no; # NPT (Network Prefix translation) target support
  ##### end of IPv6: Netfilter Configuration

  "NF_TABLES_BRIDGE" = no; # Ethernet Bridge nf_tables support
  "NF_CONNTRACK_BRIDGE" = no; # IPv4/IPV6 bridge connection tracking support
  "BRIDGE_NF_EBTABLES_LEGACY" = no; # Legacy EBTABLES support
  "BRIDGE_NF_EBTABLES" = no; # Ethernet Bridge tables (ebtables) support
  "IP_SCTP" = no; # The SCTP Protocol
  "RDS" = no; # The Reliable Datagram Sockets Protocol
  "TIPC" = no; # The TIPC Protocol
  "ATM" = no; # Asynchronous Transfer Mode (ATM)
  "L2TP" = no; # Layer Two Tunneling Protocol (L2TP)
  "BRIDGE" = module; # 802.1d Ethernet Bridging
  "BRIDGE_IGMP_SNOOPING" = yes; # IGMP/MLD snooping
  "BRIDGE_VLAN_FILTERING" = yes; # VLAN filtering
  "BRIDGE_MRP" = no; # MRP protocol
  "BRIDGE_CFM" = no; # CFM protocol
  "NET_DSA" = no; # Distributed Switch Architecture
  "VLAN_8021Q" = module; # 802.1Q/802.1ad VLAN Support
  "VLAN_8021Q_GVRP" = yes; # GVRP (GARP VLAN Registration Protocol) support
  "VLAN_8021Q_MVRP" = yes; # MVRP (Multiple VLAN Registration Protocol) support
  "LLC2" = no; # ANSI/IEEE 802.2 LLC type 2 Support
  "ATALK" = no; # Appletalk protocol support
  "X25" = no; # CCITT X.25 Packet Layer
  "LAPB" = no; # LAPB Data Link Driver
  "PHONET" = no; # Phonet protocols family
  "6LOWPAN" = no; # 6LoWPAN Support
  "IEEE802154" = no; # IEEE Std 802.15.4 Low-Rate Wireless Personal Area Networks support
  "NET_SCHED" = yes; # QoS and/or fair queueing
  "NET_SCH_HTB" = yes; # Hierarchical Token Bucket (HTB)
  "NET_SCH_HFSC" = no; # Hierarchical Fair Service Curve (HFSC)
  "NET_SCH_PRIO" = yes; # Multi Band Priority Queueing (PRIO)
  "NET_SCH_MULTIQ" = yes; # Hardware Multiqueue-aware Multi Band Queuing (MULTIQ)
  "NET_SCH_RED" = no; # Random Early Detection (RED)
  "NET_SCH_SFB" = no; # Stochastic Fair Blue (SFB)
  "NET_SCH_SFQ" = no; # Stochastic Fairness Queueing (SFQ)
  "NET_SCH_TEQL" = no; # True Link Equalizer (TEQL)
  "NET_SCH_TBF" = no; # Token Bucket Filter (TBF)
  "NET_SCH_CBS" = no; # Credit Based Shaper (CBS)
  "NET_SCH_ETF" = no; # Earliest TxTime First (ETF)
  "NET_SCH_TAPRIO" = no; # Time Aware Priority (taprio) Scheduler
  "NET_SCH_GRED" = no; # Generic Random Early Detection (GRED)
  "NET_SCH_NETEM" = no; # Network emulator (NETEM)
  "NET_SCH_DRR" = no; # Deficit Round Robin scheduler (DRR)
  "NET_SCH_MQPRIO" = no; # Multi-queue priority scheduler (MQPRIO)
  "NET_SCH_SKBPRIO" = no; # SKB priority queue scheduler (SKBPRIO)
  "NET_SCH_CHOKE" = no; # CHOose and Keep responsive flow scheduler (CHOKE)
  "NET_SCH_QFQ" = no; # Quick Fair Queueing scheduler (QFQ)
  "NET_SCH_CODEL" = no; # Controlled Delay AQM (CODEL)
  "NET_SCH_FQ_CODEL" = no; # Fair Queue Controlled Delay AQM (FQ_CODEL)
  "NET_SCH_CAKE" = no; # Common Applications Kept Enhanced (CAKE)
  "NET_SCH_FQ" = no; # Fair Queue
  "NET_SCH_HHF" = no; # Heavy-Hitter Filter (HHF)
  "NET_SCH_PIE" = no; # Proportional Integral controller Enhanced (PIE) scheduler
  "NET_SCH_PLUG" = no; # Plug network traffic until release (PLUG)
  "NET_SCH_ETS" = no; # Enhanced transmission selection scheduler (ETS)
  "NET_SCH_DEFAULT" = no; # Allow override default queue discipline
  "NET_CLS_BASIC" = no; # Elementary classification (BASIC)
  "NET_CLS_ROUTE4" = no; # Routing decision (ROUTE)
  "NET_CLS_FW" = no; # Netfilter mark (FW)
  "NET_CLS_U32" = no; # Universal 32bit comparisons w/ hashing (U32)
  "NET_CLS_FLOW" = no; # Flow classifier
  "NET_CLS_CGROUP" = module; # Control Group Classifier
  "NET_CLS_BPF" = no; # BPF-based classifier
  "NET_CLS_FLOWER" = no; # Flower classifier
  "NET_CLS_MATCHALL" = no; # Match-all classifier
  "NET_EMATCH" = no; # Extended Matches
  "NET_CLS_ACT" = no; # Actions
  "DCB" = no; # Data Center Bridging support
  "DNS_RESOLVER" = yes; # DNS Resolver support
  "BATMAN_ADV" = no; # B.A.T.M.A.N. Advanced Meshing Protocol
  "OPENVSWITCH" = no; # Open vSwitch
  "VSOCKETS" = no; # Virtual Socket protocol
  "NETLINK_DIAG" = module; # NETLINK: socket monitoring interface
  "MPLS" = no; # MultiProtocol Label Switching
  "NET_NSH" = no; # Network Service Header (NSH) protocol
  "HSR" = module; # High-availability Seamless Redundancy (HSR & PRP)
  "NET_SWITCHDEV" = yes; # Switch (and switch-ish) device support
  "NET_L3_MASTER_DEV" = yes; # L3 Master device support
  "QRTR" = module; # Qualcomm IPC Router support
  "QRTR_SMD" = module; # SMD IPC Router channels
  "QRTR_TUN" = module; # TUN device for Qualcomm IPC Router
  "QRTR_MHI" = module; # MHI IPC Router channels
  "NET_NCSI" = no; # NCSI interface support
  "PCPU_DEV_REFCNT" = yes; # Use percpu variables to maintain network device refcount
  "MAX_SKB_FRAGS" = freeform "17"; # Maximum number of fragments per skb_shared_info
  "RPS" = yes; # Receive packet steering
  "RFS_ACCEL" = yes; # Hardware acceleration of RFS
  "CGROUP_NET_PRIO" = yes; # Network priority cgroup
  "CGROUP_NET_CLASSID" = yes; # Network classid cgroup
  "BQL" = yes; # Enable Byte Queue Limits
  "BPF_STREAM_PARSER" = no; # enable BPF STREAM_PARSER
  "NET_FLOW_LIMIT" = yes; # Net flow limit

  #### Networking options -> Network testing
  "NET_PKTGEN" = no; # Packet Generator (USE WITH CAUTION)
  "NET_DROP_MONITOR" = no; # Network packet drop alerting service
  #### Networking options: end of Network testing
  ### end of Networking options

  "HAMRADIO" = no; # Amateur Radio support
  "CAN" = no; # CAN bus subsystem support
  "BT" = module; # Bluetooth subsystem support
  "BT_BREDR" = yes; # Bluetooth Classic (BR/EDR) features
  "BT_RFCOMM" = module; # RFCOMM protocol support
  "BT_RFCOMM_TTY" = yes; # RFCOMM TTY support
  "BT_BNEP" = module; # BNEP protocol support
  "BT_BNEP_MC_FILTER" = yes; # Multicast filter support
  "BT_BNEP_PROTO_FILTER" = yes; # Protocol filter support
  "BT_HIDP" = module; # HIDP protocol support
  "BT_LE" = yes; # Bluetooth Low Energy (LE) features
  "BT_LE_L2CAP_ECRED" = yes; # Bluetooth L2CAP Enhanced Credit Flow Control
  "BT_LEDS" = yes; # Enable LED triggers
  "BT_MSFTEXT" = no; # Enable Microsoft extensions
  "BT_AOSPEXT" = no; # Enable Android Open Source Project extensions
  "BT_DEBUGFS" = no; # Export Bluetooth internals in debugfs
  "BT_SELFTEST" = no; # Bluetooth self testing support

  #### Bluetooth device drivers
  "BT_HCIBTUSB" = module; # HCI USB driver
  "BT_HCIBTUSB_AUTOSUSPEND" = no; # Enable USB autosuspend for Bluetooth USB devices by default
  "BT_HCIBTUSB_POLL_SYNC" = yes; # Enable USB poll_sync for Bluetooth USB devices by default
  "BT_HCIBTUSB_BCM" = yes; # Broadcom protocol support
  "BT_HCIBTUSB_MTK" = yes; # MediaTek protocol support
  "BT_HCIBTUSB_RTL" = yes; # Realtek protocol support
  "BT_HCIBTSDIO" = no; # HCI SDIO driver
  "BT_HCIUART" = module; # HCI UART driver
  "BT_HCIUART_H4" = yes; # UART (H4) protocol support
  "BT_HCIUART_NOKIA" = no; # UART Nokia H4+ protocol support
  "BT_HCIUART_BCSP" = no; # BCSP protocol support
  "BT_HCIUART_ATH3K" = no; # Atheros AR300x serial support
  "BT_HCIUART_LL" = yes; # HCILL protocol support
  "BT_HCIUART_3WIRE" = no; # Three-wire UART (H5) protocol support
  "BT_HCIUART_INTEL" = no; # Intel protocol support
  "BT_HCIUART_BCM" = yes; # Broadcom protocol support
  "BT_HCIUART_RTL" = no; # Realtek protocol support
  "BT_HCIUART_QCA" = yes; # Qualcomm Atheros protocol support
  "BT_HCIUART_AG6XX" = no; # Intel AG6XX protocol support
  "BT_HCIUART_MRVL" = yes; # Marvell protocol support
  "BT_HCIUART_AML" = no; # Amlogic protocol support
  "BT_HCIBCM203X" = no; # HCI BCM203x USB driver
  "BT_HCIBCM4377" = no; # HCI BCM4377/4378/4387/4388 PCIe driver
  "BT_HCIBPA10X" = no; # HCI BPA10x USB driver
  "BT_HCIBFUSB" = no; # HCI BlueFRITZ! USB driver
  "BT_HCIVHCI" = no; # HCI VHCI (Virtual HCI device) driver
  "BT_MRVL" = module; # Marvell Bluetooth driver support
  "BT_MRVL_SDIO" = module; # Marvell BT-over-SDIO driver
  "BT_ATH3K" = no; # Atheros firmware download driver
  "BT_MTKSDIO" = no; # MediaTek HCI SDIO driver
  "BT_MTKUART" = no; # MediaTek HCI UART driver
  "BT_QCOMSMD" = module; # Qualcomm SMD based HCI support
  "BT_VIRTIO" = no; # Virtio Bluetooth driver
  "BT_NXPUART" = module; # NXP protocol support
  "BT_INTEL_PCIE" = no; # Intel HCI PCIe driver
  #### end of Bluetooth device drivers

  "AF_RXRPC" = no; # RxRPC session sockets
  "AF_KCM" = no; # KCM sockets
  "MCTP" = no; # MCTP core protocol support
  "WIRELESS" = yes; # Wireless
  "CFG80211" = module; # cfg80211 - wireless configuration API
  "NL80211_TESTMODE" = no; # nl80211 testmode command
  "CFG80211_DEVELOPER_WARNINGS" = no; # enable developer warnings
  "CFG80211_DEFAULT_PS" = yes; # enable powersave by default
  "CFG80211_DEBUGFS" = no; # cfg80211 DebugFS entries
  "CFG80211_WEXT" = no; # cfg80211 wireless extensions compatibility
  "MAC80211" = module; # Generic IEEE 802.11 Networking Stack (mac80211)
  "MAC80211_RC_DEFAULT_MINSTREL" = yes; # Minstrel
  "MAC80211_MESH" = no; # Enable mac80211 mesh networking support
  "MAC80211_LEDS" = yes; # Enable LED triggers
  "MAC80211_MESSAGE_TRACING" = no; # Trace all mac80211 debug messages
  "MAC80211_DEBUG_MENU" = no; # Select mac80211 debugging features
  "RFKILL" = module; # RF switch subsystem support
  "RFKILL_GPIO" = module; # GPIO RFKILL driver
  "NET_9P" = no; # Plan 9 Resource Sharing Support (9P2000)
  "CAIF" = no; # CAIF support
  "CEPH_LIB" = no; # Ceph core library
  "NFC" = module; # NFC subsystem support
  "NFC_DIGITAL" = no; # NFC Digital Protocol stack support
  "NFC_NCI" = module; # NCI protocol support
  "NFC_NCI_SPI" = no; # NCI over SPI protocol support
  "NFC_NCI_UART" = no; # NCI over UART protocol support
  "NFC_HCI" = no; # NFC HCI implementation

  #### Near Field Communication (NFC) devices
  "NFC_VIRTUAL_NCI" = no; # NCI device simulator driver
  "NFC_FDP" = no; # Intel FDP NFC driver
  "NFC_PN533_USB" = no; # NFC PN533 device support (USB)
  "NFC_PN533_I2C" = no; # NFC PN533 device support (I2C)
  "NFC_PN532_UART" = no; # NFC PN532 device support (UART)
  "NFC_MRVL_USB" = no; # Marvell NFC-over-USB driver
  "NFC_ST_NCI_I2C" = no; # STMicroelectronics ST NCI NFC driver (I2C)
  "NFC_ST_NCI_SPI" = no; # STMicroelectronics ST NCI NFC driver (SPI)
  "NFC_NXP_NCI" = no; # NXP-NCI NFC driver
  "NFC_S3FWRN5_I2C" = module; # Samsung S3FWRN5 I2C support
  "NFC_S3FWRN82_UART" = no; # Samsung S3FWRN82 UART support
  #### end of Near Field Communication (NFC) devices

  "PSAMPLE" = no; # Packet-sampling netlink channel
  "NET_IFE" = no; # Inter-FE based on IETF ForCES InterFE LFB
  "LWTUNNEL" = no; # Network light weight tunnels
  "PAGE_POOL_STATS" = yes; # Page pool stats
  "FAILOVER" = yes; # Generic failover module
  "ETHTOOL_NETLINK" = yes; # Netlink interface for ethtool

  ## Device Drivers
  "PCI" = yes; # PCI support
  "PCIEPORTBUS" = yes; # PCI Express Port Bus support
  "HOTPLUG_PCI_PCIE" = no; # PCI Express Hotplug driver
  "PCIEAER" = yes; # PCI Express Advanced Error Reporting support
  "PCIEAER_INJECT" = no; # PCI Express error injection support
  "PCIE_ECRC" = no; # PCI Express ECRC settings control
  "PCIEASPM" = yes; # PCI Express ASPM control
  "PCIEASPM_DEFAULT" = yes; # BIOS default
  "PCIEASPM_POWERSAVE" = no; # Powersave
  "PCIEASPM_POWER_SUPERSAVE" = no; # Power Supersave
  "PCIEASPM_PERFORMANCE" = no; # Performance
  "PCIE_DPC" = no; # PCI Express Downstream Port Containment support
  "PCIE_PTM" = no; # PCI Express Precision Time Measurement support
  "PCI_MSI" = yes; # Message Signaled Interrupts (MSI and MSI-X)
  "PCI_DEBUG" = no; # PCI Debugging
  "PCI_REALLOC_ENABLE_AUTO" = no; # Enable PCI resource re-allocation detection
  "PCI_STUB" = no; # PCI Stub driver
  "PCI_PF_STUB" = no; # PCI PF Stub driver
  "PCI_DOE" = no; # Enable PCI Data Object Exchange (DOE) support
  "PCI_IOV" = yes; # PCI IOV support
  "PCI_NPEM" = no; # Native PCIe Enclosure Management
  "PCI_PRI" = no; # PCI PRI support
  "PCI_PASID" = no; # PCI PASID support
  "PCIE_TPH" = no; # TLP Processing Hints
  "PCI_DYNAMIC_OF_NODES" = no; # Create Device tree nodes for PCI devices
  "VGA_ARB" = yes; # VGA Arbitration
  "VGA_ARB_MAX_GPUS" = freeform "16"; # Maximum number of GPUs
  "HOTPLUG_PCI" = yes; # Support for PCI Hotplug
  "HOTPLUG_PCI_ACPI" = yes; # ACPI PCI Hotplug driver
  "HOTPLUG_PCI_ACPI_AMPERE_ALTRA" = no; # ACPI PCI Hotplug driver Ampere Altra extensions
  "HOTPLUG_PCI_ACPI_IBM" = no; # ACPI PCI Hotplug driver IBM extensions
  "HOTPLUG_PCI_CPCI" = no; # CompactPCI Hotplug driver
  "HOTPLUG_PCI_OCTEONEP" = no; # Marvell OCTEON PCI Hotplug driver
  "HOTPLUG_PCI_SHPC" = no; # SHPC PCI Hotplug driver

  #### PCI controller drivers
  "PCIE_ALTERA" = no; # Altera PCIe controller
  "PCI_HOST_THUNDER_PEM" = no; # Cavium Thunder PCIe controller to off-chip devices
  "PCI_HOST_THUNDER_ECAM" = no; # Cavium Thunder ECAM controller to on-chip devices on pass-1.x silicon
  "PCI_FTPCI100" = no; # Faraday Technology FTPCI100 PCI controller
  "PCI_HOST_GENERIC" = yes; # Generic PCI host controller
  "PCIE_HISI_ERR" = no; # HiSilicon HIP PCIe controller error handling driver
  "PCIE_MEDIATEK" = no; # MediaTek PCIe controller
  "PCIE_MEDIATEK_GEN3" = module; # MediaTek Gen3 PCIe controller
  "PCI_XGENE" = no; # X-Gene PCIe controller
  "PCIE_XILINX" = no; # Xilinx AXI PCIe controller

  ##### PCI controller drivers -> Cadence-based PCIe controllers
  "PCIE_CADENCE_PLAT_HOST" = no; # Cadence platform PCIe controller (host mode)
  "PCIE_CADENCE_PLAT_EP" = no; # Cadence platform PCIe controller (endpoint mode)
  ##### PCI controller drivers: end of Cadence-based PCIe controllers

  ##### PCI controller drivers -> DesignWare-based PCIe controllers
  "PCIE_DW_DEBUGFS" = no; # DesignWare PCIe debugfs entries
  "PCIE_AL" = no; # Amazon Annapurna Labs PCIe controller
  "PCIE_AMD_MDB" = no; # AMD MDB Versal2 PCIe controller
  "PCI_MESON" = module; # Amlogic Meson PCIe controller
  "PCI_HISI" = no; # HiSilicon Hip05 and Hip06 SoCs PCIe controller
  "PCIE_KIRIN" = no; # HiSilicon Kirin PCIe controller
  "PCIE_DW_PLAT_HOST" = no; # Platform bus based DesignWare PCIe controller (host mode)
  "PCIE_DW_PLAT_EP" = no; # Platform bus based DesignWare PCIe controller (endpoint mode)
  "PCIE_QCOM" = yes; # Qualcomm PCIe controller (host mode)
  "PCIE_QCOM_EP" = no; # Qualcomm PCIe controller (endpoint mode)
  ##### PCI controller drivers: end of DesignWare-based PCIe controllers

  ##### PCI controller drivers -> PLDA-based PCIe controllers
  "PCIE_MICROCHIP_HOST" = no; # Microchip AXI PCIe controller
  ##### PCI controller drivers: end of PLDA-based PCIe controllers
  #### end of PCI controller drivers

  #### PCI Endpoint
  "PCI_ENDPOINT" = yes; # PCI Endpoint Support
  "PCI_ENDPOINT_CONFIGFS" = yes; # PCI Endpoint Configfs Support
  "PCI_EPF_TEST" = module; # PCI Endpoint Test driver
  "PCI_EPF_NTB" = no; # PCI Endpoint NTB driver
  #### end of PCI Endpoint

  #### PCI switch controller drivers
  "PCI_SW_SWITCHTEC" = no; # MicroSemi Switchtec PCIe Switch Management Driver
  #### end of PCI switch controller drivers

  "PCI_PWRCTRL_SLOT" = no; # PCI Power Control driver for PCI slots
  "CXL_BUS" = no; # CXL (Compute Express Link) Devices Support
  "PCCARD" = no; # PCCard (PCMCIA/CardBus) support
  "RAPIDIO" = no; # RapidIO support

  ### Device Drivers -> Generic Driver Options
  "UEVENT_HELPER" = yes; # Support for uevent helper
  "DEVTMPFS" = yes; # Maintain a devtmpfs filesystem to mount at /dev
  "DEVTMPFS_MOUNT" = yes; # Automount devtmpfs at /dev, after the kernel mounted the rootfs
  "DEVTMPFS_SAFE" = no; # Use nosuid,noexec mount options on devtmpfs
  "STANDALONE" = yes; # Select only drivers that don't need compile-time external firmware
  "PREVENT_FIRMWARE_BUILD" = yes; # Disable drivers features which enable custom firmware building

  #### Device Drivers -> Generic Driver Options -> Firmware loader
  "FW_LOADER" = yes; # Firmware loading facility
  "FW_LOADER_DEBUG" = yes; # Log filenames and checksums for loaded firmware
  "FW_LOADER_USER_HELPER" = no; # Enable the firmware sysfs fallback mechanism
  "FW_LOADER_COMPRESS" = yes; # Enable compressed firmware support
  "FW_LOADER_COMPRESS_XZ" = yes; # Enable XZ-compressed firmware support
  "FW_LOADER_COMPRESS_ZSTD" = yes; # Enable ZSTD-compressed firmware support
  "FW_CACHE" = yes; # Enable firmware caching during suspend
  "FW_UPLOAD" = yes; # Enable users to initiate firmware updates using sysfs
  #### Device Drivers -> Generic Driver Options: end of Firmware loader

  "DEBUG_DRIVER" = no; # Driver Core verbose debug messages
  "DEBUG_DEVRES" = no; # Managed device resources verbose debug messages
  "DEBUG_TEST_DRIVER_REMOVE" = no; # Test driver remove calls during probe (UNSTABLE)
  "TEST_ASYNC_DRIVER_PROBE" = no; # Build kernel module to test asynchronous driver probing
  "DMA_FENCE_TRACE" = no; # Enable verbose DMA_FENCE_TRACE messages
  "FW_DEVLINK_SYNC_STATE_TIMEOUT" = no; # sync_state() behavior defaults to timeout instead of strict
  ### Device Drivers: end of Generic Driver Options

  ### Device Drivers -> Bus devices
  "MOXTET" = no; # CZ.NIC Turris Mox module configuration bus
  "QCOM_EBI2" = yes; # Qualcomm External Bus Interface 2 (EBI2)
  "QCOM_SSC_BLOCK_BUS" = no; # Qualcomm SSC Block Bus Init Driver
  "STM32_FIREWALL" = yes; # STM32 Firewall framework
  "VEXPRESS_CONFIG" = yes; # Versatile Express configuration bus
  "MHI_BUS" = module; # Modem Host Interface (MHI) bus
  "MHI_BUS_DEBUG" = no; # Debugfs support for the MHI bus
  "MHI_BUS_PCI_GENERIC" = module; # MHI PCI controller driver
  "MHI_BUS_EP" = no; # Modem Host Interface (MHI) bus Endpoint implementation
  ### Device Drivers: end of Bus devices
  "CONNECTOR" = no; # Connector - unified userspace <-> kernelspace linker

  ### Device Drivers -> Firmware Drivers

  #### Device Drivers -> Firmware Drivers -> ARM System Control and Management Interface Protocol
  "ARM_SCMI_PROTOCOL" = yes; # ARM System Control and Management Interface (SCMI) Message Protocol
  "ARM_SCMI_RAW_MODE_SUPPORT" = no; # Enable support for SCMI Raw transmission mode
  "ARM_SCMI_DEBUG_COUNTERS" = no; # Enable SCMI communication debug metrics tracking
  "ARM_SCMI_QUIRKS" = yes; # Enable SCMI Quirks framework

  ###### SCMI Transport Drivers
  "ARM_SCMI_TRANSPORT_MAILBOX" = yes; # SCMI transport based on Mailbox
  "ARM_SCMI_TRANSPORT_SMC" = yes; # SCMI transport based on SMC
  "ARM_SCMI_TRANSPORT_SMC_ATOMIC_ENABLE" = no; # Enable atomic mode support for SCMI SMC transport
  "ARM_SCMI_TRANSPORT_OPTEE" = yes; # SCMI transport based on OP-TEE service
  "ARM_SCMI_TRANSPORT_VIRTIO" = no; # SCMI transport based on VirtIO
  ###### end of SCMI Transport Drivers

  ###### ARM SCMI NXP i.MX Vendor Protocols
  "IMX_SCMI_BBM_EXT" = yes; # i.MX SCMI BBM EXTENSION
  ###### end of ARM SCMI NXP i.MX Vendor Protocols

  "ARM_SCMI_POWER_CONTROL" = no; # SCMI system power control driver
  #### Device Drivers -> Firmware Drivers: end of ARM System Control and Management Interface Protocol

  "ARM_SCPI_PROTOCOL" = yes; # ARM System Control and Power Interface (SCPI) Message Protocol
  "ARM_SDE_INTERFACE" = yes; # ARM Software Delegated Exception Interface (SDEI)
  "DMIID" = yes; # Export DMI identification via sysfs to userspace
  "DMI_SYSFS" = no; # DMI table support in sysfs
  "ISCSI_IBFT" = no; # iSCSI Boot Firmware Table Attributes module
  "FW_CFG_SYSFS" = no; # QEMU fw_cfg device support in sysfs
  "SYSFB_SIMPLEFB" = no; # Mark VGA/VBE/EFI FB as generic system framebuffer
  "ARM_FFA_TRANSPORT" = no; # Arm Firmware Framework for Armv8-A
  "GOOGLE_FIRMWARE" = yes; # Google Firmware Drivers
  "GOOGLE_CBMEM" = module; # CBMEM entries in sysfs
  "GOOGLE_COREBOOT_TABLE" = module; # Coreboot Table Access
  "GOOGLE_FRAMEBUFFER_COREBOOT" = no; # Coreboot Framebuffer
  "GOOGLE_MEMCONSOLE_COREBOOT" = no; # Firmware Memory Console
  "GOOGLE_VPD" = no; # Vital Product Data

  #### Device Drivers -> Firmware Drivers -> EFI (Extensible Firmware Interface) Support
  "EFI_VARS_PSTORE" = yes; # Register efivars backend for pstore
  "EFI_VARS_PSTORE_DEFAULT_DISABLE" = no; # Disable using efivars as a pstore backend by default
  "EFI_SOFT_RESERVE" = yes; # Reserve EFI Specific Purpose Memory
  "EFI_ZBOOT" = yes; # Enable the generic EFI decompressor
  "EFI_ARMSTUB_DTB_LOADER" = yes; # Enable the DTB loader
  "EFI_BOOTLOADER_CONTROL" = no; # EFI Bootloader Control
  "EFI_CAPSULE_LOADER" = yes; # EFI capsule loader
  "EFI_TEST" = no; # EFI Runtime Service Tests Support
  "RESET_ATTACK_MITIGATION" = no; # Reset memory attack mitigation
  "EFI_DISABLE_PCI_DMA" = no; # Clear Busmaster bit on PCI bridges during ExitBootServices()
  "EFI_CUSTOM_SSDT_OVERLAYS" = yes; # Load custom ACPI SSDT overlay from an EFI variable
  "EFI_DISABLE_RUNTIME" = no; # Disable EFI runtime services support by default
  "EFI_COCO_SECRET" = no; # EFI Confidential Computing Secret Area Support
  #### Device Drivers -> Firmware Drivers: end of EFI (Extensible Firmware Interface) Support

  "TEE_STMM_EFI" = no; # TEE-based EFI runtime variable service driver
  "ARM_PSCI_CHECKER" = no; # ARM PSCI checker

  #### Device Drivers -> Firmware Drivers -> Qualcomm firmware drivers
  "QCOM_TZMEM_MODE_GENERIC" = no; # Generic
  "QCOM_TZMEM_MODE_SHMBRIDGE" = yes; # SHM Bridge
  "QCOM_QSEECOM" = yes; # Qualcomm QSEECOM interface driver
  "QCOM_QSEECOM_UEFISECAPP" = yes; # Qualcomm SEE UEFI Secure App client driver
  #### Device Drivers -> Firmware Drivers: end of Qualcomm firmware drivers

  "ARM_SMCCC_SOC_ID" = yes; # SoC bus device for the ARM SMCCC SOC_ID
  ### Device Drivers: end of Firmware Drivers

  "FWCTL" = no; # fwctl device firmware access framework
  "GNSS" = module; # GNSS receiver support
  "GNSS_MTK_SERIAL" = no; # Mediatek GNSS receiver support
  "GNSS_SIRF_SERIAL" = no; # SiRFstar GNSS receiver support
  "GNSS_UBX_SERIAL" = no; # u-blox GNSS receiver support
  "GNSS_USB" = no; # USB GNSS receiver support
  "MTD" = no; # Memory Technology Device (MTD) support
  "OF" = yes; # Device Tree and Open Firmware support
  "OF_UNITTEST" = no; # Device Tree runtime unit tests
  "OF_OVERLAY" = no; # Device Tree overlays
  "PARPORT" = no; # Parallel port support
  "PNP" = yes; # Plug and Play support
  "PNP_DEBUG_MESSAGES" = yes; # PNP debugging messages
  "BLK_DEV" = yes; # Block devices
  "BLK_DEV_NULL_BLK" = no; # Null test block driver
  "BLK_DEV_PCIESSD_MTIP32XX" = no; # Block Device Driver for Micron PCIe SSDs
  "ZRAM" = module; # Compressed RAM block device support
  "ZRAM_BACKEND_LZ4" = no; # lz4 compression support
  "ZRAM_BACKEND_LZ4HC" = no; # lz4hc compression support
  "ZRAM_BACKEND_ZSTD" = yes; # zstd compression support
  "ZRAM_BACKEND_DEFLATE" = no; # deflate compression support
  "ZRAM_BACKEND_842" = no; # 842 compression support
  "ZRAM_BACKEND_LZO" = no; # lzo and lzo-rle compression support
  "ZRAM_DEF_COMP_ZSTD" = yes; # zstd
  "ZRAM_WRITEBACK" = no; # Write back incompressible or idle page to backing device
  "ZRAM_TRACK_ENTRY_ACTIME" = yes; # Track access time of zram entries
  "ZRAM_MEMORY_TRACKING" = yes; # Track zRam block status
  "ZRAM_MULTI_COMP" = yes; # Enable multiple compression streams
  "BLK_DEV_LOOP" = yes; # Loopback device support
  "BLK_DEV_LOOP_MIN_COUNT" = freeform "8"; # Number of loop devices to pre-create at init time
  "BLK_DEV_DRBD" = no; # DRBD Distributed Replicated Block Device support
  "BLK_DEV_NBD" = module; # Network block device support
  "BLK_DEV_RAM" = yes; # RAM block device support
  "BLK_DEV_RAM_COUNT" = freeform "16"; # Default number of RAM disks
  "BLK_DEV_RAM_SIZE" = freeform "8192"; # Default RAM disk size (kbytes)
  "CDROM_PKTCDVD" = no; # Packet writing on CD/DVD media (DEPRECATED)
  "ATA_OVER_ETH" = no; # ATA over Ethernet support
  "XEN_BLKDEV_FRONTEND" = yes; # Xen virtual block device support
  "XEN_BLKDEV_BACKEND" = no; # Xen block-device backend driver
  "VIRTIO_BLK" = yes; # Virtio block driver
  "BLK_DEV_RBD" = no; # Rados block device (RBD)
  "BLK_DEV_UBLK" = no; # Userspace block driver (Experimental)

  ### Device Drivers -> NVME Support
  "BLK_DEV_NVME" = no; # NVM Express block device
  "NVME_FC" = no; # NVM Express over Fabrics FC host driver
  "NVME_TCP" = no; # NVM Express over Fabrics TCP host driver
  "NVME_TARGET" = no; # NVMe Target support
  ### Device Drivers: end of NVME Support

  ### Device Drivers -> Misc devices
  "AD525X_DPOT" = no; # Analog Devices Digital Potentiometers
  "DUMMY_IRQ" = no; # Dummy IRQ handler
  "PHANTOM" = no; # Sensable PHANToM (PCI)
  "RPMB" = no; # RPMB partition interface
  "TI_FPC202" = no; # TI FPC202 Dual Port Controller
  "TIFM_CORE" = no; # TI Flash Media interface support
  "ICS932S401" = no; # Integrated Circuits ICS932S401
  "ENCLOSURE_SERVICES" = no; # Enclosure Services
  "HI6421V600_IRQ" = no; # HiSilicon Hi6421v600 IRQ and powerkey
  "HP_ILO" = no; # Channel interface driver for the HP iLO processor
  "QCOM_COINCELL" = module; # Qualcomm coincell charger support
  "QCOM_FASTRPC" = module; # Qualcomm FastRPC
  "APDS9802ALS" = no; # Medfield Avago APDS9802 ALS Sensor module
  "ISL29003" = no; # Intersil ISL29003 ambient light sensor
  "ISL29020" = no; # Intersil ISL29020 ambient light sensor
  "SENSORS_TSL2550" = no; # Taos TSL2550 ambient light sensor
  "SENSORS_BH1770" = no; # BH1770GLC / SFH7770 combined ALS - Proximity sensor
  "SENSORS_APDS990X" = no; # APDS990X combined als and proximity sensors
  "HMC6352" = no; # Honeywell HMC6352 compass
  "DS1682" = no; # Dallas DS1682 Total Elapsed Time Recorder with Alarm
  "LATTICE_ECP3_CONFIG" = no; # Lattice ECP3 FPGA bitstream configuration via SPI
  "SRAM" = no; # Generic on-chip SRAM driver
  "DW_XDATA_PCIE" = no; # Synopsys DesignWare xData PCIe driver
  "PCI_ENDPOINT_TEST" = module; # PCI Endpoint Test driver
  "XILINX_SDFEC" = no; # Xilinx SDFEC 16
  "HISI_HIKEY_USB" = no; # USB GPIO Hub on HiSilicon Hikey 960/970 Platform
  "OPEN_DICE" = no; # Open Profile for DICE driver
  "NTSYNC" = no; # NT synchronization primitive emulation
  "VCPU_STALL_DETECTOR" = no; # Guest vCPU stall detector
  "TPS6594_ESM" = module; # TI TPS6594 Error Signal Monitor support
  "TPS6594_PFSM" = module; # TI TPS6594 Pre-configurable Finite State Machine support
  "NSM" = no; # Nitro (Enclaves) Security Module support
  "C2PORT" = no; # Silicon Labs C2 port support

  #### Device Drivers -> Misc devices -> EEPROM support
  "EEPROM_AT24" = no; # I2C EEPROMs / RAMs / ROMs from most vendors
  "EEPROM_AT25" = no; # SPI EEPROMs (FRAMs) from most vendors
  "EEPROM_MAX6875" = no; # Maxim MAX6874/5 power supply supervisor
  "EEPROM_93CX6" = yes; # EEPROM 93CX6 support
  "EEPROM_93XX46" = no; # Microwire EEPROM 93XX46 support
  "EEPROM_IDT_89HPESX" = no; # IDT 89HPESx PCIe-switches EEPROM / CSR support
  "EEPROM_EE1004" = no; # SPD EEPROMs on DDR4 memory modules
  #### Device Drivers -> Misc devices: end of EEPROM support

  "CB710_CORE" = no; # ENE CB710/720 Flash memory card reader support
  "SENSORS_LIS3_I2C" = no; # STMicroeletronics LIS3LV02Dx three-axis digital accelerometer (I2C)
  "ALTERA_STAPL" = no; # Altera FPGA firmware download module
  "VMWARE_VMCI" = no; # VMware VMCI Driver
  "GENWQE" = no; # GenWQE PCIe Accelerator
  "BCM_VK" = no; # Support for Broadcom VK Accelerators
  "MISC_ALCOR_PCI" = no; # Alcor Micro/Alcor Link PCI-E card reader
  "MISC_RTSX_PCI" = no; # Realtek PCI-E card reader
  "MISC_RTSX_USB" = no; # Realtek USB card reader
  "UACCE" = no; # Accelerator Framework for User Land
  "PVPANIC" = no; # pvpanic device support
  "GP_PCI1XXXX" = no; # Microchip PCI1XXXX PCIe to GPIO Expander + OTP/EEPROM manager
  "KEBA_CP500" = no; # KEBA CP500 system FPGA support
  "AMD_SBRMI_I2C" = no; # AMD side band RMI support
  ### Device Drivers: end of Misc devices

  ### Device Drivers -> SCSI device support
  "RAID_ATTRS" = module; # RAID Transport Class
  "SCSI" = yes; # SCSI device support
  "SCSI_PROC_FS" = no; # legacy /proc/scsi/ support
  "BLK_DEV_SD" = yes; # SCSI disk support
  "CHR_DEV_ST" = no; # SCSI tape support
  "BLK_DEV_SR" = no; # SCSI CDROM support
  "CHR_DEV_SG" = no; # SCSI generic support
  "BLK_DEV_BSG" = yes; # /dev/bsg support (SG v4)
  "CHR_DEV_SCH" = no; # SCSI media changer support
  "SCSI_CONSTANTS" = no; # Verbose SCSI error reporting (kernel size += 36K)
  "SCSI_LOGGING" = no; # SCSI logging facility
  "SCSI_SCAN_ASYNC" = yes; # Asynchronous SCSI scanning

  #### Device Drivers -> SCSI device support -> SCSI Transports
  "SCSI_SPI_ATTRS" = no; # Parallel SCSI (SPI) Transport Attributes
  "SCSI_FC_ATTRS" = no; # FiberChannel Transport Attributes
  "SCSI_ISCSI_ATTRS" = no; # iSCSI Transport Attributes
  "SCSI_SAS_ATTRS" = yes; # SAS Transport Attributes
  "SCSI_SAS_LIBSAS" = yes; # SAS Domain Transport Attributes
  "SCSI_SAS_HOST_SMP" = yes; # Support for SMP interpretation for SAS hosts
  "SCSI_SRP_ATTRS" = no; # SRP Transport Attributes
  #### Device Drivers -> SCSI device support: end of SCSI Transports

  "SCSI_LOWLEVEL" = yes; # SCSI low-level drivers
  "ISCSI_TCP" = no; # iSCSI Initiator over TCP/IP
  "ISCSI_BOOT_SYSFS" = no; # iSCSI Boot Sysfs Interface
  "SCSI_CXGB3_ISCSI" = no; # Chelsio T3 iSCSI support
  "SCSI_CXGB4_ISCSI" = no; # Chelsio T4 iSCSI support
  "SCSI_BNX2_ISCSI" = no; # QLogic NetXtreme II iSCSI support
  "BE2ISCSI" = no; # Emulex 10Gbps iSCSI - BladeEngine 2
  "BLK_DEV_3W_XXXX_RAID" = no; # 3ware 5/6/7/8xxx ATA-RAID support
  "SCSI_HPSA" = no; # HP Smart Array SCSI driver
  "SCSI_3W_9XXX" = no; # 3ware 9xxx SATA-RAID support
  "SCSI_3W_SAS" = no; # 3ware 97xx SAS/SATA-RAID support
  "SCSI_ACARD" = no; # ACARD SCSI support
  "SCSI_AACRAID" = no; # Adaptec AACRAID support
  "SCSI_AIC7XXX" = no; # Adaptec AIC7xxx Fast -> U160 support
  "SCSI_AIC79XX" = no; # Adaptec AIC79xx U320 support
  "SCSI_AIC94XX" = no; # Adaptec AIC94xx SAS/SATA support
  "SCSI_MVSAS" = no; # Marvell 88SE64XX/88SE94XX SAS/SATA support
  "SCSI_MVUMI" = no; # Marvell UMI driver
  "SCSI_ADVANSYS" = no; # AdvanSys SCSI support
  "SCSI_ARCMSR" = no; # ARECA (ARC11xx/12xx/13xx/16xx) SATA/SAS RAID Host Adapter
  "SCSI_ESAS2R" = no; # ATTO Technology's ExpressSAS RAID adapter driver
  "MEGARAID_NEWGEN" = no; # LSI Logic New Generation RAID Device Drivers
  "MEGARAID_LEGACY" = no; # LSI Logic Legacy MegaRAID Driver
  "MEGARAID_SAS" = no; # LSI Logic MegaRAID SAS RAID Module
  "SCSI_MPT3SAS" = no; # LSI MPT Fusion SAS 3.0 & SAS 2.0 Device Driver
  "SCSI_MPT2SAS" = no; # Legacy MPT2SAS config option
  "SCSI_MPI3MR" = no; # Broadcom MPI3 Storage Controller Device Driver
  "SCSI_SMARTPQI" = no; # Microchip PQI Driver
  "SCSI_HPTIOP" = no; # HighPoint RocketRAID 3xxx/4xxx Controller support
  "SCSI_BUSLOGIC" = no; # BusLogic SCSI support
  "SCSI_MYRB" = no; # Mylex DAC960/DAC1100 PCI RAID Controller (Block Interface)
  "SCSI_MYRS" = no; # Mylex DAC960/DAC1100 PCI RAID Controller (SCSI Interface)
  "XEN_SCSI_FRONTEND" = no; # XEN SCSI frontend driver
  "SCSI_SNIC" = no; # Cisco SNIC Driver
  "SCSI_DMX3191D" = no; # DMX3191D SCSI support
  "SCSI_FDOMAIN_PCI" = no; # Future Domain TMC-3260/AHA-2920A PCI SCSI support
  "SCSI_IPS" = no; # IBM ServeRAID support
  "SCSI_INITIO" = no; # Initio 9100U(W) support
  "SCSI_INIA100" = no; # Initio INI-A100U2W support
  "SCSI_STEX" = no; # Promise SuperTrak EX Series support
  "SCSI_SYM53C8XX_2" = no; # SYM53C8XX Version 2 SCSI support
  "SCSI_IPR" = no; # IBM Power Linux RAID adapter support
  "SCSI_QLOGIC_1280" = no; # Qlogic QLA 1240/1x80/1x160 SCSI support
  "SCSI_QLA_ISCSI" = no; # QLogic ISP4XXX and ISP82XX host adapter family support
  "SCSI_DC395x" = no; # Tekram DC395(U/UW/F) and DC315(U) SCSI support
  "SCSI_AM53C974" = no; # Tekram DC390(T) and Am53/79C974 SCSI support (new driver)
  "SCSI_WD719X" = no; # Western Digital WD7193/7197/7296 support
  "SCSI_DEBUG" = no; # SCSI debugging host and device simulator
  "SCSI_PMCRAID" = no; # PMC SIERRA Linux MaxRAID adapter support
  "SCSI_PM8001" = no; # PMC-Sierra SPC 8001 SAS/SATA Based Host Adapter driver
  "SCSI_VIRTIO" = no; # virtio-scsi support
  "SCSI_DH" = no; # SCSI Device Handlers
  ### Device Drivers: end of SCSI device support

  "ATA" = no; # Serial ATA and Parallel ATA drivers (libata)
  "MD" = yes; # Multiple devices driver support (RAID and LVM)
  "BLK_DEV_MD" = no; # RAID support
  "MD_BITMAP_FILE" = yes; # MD bitmap file support (deprecated)
  "BCACHE" = no; # Block device as cache
  "BLK_DEV_DM" = yes; # Device mapper support
  "DM_DEBUG" = no; # Device mapper debugging support
  "DM_DEBUG_BLOCK_MANAGER_LOCKING" = no; # Block manager locking
  "DM_UNSTRIPED" = no; # Unstriped target
  "DM_CRYPT" = yes; # Crypt target support
  "DM_SNAPSHOT" = no; # Snapshot target
  "DM_THIN_PROVISIONING" = yes; # Thin provisioning target
  "DM_CACHE" = no; # Cache target (EXPERIMENTAL)
  "DM_WRITECACHE" = no; # Writecache target
  "DM_EBS" = no; # Emulated block size target (EXPERIMENTAL)
  "DM_ERA" = no; # Era target (EXPERIMENTAL)
  "DM_CLONE" = no; # Clone target (EXPERIMENTAL)
  "DM_MIRROR" = no; # Mirror target
  "DM_RAID" = no; # RAID 1/4/5/6/10 target
  "DM_ZERO" = no; # Zero target
  "DM_MULTIPATH" = no; # Multipath target
  "DM_DELAY" = no; # I/O delaying target
  "DM_DUST" = no; # Bad sector simulation target
  "DM_INIT" = no; # DM "dm-mod.create=" parameter support
  "DM_UEVENT" = no; # DM uevents
  "DM_FLAKEY" = no; # Flakey target
  "DM_VERITY" = no; # Verity target support
  "DM_SWITCH" = no; # Switch target support (EXPERIMENTAL)
  "DM_LOG_WRITES" = no; # Log writes target support
  "DM_INTEGRITY" = yes; # Integrity target support
  "DM_AUDIT" = yes; # DM audit events
  "DM_VDO" = no; # VDO: deduplication and compression target
  "TARGET_CORE" = no; # Generic Target Core Mod (TCM) and ConfigFS Infrastructure
  "FUSION" = no; # Fusion MPT device support

  ### Device Drivers -> IEEE 1394 (FireWire) support
  "FIREWIRE" = no; # FireWire driver stack
  "FIREWIRE_NOSY" = no; # Nosy - a FireWire traffic sniffer for PCILynx cards
  ### Device Drivers: end of IEEE 1394 (FireWire) support

  "NETDEVICES" = yes; # Network device support
  "NET_CORE" = yes; # Network core driver support
  "BONDING" = no; # Bonding driver support
  "DUMMY" = module; # Dummy net driver support
  "WIREGUARD" = module; # WireGuard secure network tunnel
  "WIREGUARD_DEBUG" = no; # Debugging checks and verbose messages
  "OVPN" = no; # OpenVPN data channel offload
  "EQUALIZER" = no; # EQL (serial line load balancing) support
  "NET_FC" = no; # Fibre Channel driver support
  "NET_TEAM" = no; # Ethernet team driver support
  "MACVLAN" = module; # MAC-VLAN support
  "MACVTAP" = module; # MAC-VLAN based tap driver
  "IPVLAN" = module; # IP-VLAN support
  "IPVTAP" = no; # IP-VLAN based tap driver
  "VXLAN" = module; # Virtual eXtensible Local Area Network (VXLAN)
  "GENEVE" = no; # Generic Network Virtualization Encapsulation
  "BAREUDP" = no; # Bare UDP Encapsulation
  "GTP" = no; # GPRS Tunneling Protocol datapath (GTP-U)
  "PFCP" = no; # Packet Forwarding Control Protocol (PFCP)
  "AMT" = no; # Automatic Multicast Tunneling (AMT)
  "MACSEC" = no; # IEEE 802.1AE MAC-level encryption (MACsec)
  "NETCONSOLE" = no; # Network console logging support
  "TUN" = yes; # Universal TUN/TAP device driver support
  "TUN_VNET_CROSS_LE" = no; # Support for cross-endian vnet headers on little-endian kernels
  "VETH" = module; # Virtual ethernet pair device
  "VIRTIO_NET" = yes; # Virtio network driver
  "NLMON" = no; # Virtual netlink monitoring device
  "NETKIT" = no; # BPF-programmable network device
  "NET_VRF" = no; # Virtual Routing and Forwarding (Lite)
  "MHI_NET" = module; # MHI network driver
  "ARCNET" = no; # ARCnet support
  "ETHERNET" = yes; # Ethernet driver support
  "NET_VENDOR_3COM" = yes; # 3Com devices
  "VORTEX" = no; # 3c590/3c900 series (592/595/597) "Vortex/Boomerang" support
  "TYPHOON" = no; # 3cr990 series "Typhoon" support
  "NET_VENDOR_ADAPTEC" = yes; # Adaptec devices
  "ADAPTEC_STARFIRE" = no; # Adaptec Starfire/DuraLAN support
  "NET_VENDOR_AGERE" = yes; # Agere devices
  "ET131X" = no; # Agere ET-1310 Gigabit Ethernet support
  "NET_VENDOR_AIROHA" = no; # Airoha devices
  "NET_VENDOR_ALACRITECH" = yes; # Alacritech devices
  "SLICOSS" = no; # Alacritech Slicoss support
  "NET_VENDOR_ALTEON" = yes; # Alteon devices
  "ACENIC" = no; # Alteon AceNIC/3Com 3C985/NetGear GA620 Gigabit support
  "ALTERA_TSE" = no; # Altera Triple-Speed Ethernet MAC support
  "NET_VENDOR_AMAZON" = yes; # Amazon Devices
  "ENA_ETHERNET" = module; # Elastic Network Adapter (ENA) support
  "NET_VENDOR_AMD" = yes; # AMD devices
  "AMD8111_ETH" = no; # AMD 8111 (new PCI LANCE) support
  "PCNET32" = no; # AMD PCnet32 PCI support
  "AMD_XGBE" = yes; # AMD 10GbE Ethernet driver
  "PDS_CORE" = no; # AMD/Pensando Data Systems Core Device Support
  "NET_VENDOR_AQUANTIA" = yes; # aQuantia devices
  "AQTION" = no; # aQuantia AQtion(tm) Support
  "NET_VENDOR_ARC" = yes; # ARC devices
  "NET_VENDOR_ASIX" = yes; # Asix devices
  "SPI_AX88796C" = no; # Asix AX88796C-SPI support
  "NET_VENDOR_ATHEROS" = yes; # Atheros devices
  "ATL2" = no; # Atheros L2 Fast Ethernet support
  "ATL1" = no; # Atheros/Attansic L1 Gigabit Ethernet support
  "ATL1E" = no; # Atheros L1E Gigabit Ethernet support
  "ATL1C" = no; # Atheros L1C Gigabit Ethernet support
  "ALX" = no; # Qualcomm Atheros AR816x/AR817x support
  "NET_VENDOR_BROADCOM" = yes; # Broadcom devices
  "B44" = no; # Broadcom 440x/47xx ethernet support
  "BCMGENET" = module; # Broadcom GENET internal MAC support
  "BNX2" = no; # QLogic bnx2 support
  "CNIC" = no; # QLogic CNIC support
  "TIGON3" = no; # Broadcom Tigon3 support
  "BNX2X" = no; # Broadcom NetXtremeII 10Gb support
  "SYSTEMPORT" = module; # Broadcom SYSTEMPORT internal MAC support
  "BNXT" = no; # Broadcom NetXtreme-C/E support
  "NET_VENDOR_CADENCE" = yes; # Cadence devices
  "MACB" = no; # Cadence MACB/GEM support
  "NET_VENDOR_CAVIUM" = yes; # Cavium ethernet drivers
  "THUNDER_NIC_PF" = yes; # Thunder Physical function driver
  "THUNDER_NIC_VF" = no; # Thunder Virtual function driver
  "THUNDER_NIC_BGX" = yes; # Thunder MAC interface driver (BGX)
  "THUNDER_NIC_RGX" = yes; # Thunder MAC interface driver (RGX)
  "CAVIUM_PTP" = no; # Cavium PTP coprocessor as PTP clock
  "LIQUIDIO" = no; # Cavium LiquidIO support
  "LIQUIDIO_VF" = no; # Cavium LiquidIO VF support
  "NET_VENDOR_CHELSIO" = yes; # Chelsio devices
  "CHELSIO_T1" = no; # Chelsio 10Gb Ethernet support
  "CHELSIO_T3" = no; # Chelsio Communications T3 10Gb Ethernet support
  "CHELSIO_T4" = no; # Chelsio Communications T4/T5/T6 Ethernet support
  "CHELSIO_T4VF" = no; # Chelsio Communications T4/T5/T6 Virtual Function Ethernet support
  "NET_VENDOR_CISCO" = yes; # Cisco devices
  "ENIC" = no; # Cisco VIC Ethernet NIC Support
  "NET_VENDOR_CORTINA" = yes; # Cortina Gemini devices
  "GEMINI_ETHERNET" = no; # Gemini Gigabit Ethernet support
  "NET_VENDOR_DAVICOM" = yes; # Davicom devices
  "DM9051" = no; # DM9051 SPI support
  "DNET" = no; # Dave ethernet support (DNET)
  "NET_VENDOR_DEC" = yes; # Digital Equipment devices
  "NET_TULIP" = no; # DEC - Tulip devices
  "NET_VENDOR_DLINK" = yes; # D-Link devices
  "DL2K" = no; # DL2000/TC902x/IP1000A-based Gigabit Ethernet support
  "NET_VENDOR_EMULEX" = yes; # Emulex devices
  "BE2NET" = no; # ServerEngines' 10Gbps NIC - BladeEngine
  "NET_VENDOR_ENGLEDER" = yes; # Engleder devices
  "TSNEP" = no; # TSN endpoint support
  "NET_VENDOR_EZCHIP" = yes; # EZchip devices
  "EZCHIP_NPS_MANAGEMENT_ENET" = no; # EZchip NPS management enet support
  "NET_VENDOR_FUNGIBLE" = yes; # Fungible devices
  "FUN_ETH" = no; # Fungible Ethernet device driver
  "NET_VENDOR_GOOGLE" = yes; # Google Devices
  "GVE" = no; # Google Virtual NIC (gVNIC) support
  "NET_VENDOR_HISILICON" = yes; # Hisilicon devices
  "HIX5HD2_GMAC" = no; # Hisilicon HIX5HD2 Family Network Device Support
  "HISI_FEMAC" = no; # Hisilicon Fast Ethernet MAC device support
  "HIP04_ETH" = no; # HISILICON P04 Ethernet support
  "HNS_DSAF" = no; # Hisilicon HNS DSAF device Support
  "HNS_ENET" = no; # Hisilicon HNS Ethernet Device Support
  "HNS3" = no; # Hisilicon Network Subsystem Support HNS3 (Framework)
  "HIBMCGE" = no; # Hisilicon BMC Gigabit Ethernet Device Support
  "NET_VENDOR_HUAWEI" = yes; # Huawei devices
  "HINIC" = no; # Huawei Intelligent PCIE Network Interface Card
  "HINIC3" = no; # Huawei 3rd generation network adapters (HINIC3) support
  "NET_VENDOR_I825XX" = yes; # Intel (82586/82593/82596) devices
  "NET_VENDOR_INTEL" = yes; # Intel devices
  "E100" = no; # Intel(R) PRO/100+ support
  "E1000" = yes; # Intel(R) PRO/1000 Gigabit Ethernet support
  "E1000E" = yes; # Intel(R) PRO/1000 PCI-Express Gigabit Ethernet support
  "IGB" = no; # Intel(R) 82575/82576 PCI-Express Gigabit Ethernet support
  "IGBVF" = no; # Intel(R) 82576 Virtual Function Ethernet support
  "IXGBE" = no; # Intel(R) 10GbE PCI Express adapters support
  "IXGBEVF" = no; # Intel(R) 10GbE PCI Express Virtual Function Ethernet support
  "I40E" = no; # Intel(R) Ethernet Controller XL710 Family support
  "I40EVF" = no; # Intel(R) Ethernet Adaptive Virtual Function support
  "ICE" = no; # Intel(R) Ethernet Connection E800 Series Support
  "FM10K" = no; # Intel(R) FM10000 Ethernet Switch Host Interface Support
  "IGC" = no; # Intel(R) Ethernet Controller I225-LM/I225-V support
  "IDPF" = no; # Intel(R) Infrastructure Data Path Function Support
  "JME" = no; # JMicron(R) PCI-Express Gigabit Ethernet support
  "NET_VENDOR_ADI" = no; # Analog Devices devices
  "NET_VENDOR_LITEX" = yes; # LiteX devices
  "LITEX_LITEETH" = no; # LiteX Ethernet support
  "NET_VENDOR_MARVELL" = yes; # Marvell devices
  "MVMDIO" = yes; # Marvell MDIO interface support
  "SKGE" = no; # Marvell Yukon Gigabit Ethernet support
  "SKY2" = yes; # Marvell Yukon 2 support
  "SKY2_DEBUG" = no; # Debugging interface
  "OCTEONTX2_AF" = no; # Marvell OcteonTX2 RVU Admin Function driver
  "OCTEONTX2_PF" = no; # Marvell OcteonTX2 NIC Physical Function driver
  "OCTEON_EP" = no; # Marvell Octeon PCI Endpoint NIC Driver
  "OCTEON_EP_VF" = no; # Marvell Octeon PCI Endpoint NIC VF Driver
  "PRESTERA" = no; # Marvell Prestera Switch ASICs support
  "NET_VENDOR_MEDIATEK" = yes; # MediaTek devices
  "NET_MEDIATEK_SOC" = no; # MediaTek SoC Gigabit Ethernet support
  "NET_MEDIATEK_STAR_EMAC" = module; # MediaTek STAR Ethernet MAC support
  "NET_VENDOR_MELLANOX" = yes; # Mellanox devices
  "MLX4_EN" = no; # Mellanox Technologies 1/10/40Gbit Ethernet support
  "MLX5_CORE" = no; # Mellanox 5th generation network adapters (ConnectX series) core driver
  "MLXSW_CORE" = no; # Mellanox Technologies Switch ASICs support
  "MLXFW" = no; # Mellanox Technologies firmware flash module
  "MLXBF_GIGE" = no; # Mellanox Technologies BlueField Gigabit Ethernet support
  "NET_VENDOR_META" = yes; # Meta Platforms devices
  "NET_VENDOR_MICREL" = yes; # Micrel devices
  "KS8842" = no; # Micrel KSZ8841/42 with generic bus interface
  "KS8851" = no; # Micrel KS8851 SPI
  "KS8851_MLL" = no; # Micrel KS8851 MLL
  "KSZ884X_PCI" = no; # Micrel KSZ8841/2 PCI
  "NET_VENDOR_MICROCHIP" = yes; # Microchip devices
  "ENC28J60" = no; # ENC28J60 support
  "ENCX24J600" = no; # ENCX24J600 support
  "LAN743X" = no; # LAN743x support
  "LAN865X" = no; # LAN865x support
  "LAN966X_SWITCH" = no; # Lan966x switch driver
  "VCAP" = no; # VCAP (Versatile Content-Aware Processor) library
  "NET_VENDOR_MICROSEMI" = yes; # Microsemi devices
  "MSCC_OCELOT_SWITCH" = no; # Ocelot switch driver
  "NET_VENDOR_MICROSOFT" = yes; # Microsoft Network Devices
  "NET_VENDOR_MYRI" = yes; # Myricom devices
  "MYRI10GE" = no; # Myricom Myri-10G Ethernet support
  "FEALNX" = no; # Myson MTD-8xx PCI Ethernet support
  "NET_VENDOR_NI" = no; # National Instruments Devices
  "NET_VENDOR_NATSEMI" = yes; # National Semiconductor devices
  "NATSEMI" = no; # National Semiconductor DP8381x series PCI Ethernet support
  "NS83820" = no; # National Semiconductor DP83820 support
  "NET_VENDOR_NETERION" = yes; # Neterion (Exar) devices
  "S2IO" = no; # Neterion (Exar) Xframe 10Gb Ethernet Adapter
  "NET_VENDOR_NETRONOME" = yes; # Netronome(R) devices
  "NFP" = no; # Netronome(R) NFP4000/NFP6000 NIC driver
  "NET_VENDOR_8390" = yes; # National Semiconductor 8390 devices
  "NE2K_PCI" = no; # PCI NE2000 and clones support (see help)
  "NET_VENDOR_NVIDIA" = yes; # NVIDIA devices
  "FORCEDETH" = no; # nForce Ethernet support
  "NET_VENDOR_OKI" = yes; # OKI Semiconductor devices
  "ETHOC" = no; # OpenCores 10/100 Mbps Ethernet MAC support
  "NET_VENDOR_PACKET_ENGINES" = yes; # Packet Engines devices
  "HAMACHI" = no; # Packet Engines Hamachi GNIC-II support
  "YELLOWFIN" = no; # Packet Engines Yellowfin Gigabit-NIC support
  "NET_VENDOR_PENSANDO" = yes; # Pensando devices
  "IONIC" = no; # Pensando Ethernet IONIC Support
  "NET_VENDOR_QLOGIC" = yes; # QLogic devices
  "QLA3XXX" = no; # QLogic QLA3XXX Network Driver Support
  "QLCNIC" = no; # QLOGIC QLCNIC 1/10Gb Converged Ethernet NIC Support
  "NETXEN_NIC" = no; # NetXen Multi port (1/10) Gigabit Ethernet NIC
  "QED" = no; # QLogic QED 25/40/100Gb core driver
  "NET_VENDOR_BROCADE" = yes; # QLogic BR-series devices
  "BNA" = no; # QLogic BR-series 1010/1020/1860 10Gb Ethernet Driver support
  "NET_VENDOR_QUALCOMM" = yes; # Qualcomm devices
  "QCA7000_SPI" = no; # Qualcomm Atheros QCA7000 SPI support
  "QCA7000_UART" = no; # Qualcomm Atheros QCA7000 UART support
  "QCOM_EMAC" = module; # Qualcomm Technologies, Inc. EMAC Gigabit Ethernet support
  "RMNET" = module; # RmNet MAP driver
  "NET_VENDOR_RDC" = yes; # RDC devices
  "R6040" = no; # RDC R6040 Fast Ethernet Adapter support
  "NET_VENDOR_REALTEK" = yes; # Realtek devices
  "8139CP" = no; # RealTek RTL-8139 C+ PCI Fast Ethernet Adapter support
  "8139TOO" = no; # RealTek RTL-8129/8130/8139 PCI Fast Ethernet Adapter support
  "R8169" = module; # Realtek 8169/8168/8101/8125 ethernet support
  "RTASE" = no; # Realtek Automotive Switch 9054/9068/9072/9075/9068/9071 PCIe Interface support
  "NET_VENDOR_RENESAS" = yes; # Renesas devices
  "NET_VENDOR_ROCKER" = yes; # Rocker devices
  "ROCKER" = no; # Rocker switch driver (EXPERIMENTAL)
  "NET_VENDOR_SAMSUNG" = yes; # Samsung Ethernet devices
  "SXGBE_ETH" = no; # Samsung 10G/2.5G/1G SXGBE Ethernet driver
  "NET_VENDOR_SEEQ" = yes; # SEEQ devices
  "NET_VENDOR_SILAN" = yes; # Silan devices
  "SC92031" = no; # Silan SC92031 PCI Fast Ethernet Adapter driver
  "NET_VENDOR_SIS" = yes; # Silicon Integrated Systems (SiS) devices
  "SIS900" = no; # SiS 900/7016 PCI Fast Ethernet Adapter support
  "SIS190" = no; # SiS190/SiS191 gigabit ethernet support
  "NET_VENDOR_SOLARFLARE" = yes; # Solarflare devices
  "SFC" = no; # Solarflare SFC9100/EF100-family support
  "SFC_FALCON" = no; # Solarflare SFC4000 support
  "SFC_SIENA" = no; # Solarflare SFC9000 support
  "NET_VENDOR_SMSC" = yes; # SMC (SMSC)/Western Digital devices
  "SMC91X" = no; # SMC 91C9x/91C1xxx support
  "EPIC100" = no; # SMC EtherPower II
  "SMSC911X" = yes; # SMSC LAN911x/LAN921x families embedded ethernet support
  "SMSC9420" = no; # SMSC LAN9420 PCI ethernet adapter support
  "NET_VENDOR_SOCIONEXT" = no; # Socionext ethernet drivers
  "NET_VENDOR_STMICRO" = yes; # STMicroelectronics devices
  "STMMAC_ETH" = no; # STMicroelectronics Multi-Gigabit Ethernet driver
  "NET_VENDOR_SUN" = yes; # Sun devices
  "HAPPYMEAL" = no; # Sun Happy Meal 10/100baseT support
  "SUNGEM" = no; # Sun GEM support
  "CASSINI" = no; # Sun Cassini support
  "NIU" = no; # Sun Neptune 10Gbit Ethernet support
  "NET_VENDOR_SYNOPSYS" = yes; # Synopsys devices
  "DWC_XLGMAC" = no; # Synopsys DWC Enterprise Ethernet (XLGMAC) driver support
  "NET_VENDOR_TEHUTI" = yes; # Tehuti devices
  "TEHUTI" = no; # Tehuti Networks 10G Ethernet
  "TEHUTI_TN40" = no; # Tehuti Networks TN40xx 10G Ethernet adapters
  "NET_VENDOR_TI" = yes; # Texas Instruments (TI) devices
  "TI_CPSW_PHY_SEL" = no; # TI CPSW Phy mode Selection (DEPRECATED)
  "TLAN" = no; # TI ThunderLAN support
  "NET_VENDOR_VERTEXCOM" = yes; # Vertexcom devices
  "MSE102X" = no; # Vertexcom MSE102x SPI
  "NET_VENDOR_VIA" = yes; # VIA devices
  "VIA_RHINE" = no; # VIA Rhine support
  "VIA_VELOCITY" = no; # VIA Velocity support
  "NET_VENDOR_WANGXUN" = yes; # Wangxun devices
  "NGBE" = no; # Wangxun(R) GbE PCI Express adapters support
  "NET_VENDOR_WIZNET" = yes; # WIZnet devices
  "WIZNET_W5100" = no; # WIZnet W5100 Ethernet support
  "WIZNET_W5300" = no; # WIZnet W5300 Ethernet support
  "NET_VENDOR_XILINX" = yes; # Xilinx devices
  "XILINX_EMACLITE" = no; # Xilinx 10/100 Ethernet Lite support
  "XILINX_LL_TEMAC" = no; # Xilinx LL TEMAC (LocalLink Tri-mode Ethernet MAC) driver
  "FDDI" = no; # FDDI driver support
  "HIPPI" = no; # HIPPI driver support
  "QCOM_IPA" = module; # Qualcomm IPA support
  "PHYLIB" = yes; # PHY Device support and infrastructure
  "LED_TRIGGER_PHY" = no; # Support LED triggers for tracking link state
  "FIXED_PHY" = yes; # MDIO Bus/PHY emulation with fixed speed/link PHYs
  "SFP" = no; # SFP cage support
  "AS21XXX_PHY" = no; # Aeonsemi AS21xxx PHYs
  "AIR_EN8811H_PHY" = no; # Airoha EN8811H 2.5 Gigabit PHY
  "AMD_PHY" = no; # AMD and Altima PHYs
  "ADIN_PHY" = no; # Analog Devices Industrial Ethernet PHYs
  "ADIN1100_PHY" = no; # Analog Devices Industrial Ethernet T1L PHYs
  "AQUANTIA_PHY" = no; # Aquantia PHYs
  "AX88796B_PHY" = module; # Asix PHYs
  "BROADCOM_PHY" = module; # Broadcom 54XX PHYs
  "BCM54140_PHY" = module; # Broadcom BCM54140 PHY
  "BCM7XXX_PHY" = module; # Broadcom 7xxx SOCs internal PHYs
  "BCM84881_PHY" = no; # Broadcom BCM84881 PHY
  "BCM87XX_PHY" = no; # Broadcom BCM8706 and BCM8727 PHYs
  "CICADA_PHY" = no; # Cicada PHYs
  "CORTINA_PHY" = no; # Cortina EDC CDR 10G Ethernet PHY
  "DAVICOM_PHY" = no; # Davicom PHYs
  "ICPLUS_PHY" = no; # ICPlus PHYs
  "LXT_PHY" = no; # Intel LXT PHYs
  "INTEL_XWAY_PHY" = no; # Intel XWAY PHYs
  "LSI_ET1011C_PHY" = no; # LSI ET1011C PHY
  "MARVELL_PHY" = module; # Marvell Alaska PHYs
  "MARVELL_10G_PHY" = yes; # Marvell Alaska 10Gbit PHYs
  "MARVELL_88Q2XXX_PHY" = yes; # Marvell 88Q2XXX PHY
  "MARVELL_88X2222_PHY" = no; # Marvell 88X2222 PHY
  "MAXLINEAR_GPHY" = no; # Maxlinear Ethernet PHYs
  "MAXLINEAR_86110_PHY" = no; # MaxLinear MXL86110 PHY support
  "MEDIATEK_GE_PHY" = no; # MediaTek Gigabit Ethernet PHYs
  "MEDIATEK_GE_SOC_PHY" = no; # MediaTek SoC Ethernet PHYs
  "MICREL_PHY" = no; # Micrel PHYs
  "MICROCHIP_T1S_PHY" = no; # Microchip 10BASE-T1S Ethernet PHYs
  "MICROCHIP_PHY" = module; # Microchip PHYs
  "MICROCHIP_T1_PHY" = no; # Microchip T1 PHYs
  "MICROSEMI_PHY" = no; # Microsemi PHYs
  "MOTORCOMM_PHY" = no; # Motorcomm PHYs
  "NATIONAL_PHY" = no; # National Semiconductor PHYs
  "NXP_CBTX_PHY" = no; # NXP 100BASE-TX PHYs
  "NXP_C45_TJA11XX_PHY" = no; # NXP C45 TJA11XX PHYs
  "NXP_TJA11XX_PHY" = no; # NXP TJA11xx PHYs support
  "NCN26000_PHY" = no; # Onsemi 10BASE-T1S Ethernet PHY
  "AT803X_PHY" = yes; # Qualcomm Atheros AR803X PHYs
  "QCA83XX_PHY" = no; # Qualcomm Atheros QCA833x PHYs
  "QCA808X_PHY" = no; # Qualcomm QCA808x PHYs
  "QCA807X_PHY" = no; # Qualcomm QCA807x PHYs
  "QSEMI_PHY" = no; # Quality Semiconductor PHYs
  "REALTEK_PHY" = module; # Realtek PHYs
  "REALTEK_PHY_HWMON" = no; # HWMON support for Realtek PHYs
  "RENESAS_PHY" = no; # Renesas PHYs
  "ROCKCHIP_PHY" = yes; # Rockchip Ethernet PHYs
  "SMSC_PHY" = module; # SMSC PHYs
  "STE10XP" = no; # STMicroelectronics STe10Xp PHYs
  "TERANETICS_PHY" = no; # Teranetics PHYs
  "DP83822_PHY" = no; # Texas Instruments DP83822/825/826 PHYs
  "DP83TC811_PHY" = no; # Texas Instruments DP83TC811 PHY
  "DP83848_PHY" = no; # Texas Instruments DP83848 PHY
  "DP83867_PHY" = yes; # Texas Instruments DP83867 Gigabit PHY
  "DP83869_PHY" = module; # Texas Instruments DP83869 Gigabit PHY
  "DP83TD510_PHY" = yes; # Texas Instruments DP83TD510 Ethernet 10Base-T1L PHY
  "DP83TG720_PHY" = no; # Texas Instruments DP83TG720 Ethernet 1000Base-T1 PHY
  "VITESSE_PHY" = no; # Vitesse PHYs
  "XILINX_GMII2RGMII" = no; # Xilinx GMII2RGMII converter driver
  "MICREL_KS8995MA" = no; # Micrel KS8995MA 5-ports 10/100 managed Ethernet switch
  "PSE_CONTROLLER" = no; # Ethernet Power Sourcing Equipment Support
  "MDIO_BUS" = yes; # MDIO bus consumer layer
  "MDIO_BITBANG" = yes; # Bitbanged MDIO buses
  "MDIO_BCM_UNIMAC" = yes; # Broadcom UniMAC MDIO bus controller
  "MDIO_GPIO" = yes; # GPIO lib-based bitbanged MDIO buses
  "MDIO_HISI_FEMAC" = no; # Hisilicon FEMAC MDIO bus controller
  "MDIO_MVUSB" = no; # Marvell USB to MDIO Adapter
  "MDIO_MSCC_MIIM" = no; # Microsemi MIIM interface support
  "MDIO_OCTEON" = no; # Octeon and some ThunderX SOCs MDIO buses
  "MDIO_IPQ4019" = no; # Qualcomm IPQ4019 MDIO interface support
  "MDIO_IPQ8064" = no; # Qualcomm IPQ8064 MDIO interface support
  "MDIO_THUNDER" = yes; # ThunderX SOCs MDIO buses
  "MDIO_BUS_MUX_GPIO" = no; # GPIO controlled MDIO bus multiplexers
  "MDIO_BUS_MUX_MULTIPLEXER" = no; # MDIO bus multiplexer using kernel multiplexer subsystem
  "MDIO_BUS_MUX_MMIOREG" = no; # MMIO device-controlled MDIO bus multiplexers

  #### PCS device drivers
  "PCS_XPCS" = module; # Synopsys DesignWare Ethernet XPCS
  #### end of PCS device drivers

  "PPP" = no; # PPP (point-to-point protocol) support
  "SLIP" = no; # SLIP (serial line) support
  "USB_NET_DRIVERS" = yes; # USB Network Adapters
  "USB_CATC" = no; # USB CATC NetMate-based Ethernet device support
  "USB_KAWETH" = no; # USB KLSI KL5USB101-based ethernet device support
  "USB_PEGASUS" = module; # USB Pegasus/Pegasus-II based ethernet device support
  "USB_RTL8150" = module; # USB RTL8150 based ethernet device support
  "USB_RTL8152" = module; # Realtek RTL8152/RTL8153 Based USB Ethernet Adapters
  "USB_LAN78XX" = module; # Microchip LAN78XX Based USB Ethernet Adapters
  "USB_USBNET" = module; # Multi-purpose USB Networking Framework
  "USB_NET_AX8817X" = module; # ASIX AX88xxx Based USB 2.0 Ethernet Adapters
  "USB_NET_AX88179_178A" = module; # ASIX AX88179/178A USB 3.0/2.0 to Gigabit Ethernet
  "USB_NET_CDCETHER" = module; # CDC Ethernet support (smart devices such as cable modems)
  "USB_NET_CDC_EEM" = no; # CDC EEM support
  "USB_NET_CDC_NCM" = module; # CDC NCM support
  "USB_NET_HUAWEI_CDC_NCM" = no; # Huawei NCM embedded AT channel support
  "USB_NET_CDC_MBIM" = no; # CDC MBIM support
  "USB_NET_DM9601" = module; # Davicom DM96xx based USB 10/100 ethernet devices
  "USB_NET_SR9700" = no; # CoreChip-sz SR9700 based USB 1.1 10/100 ethernet devices
  "USB_NET_SR9800" = module; # CoreChip-sz SR9800 based USB 2.0 10/100 ethernet devices
  "USB_NET_SMSC75XX" = module; # SMSC LAN75XX based USB 2.0 gigabit ethernet devices
  "USB_NET_SMSC95XX" = module; # SMSC LAN95XX based USB 2.0 10/100 ethernet devices
  "USB_NET_GL620A" = no; # GeneSys GL620USB-A based cables
  "USB_NET_NET1080" = module; # NetChip 1080 based cables (Laplink, ...)
  "USB_NET_PLUSB" = no; # Prolific PL-2301/2302/25A1/27A1 based cables
  "USB_NET_MCS7830" = module; # MosChip MCS7830 based Ethernet adapters
  "USB_NET_RNDIS_HOST" = no; # Host for RNDIS and ActiveSync devices
  "USB_NET_CDC_SUBSET" = module; # Simple USB Network Links (CDC Ethernet subset)
  "USB_ALI_M5632" = no; # ALi M5632 based 'USB 2.0 Data Link' cables
  "USB_AN2720" = no; # AnchorChips 2720 based cables (Xircom PGUNET, ...)
  "USB_BELKIN" = yes; # eTEK based host-to-host cables (Advance, Belkin, ...)
  "USB_ARMLINUX" = yes; # Embedded ARM Linux links (iPaq, ...)
  "USB_EPSON2888" = no; # Epson 2888 based firmware (DEVELOPMENT)
  "USB_KC2190" = no; # KT Technology KC2190 based cables (InstaNet)
  "USB_NET_ZAURUS" = module; # Sharp Zaurus (stock ROMs) and compatible
  "USB_NET_CX82310_ETH" = no; # Conexant CX82310 USB ethernet port
  "USB_NET_KALMIA" = no; # Samsung Kalmia based LTE USB modem
  "USB_NET_QMI_WWAN" = no; # QMI WWAN driver for Qualcomm MSM based 3G and LTE modems
  "USB_HSO" = no; # Option USB High Speed Mobile Devices
  "USB_NET_INT51X1" = no; # Intellon PLC based usb adapter
  "USB_IPHETH" = no; # Apple iPhone USB Ethernet driver
  "USB_SIERRA_NET" = no; # USB-to-WWAN Driver for Sierra Wireless modems
  "USB_VL600" = no; # LG VL600 modem dongle
  "USB_NET_CH9200" = no; # QingHeng CH9200 USB ethernet support
  "USB_NET_AQC111" = no; # Aquantia AQtion USB to 5/2.5GbE Controllers support
  "WLAN" = yes; # Wireless LAN
  "WLAN_VENDOR_ADMTEK" = yes; # ADMtek devices
  "ADM8211" = no; # ADMtek ADM8211 support
  "WLAN_VENDOR_ATH" = yes; # Atheros/Qualcomm devices
  "ATH_DEBUG" = no; # Atheros wireless debugging
  "ATH5K" = no; # Atheros 5xxx wireless cards support
  "ATH5K_PCI" = no; # Atheros 5xxx PCI bus support
  "ATH9K" = no; # Atheros 802.11n wireless cards support
  "ATH9K_HTC" = no; # Atheros HTC based wireless cards support
  "CARL9170" = no; # Linux Community AR9170 802.11n USB support
  "ATH6KL" = no; # Atheros mobile chipsets support
  "AR5523" = no; # Atheros AR5523 wireless driver support
  "WIL6210" = no; # Wilocity 60g WiFi card wil6210 support
  "ATH10K" = module; # Atheros 802.11ac wireless cards support
  "ATH10K_PCI" = no; # Atheros ath10k PCI support
  "ATH10K_SDIO" = module; # Atheros ath10k SDIO support
  "ATH10K_USB" = no; # Atheros ath10k USB support (EXPERIMENTAL)
  "ATH10K_SNOC" = module; # Qualcomm ath10k SNOC support
  "ATH10K_DEBUG" = yes; # Atheros ath10k debugging
  "ATH10K_DEBUGFS" = yes; # Atheros ath10k debugfs support
  "ATH10K_SPECTRAL" = yes; # Atheros ath10k spectral scan support
  "ATH10K_TRACING" = no; # Atheros ath10k tracing support
  "WCN36XX" = module; # Qualcomm Atheros WCN3660/3680 support
  "WCN36XX_DEBUGFS" = no; # WCN36XX debugfs support
  "ATH11K" = module; # Qualcomm Technologies 802.11ax chipset support
  "ATH11K_AHB" = module; # Atheros ath11k AHB support
  "ATH11K_PCI" = module; # Atheros ath11k PCI support
  "ATH11K_DEBUG" = no; # QCA ath11k debugging
  "ATH11K_TRACING" = no; # ath11k tracing support
  "ATH12K" = module; # Qualcomm Technologies Wi-Fi 7 support (ath12k)
  "ATH12K_AHB" = no; # QTI ath12k AHB support
  "ATH12K_DEBUG" = no; # ath12k debugging
  "ATH12K_TRACING" = no; # ath12k tracing support
  "ATH12K_COREDUMP" = no; # ath12k coredump
  "WLAN_VENDOR_ATMEL" = yes; # Atmel devices
  "AT76C50X_USB" = no; # Atmel at76c503/at76c505/at76c505a USB cards
  "WLAN_VENDOR_BROADCOM" = yes; # Broadcom devices
  "B43" = no; # Broadcom 43xx wireless support (mac80211 stack)
  "B43LEGACY" = no; # Broadcom 43xx-legacy wireless support (mac80211 stack)
  "BRCMSMAC" = no; # Broadcom IEEE802.11n PCIe SoftMAC WLAN driver
  "BRCMFMAC" = no; # Broadcom FullMAC WLAN driver
  "WLAN_VENDOR_INTEL" = yes; # Intel devices
  "IPW2100" = no; # Intel PRO/Wireless 2100 Network Connection
  "IPW2200" = no; # Intel PRO/Wireless 2200BG and 2915ABG Network Connection
  "IWL4965" = no; # Intel Wireless WiFi 4965AGN (iwl4965)
  "IWL3945" = no; # Intel PRO/Wireless 3945ABG/BG Network Connection (iwl3945)
  "IWLWIFI" = module; # Intel Wireless WiFi Next Gen AGN - Wireless-N/Advanced-N/Ultimate-N (iwlwifi)
  "IWLDVM" = module; # Intel Wireless WiFi DVM Firmware support
  "IWLMVM" = module; # Intel Wireless WiFi MVM Firmware support
  "IWLMLD" = no; # Intel Wireless WiFi MLD Firmware support

  ####### Debugging Options
  "IWLWIFI_DEBUG" = no; # Enable full debugging output in the iwlwifi driver
  "IWLWIFI_DEVICE_TRACING" = yes; # iwlwifi device access tracing
  ####### end of Debugging Options

  "WLAN_VENDOR_INTERSIL" = yes; # Intersil devices
  "P54_COMMON" = no; # Softmac Prism54 support
  "WLAN_VENDOR_MARVELL" = yes; # Marvell devices
  "LIBERTAS" = no; # Marvell 8xxx Libertas WLAN driver support
  "LIBERTAS_THINFIRM" = no; # Marvell 8xxx Libertas WLAN driver support with thin firmware
  "MWIFIEX" = module; # Marvell WiFi-Ex Driver
  "MWIFIEX_SDIO" = module; # Marvell WiFi-Ex Driver for SD8786/SD8787/SD8797/SD8887/SD8897/SD8977/SD8978/SD8987/SD8997
  "MWIFIEX_PCIE" = module; # Marvell WiFi-Ex Driver for PCIE 8766/8897/8997
  "MWIFIEX_USB" = no; # Marvell WiFi-Ex Driver for USB8766/8797/8997
  "MWL8K" = no; # Marvell 88W8xxx PCI/PCIe Wireless support
  "WLAN_VENDOR_MEDIATEK" = yes; # MediaTek devices
  "MT7601U" = no; # MediaTek MT7601U (USB) support
  "MT76x0U" = no; # MediaTek MT76x0U (USB) support
  "MT76x0E" = no; # MediaTek MT76x0E (PCIe) support
  "MT76x2E" = no; # MediaTek MT76x2E (PCIe) support
  "MT76x2U" = no; # MediaTek MT76x2U (USB) support
  "MT7603E" = no; # MediaTek MT7603E (PCIe) and MT76x8 WLAN support
  "MT7615E" = no; # MediaTek MT7615E and MT7663E (PCIe) support
  "MT7663U" = no; # MediaTek MT7663U (USB) support
  "MT7663S" = no; # MediaTek MT7663S (SDIO) support
  "MT7915E" = no; # MediaTek MT7915E (PCIe) support
  "MT7921E" = module; # MediaTek MT7921E (PCIe) support
  "MT7921S" = no; # MediaTek MT7921S (SDIO) support
  "MT7921U" = no; # MediaTek MT7921U (USB) support
  "MT7996E" = no; # MediaTek MT7996 (PCIe) support
  "MT7925E" = no; # MediaTek MT7925E (PCIe) support
  "MT7925U" = no; # MediaTek MT7925U (USB) support
  "WLAN_VENDOR_MICROCHIP" = yes; # Microchip devices
  "WILC1000_SDIO" = no; # Atmel WILC1000 SDIO (WiFi only)
  "WILC1000_SPI" = no; # Atmel WILC1000 SPI (WiFi only)
  "WLAN_VENDOR_PURELIFI" = yes; # pureLiFi devices
  "PLFXLC" = no; # pureLiFi X, XL, XC device support
  "WLAN_VENDOR_RALINK" = yes; # Ralink devices
  "RT2X00" = no; # Ralink driver support
  "WLAN_VENDOR_REALTEK" = yes; # Realtek devices
  "RTL8180" = no; # Realtek 8180/8185/8187SE PCI support
  "RTL8187" = no; # Realtek 8187 and 8187B USB support
  "RTL_CARDS" = module; # Realtek rtlwifi family of devices
  "RTL8192CE" = no; # Realtek RTL8192CE/RTL8188CE Wireless Network Adapter
  "RTL8192SE" = no; # Realtek RTL8192SE/RTL8191SE PCIe Wireless Network Adapter
  "RTL8192DE" = no; # Realtek RTL8192DE/RTL8188DE PCIe Wireless Network Adapter
  "RTL8723AE" = no; # Realtek RTL8723AE PCIe Wireless Network Adapter
  "RTL8723BE" = no; # Realtek RTL8723BE PCIe Wireless Network Adapter
  "RTL8188EE" = no; # Realtek RTL8188EE Wireless Network Adapter
  "RTL8192EE" = no; # Realtek RTL8192EE Wireless Network Adapter
  "RTL8821AE" = no; # Realtek RTL8821AE/RTL8812AE Wireless Network Adapter
  "RTL8192CU" = no; # Realtek RTL8192CU/RTL8188CU USB Wireless Network Adapter
  "RTL8192DU" = no; # Realtek RTL8192DU USB Wireless Network Adapter
  "RTL8XXXU" = no; # Realtek 802.11n USB wireless chips support
  "RTW88" = no; # Realtek 802.11ac wireless chips support
  "RTW89" = no; # Realtek 802.11ax wireless chips support
  "WLAN_VENDOR_RSI" = yes; # Redpine Signals Inc devices
  "RSI_91X" = module; # Redpine Signals Inc 91x WLAN driver support
  "RSI_DEBUGFS" = yes; # Redpine Signals Inc debug support
  "RSI_SDIO" = module; # Redpine Signals SDIO bus support
  "RSI_USB" = module; # Redpine Signals USB bus support
  "RSI_COEX" = yes; # Redpine Signals WLAN BT Coexistence support
  "WLAN_VENDOR_SILABS" = yes; # Silicon Laboratories devices
  "WFX" = no; # Silicon Labs wireless chips WF200 and further
  "WLAN_VENDOR_ST" = yes; # STMicroelectronics devices
  "CW1200" = no; # CW1200 WLAN support
  "WLAN_VENDOR_TI" = yes; # Texas Instrument devices
  "WL1251" = no; # TI wl1251 driver support
  "WL12XX" = no; # TI wl12xx support
  "WL18XX" = no; # TI wl18xx support
  "WLCORE" = no; # TI wlcore support
  "WLAN_VENDOR_ZYDAS" = yes; # ZyDAS devices
  "ZD1211RW" = no; # ZyDAS ZD1211/ZD1211B USB-wireless support
  "WLAN_VENDOR_QUANTENNA" = yes; # Quantenna wireless cards support
  "QTNFMAC_PCIE" = no; # Quantenna QSR1000/QSR2000/QSR10g PCIe support
  "MAC80211_HWSIM" = no; # Simulated radio testing tool for mac80211
  "VIRT_WIFI" = no; # Wifi wrapper for ethernet drivers
  "WAN" = no; # Wan interfaces support

  #### Wireless WAN
  "WWAN" = module; # WWAN Driver Core
  "WWAN_HWSIM" = no; # Simulated WWAN device
  "MHI_WWAN_CTRL" = module; # MHI WWAN control driver for QCOM-based PCIe modems
  "MHI_WWAN_MBIM" = module; # MHI WWAN MBIM network driver for QCOM-based PCIe modems
  "QCOM_BAM_DMUX" = no; # Qualcomm BAM-DMUX WWAN network driver
  "RPMSG_WWAN_CTRL" = no; # RPMSG WWAN control driver
  "IOSM" = no; # IOSM Driver for Intel M.2 WWAN Device
  "MTK_T7XX" = no; # MediaTek PCIe 5G WWAN modem T7xx device
  #### end of Wireless WAN

  "XEN_NETDEV_FRONTEND" = yes; # Xen network device frontend driver
  "XEN_NETDEV_BACKEND" = no; # Xen backend network device
  "VMXNET3" = no; # VMware VMXNET3 ethernet driver
  "FUJITSU_ES" = no; # FUJITSU Extended Socket Network Device driver
  "NETDEVSIM" = no; # Simulated networking device
  "NET_FAILOVER" = yes; # Failover driver
  "ISDN" = no; # ISDN support

  ### Device Drivers -> Input device support
  "INPUT" = yes; # Generic input layer (needed for keyboard, mouse, ...)
  "INPUT_LEDS" = yes; # Export input device LEDs in sysfs
  "INPUT_FF_MEMLESS" = yes; # Support for memoryless force-feedback devices
  "INPUT_SPARSEKMAP" = no; # Sparse keymap support library
  "INPUT_MATRIXKMAP" = yes; # Matrix keymap support library
  "INPUT_MOUSEDEV" = no; # Mouse interface
  "INPUT_JOYDEV" = module; # Joystick interface
  "INPUT_EVDEV" = yes; # Event interface
  "INPUT_KEYBOARD" = yes; # Keyboards
  "KEYBOARD_ADC" = no; # ADC Ladder Buttons
  "KEYBOARD_ADP5588" = no; # ADP5588/87 I2C QWERTY Keypad and IO Expander
  "KEYBOARD_ADP5589" = no; # ADP5585/ADP5589 I2C QWERTY Keypad and IO Expander
  "KEYBOARD_ATKBD" = yes; # AT keyboard
  "KEYBOARD_QT1050" = no; # Microchip AT42QT1050 Touch Sensor Chip
  "KEYBOARD_QT1070" = no; # Atmel AT42QT1070 Touch Sensor Chip
  "KEYBOARD_QT2160" = no; # Atmel AT42QT2160 Touch Sensor Chip
  "KEYBOARD_DLINK_DIR685" = no; # D-Link DIR-685 touchkeys support
  "KEYBOARD_LKKBD" = no; # DECstation/VAXstation LK201/LK401 keyboard
  "KEYBOARD_GPIO" = yes; # GPIO Buttons
  "KEYBOARD_GPIO_POLLED" = module; # Polled GPIO buttons
  "KEYBOARD_TCA6416" = no; # TCA6416/TCA6408A Keypad Support
  "KEYBOARD_TCA8418" = no; # TCA8418 Keypad Support
  "KEYBOARD_MATRIX" = no; # GPIO driven matrix keypad support
  "KEYBOARD_LM8323" = no; # LM8323 keypad chip
  "KEYBOARD_LM8333" = no; # LM8333 keypad chip
  "KEYBOARD_MAX7359" = no; # Maxim MAX7359 Key Switch Controller
  "KEYBOARD_MPR121" = no; # Freescale MPR121 Touchkey
  "KEYBOARD_IMX_BBM_SCMI" = yes; # IMX BBM SCMI Key Driver
  "KEYBOARD_NEWTON" = no; # Newton keyboard
  "KEYBOARD_OPENCORES" = no; # OpenCores Keyboard Controller
  "KEYBOARD_PINEPHONE" = no; # Pine64 PinePhone Keyboard
  "KEYBOARD_SAMSUNG" = no; # Samsung keypad support
  "KEYBOARD_STOWAWAY" = no; # Stowaway keyboard
  "KEYBOARD_SUNKBD" = no; # Sun Type 4 and Type 5 keyboard
  "KEYBOARD_OMAP4" = no; # TI OMAP4+ keypad support
  "KEYBOARD_TM2_TOUCHKEY" = no; # TM2 touchkey support
  "KEYBOARD_XTKBD" = no; # XT keyboard
  "KEYBOARD_CROS_EC" = yes; # ChromeOS EC keyboard
  "KEYBOARD_CAP11XX" = no; # Microchip CAP11XX based touch sensors
  "KEYBOARD_BCM" = no; # Broadcom keypad driver
  "KEYBOARD_CYPRESS_SF" = no; # Cypress StreetFighter touchkey support
  "INPUT_MOUSE" = yes; # Mice
  "MOUSE_PS2" = yes; # PS/2 mouse
  "MOUSE_PS2_ELANTECH" = no; # Elantech PS/2 protocol extension
  "MOUSE_PS2_SENTELIC" = no; # Sentelic Finger Sensing Pad PS/2 protocol extension
  "MOUSE_PS2_TOUCHKIT" = no; # eGalax TouchKit PS/2 protocol extension
  "MOUSE_SERIAL" = no; # Serial mouse
  "MOUSE_APPLETOUCH" = no; # Apple USB Touchpad support
  "MOUSE_BCM5974" = no; # Apple USB BCM5974 Multitouch trackpad support
  "MOUSE_CYAPA" = no; # Cypress APA I2C Trackpad support
  "MOUSE_ELAN_I2C" = module; # ELAN I2C Touchpad support
  "MOUSE_ELAN_I2C_I2C" = yes; # Enable I2C support
  "MOUSE_ELAN_I2C_SMBUS" = no; # Enable SMbus support
  "MOUSE_VSXXXAA" = no; # DEC VSXXX-AA/GA mouse and VSXXX-AB tablet
  "MOUSE_GPIO" = no; # GPIO mouse
  "MOUSE_SYNAPTICS_I2C" = no; # Synaptics I2C Touchpad support
  "MOUSE_SYNAPTICS_USB" = no; # Synaptics USB device support
  "INPUT_JOYSTICK" = yes; # Joysticks/Gamepads
  "JOYSTICK_ANALOG" = no; # Classic PC analog joysticks and gamepads
  "JOYSTICK_A3D" = no; # Assassin 3D and MadCatz Panther devices
  "JOYSTICK_ADC" = no; # Simple joystick connected over ADC
  "JOYSTICK_ADI" = no; # Logitech ADI digital joysticks and gamepads
  "JOYSTICK_COBRA" = no; # Creative Labs Blaster Cobra gamepad
  "JOYSTICK_GF2K" = no; # Genius Flight2000 Digital joysticks and gamepads
  "JOYSTICK_GRIP" = no; # Gravis GrIP joysticks and gamepads
  "JOYSTICK_GRIP_MP" = no; # Gravis GrIP MultiPort
  "JOYSTICK_GUILLEMOT" = no; # Guillemot joysticks and gamepads
  "JOYSTICK_INTERACT" = no; # InterAct digital joysticks and gamepads
  "JOYSTICK_SIDEWINDER" = no; # Microsoft SideWinder digital joysticks and gamepads
  "JOYSTICK_TMDC" = no; # ThrustMaster DirectConnect joysticks and gamepads
  "JOYSTICK_IFORCE" = no; # I-Force devices
  "JOYSTICK_WARRIOR" = no; # Logitech WingMan Warrior joystick
  "JOYSTICK_MAGELLAN" = no; # LogiCad3d Magellan/SpaceMouse 6dof controllers
  "JOYSTICK_SPACEORB" = no; # SpaceTec SpaceOrb/Avenger 6dof controllers
  "JOYSTICK_SPACEBALL" = no; # SpaceTec SpaceBall 6dof controllers
  "JOYSTICK_STINGER" = no; # Gravis Stinger gamepad
  "JOYSTICK_TWIDJOY" = no; # Twiddler as a joystick
  "JOYSTICK_ZHENHUA" = no; # 5-byte Zhenhua RC transmitter
  "JOYSTICK_AS5011" = no; # Austria Microsystem AS5011 joystick
  "JOYSTICK_JOYDUMP" = no; # Gameport data dumper
  "JOYSTICK_XPAD" = module; # Xbox gamepad support
  "JOYSTICK_XPAD_FF" = yes; # Xbox gamepad rumble support
  "JOYSTICK_XPAD_LEDS" = yes; # LED Support for the Xbox 360 controller Guide button
  "JOYSTICK_PSXPAD_SPI" = no; # PlayStation 1/2 joypads via SPI interface
  "JOYSTICK_PXRC" = no; # PhoenixRC Flight Controller Adapter
  "JOYSTICK_QWIIC" = no; # SparkFun Qwiic Joystick
  "JOYSTICK_FSIA6B" = no; # FlySky FS-iA6B RC Receiver
  "JOYSTICK_SENSEHAT" = no; # Raspberry Pi Sense HAT joystick
  "JOYSTICK_SEESAW" = no; # Adafruit Mini I2C Gamepad with Seesaw
  "INPUT_TABLET" = no; # Tablets
  "INPUT_TOUCHSCREEN" = yes; # Touchscreens
  "TOUCHSCREEN_STM_FTS_DOWNSTREAM" = module; # STMicroelectronics i2c multitouch touchscreen - FingerTipS (FTM5)
  "TOUCHSCREEN_FTM4" = no; # STMicroelectronics i2c multitouch touchscreen - FTM4 with FingerTipS
  "TOUCHSCREEN_ADS7846" = no; # ADS7846/TSC2046/AD7873 and AD(S)7843 based touchscreens
  "TOUCHSCREEN_AD7877" = no; # AD7877 based touchscreens
  "TOUCHSCREEN_AD7879" = no; # Analog Devices AD7879-1/AD7889-1 touchscreen interface
  "TOUCHSCREEN_ADC" = no; # Generic ADC based resistive touchscreen
  "TOUCHSCREEN_AR1021_I2C" = no; # Microchip AR1020/1021 i2c touchscreen
  "TOUCHSCREEN_ATMEL_MXT" = no; # Atmel mXT I2C Touchscreen
  "TOUCHSCREEN_AUO_PIXCIR" = no; # AUO in-cell touchscreen using Pixcir ICs
  "TOUCHSCREEN_BU21013" = no; # BU21013 based touch panel controllers
  "TOUCHSCREEN_BU21029" = no; # Rohm BU21029 based touch panel controllers
  "TOUCHSCREEN_CHIPONE_ICN8318" = no; # chipone icn8318 touchscreen controller
  "TOUCHSCREEN_CHIPONE_ICN8505" = no; # chipone icn8505 touchscreen controller
  "TOUCHSCREEN_CY8CTMA140" = no; # cy8ctma140 touchscreen
  "TOUCHSCREEN_CY8CTMG110" = no; # cy8ctmg110 touchscreen
  "TOUCHSCREEN_CYTTSP_CORE" = no; # Cypress TTSP touchscreen
  "TOUCHSCREEN_CYTTSP5" = no; # Cypress TrueTouch Gen5 Touchscreen Driver
  "TOUCHSCREEN_DYNAPRO" = no; # Dynapro serial touchscreen
  "TOUCHSCREEN_HAMPSHIRE" = no; # Hampshire serial touchscreen
  "TOUCHSCREEN_EETI" = no; # EETI touchscreen panel support
  "TOUCHSCREEN_EGALAX" = no; # EETI eGalax multi-touch panel support
  "TOUCHSCREEN_EGALAX_SERIAL" = no; # EETI eGalax serial touchscreen
  "TOUCHSCREEN_EXC3000" = no; # EETI EXC3000 multi-touch panel support
  "TOUCHSCREEN_FUJITSU" = no; # Fujitsu serial touchscreen
  "TOUCHSCREEN_GOODIX" = module; # Goodix I2C touchscreen
  "TOUCHSCREEN_GOODIX_BERLIN_I2C" = no; # Goodix Berlin I2C touchscreen
  "TOUCHSCREEN_GOODIX_BERLIN_SPI" = module; # Goodix Berlin SPI touchscreen
  "TOUCHSCREEN_HIDEEP" = no; # HiDeep Touch IC
  "TOUCHSCREEN_HYCON_HY46XX" = no; # Hycon hy46xx touchscreen support
  "TOUCHSCREEN_HYNITRON_CSTXXX" = no; # Hynitron touchscreen support
  "TOUCHSCREEN_ILI210X" = no; # Ilitek ILI210X based touchscreen
  "TOUCHSCREEN_ILITEK" = no; # Ilitek I2C 213X/23XX/25XX/Lego Series Touch ICs
  "TOUCHSCREEN_S6SY761" = module; # Samsung S6SY761 Touchscreen driver
  "TOUCHSCREEN_GUNZE" = no; # Gunze AHL-51S touchscreen
  "TOUCHSCREEN_EKTF2127" = no; # Elan eKTF2127 I2C touchscreen
  "TOUCHSCREEN_ELAN" = module; # Elan eKTH I2C touchscreen
  "TOUCHSCREEN_ELO" = no; # Elo serial touchscreens
  "TOUCHSCREEN_WACOM_W8001" = no; # Wacom W8001 penabled serial touchscreen
  "TOUCHSCREEN_WACOM_I2C" = no; # Wacom Tablet support (I2C)
  "TOUCHSCREEN_MAX11801" = no; # MAX11801 based touchscreens
  "TOUCHSCREEN_MMS114" = no; # MELFAS MMS114 touchscreen
  "TOUCHSCREEN_MELFAS_MIP4" = no; # MELFAS MIP4 Touchscreen
  "TOUCHSCREEN_MSG2638" = no; # MStar msg2638 touchscreen support
  "TOUCHSCREEN_MTOUCH" = no; # MicroTouch serial touchscreens
  "TOUCHSCREEN_NOVATEK_NVT_TS" = module; # Novatek NT11205 touchscreen support
  "TOUCHSCREEN_IMAGIS" = no; # Imagis touchscreen support
  "TOUCHSCREEN_IMX6UL_TSC" = no; # Freescale i.MX6UL touchscreen controller
  "TOUCHSCREEN_INEXIO" = no; # iNexio serial touchscreens
  "TOUCHSCREEN_PENMOUNT" = no; # Penmount serial touchscreen
  "TOUCHSCREEN_EDT_FT5X06" = module; # EDT FocalTech FT5x06 I2C Touchscreen support
  "TOUCHSCREEN_TOUCHRIGHT" = no; # Touchright serial touchscreen
  "TOUCHSCREEN_TOUCHWIN" = no; # Touchwin serial touchscreen
  "TOUCHSCREEN_PIXCIR" = no; # PIXCIR I2C touchscreens
  "TOUCHSCREEN_WDT87XX_I2C" = no; # Weida HiTech I2C touchscreen
  "TOUCHSCREEN_USB_COMPOSITE" = no; # USB Touchscreen Driver
  "TOUCHSCREEN_TOUCHIT213" = no; # Sahara TouchIT-213 touchscreen
  "TOUCHSCREEN_TSC_SERIO" = no; # TSC-10/25/40 serial touchscreen support
  "TOUCHSCREEN_TSC2004" = no; # TSC2004 based touchscreens
  "TOUCHSCREEN_TSC2005" = no; # TSC2005 based touchscreens
  "TOUCHSCREEN_TSC2007" = no; # TSC2007 based touchscreens
  "TOUCHSCREEN_RM_TS" = no; # Raydium I2C Touchscreen
  "TOUCHSCREEN_SILEAD" = no; # Silead I2C touchscreen
  "TOUCHSCREEN_SIS_I2C" = no; # SiS 9200 family I2C touchscreen
  "TOUCHSCREEN_ST1232" = no; # Sitronix ST1232 or ST1633 touchscreen controllers
  "TOUCHSCREEN_STMFTS" = no; # STMicroelectronics STMFTS touchscreen
  "TOUCHSCREEN_SUR40" = no; # Samsung SUR40 (Surface 2.0/PixelSense) touchscreen
  "TOUCHSCREEN_SURFACE3_SPI" = no; # Ntrig/Microsoft Surface 3 SPI touchscreen
  "TOUCHSCREEN_SX8654" = no; # Semtech SX8654 touchscreen
  "TOUCHSCREEN_TPS6507X" = no; # TPS6507x based touchscreens
  "TOUCHSCREEN_ZET6223" = no; # Zeitec ZET6223 touchscreen driver
  "TOUCHSCREEN_ZFORCE" = no; # Neonode zForce infrared touchscreens
  "TOUCHSCREEN_COLIBRI_VF50" = no; # Toradex Colibri on board touchscreen driver
  "TOUCHSCREEN_ROHM_BU21023" = no; # ROHM BU21023/24 Dual touch support resistive touchscreens
  "TOUCHSCREEN_IQS5XX" = no; # Azoteq IQS550/572/525 trackpad/touchscreen controller
  "TOUCHSCREEN_IQS7211" = no; # Azoteq IQS7210A/7211A/E trackpad/touchscreen controller
  "TOUCHSCREEN_ZINITIX" = no; # Zinitix touchscreen support
  "TOUCHSCREEN_HIMAX_HX83112B" = no; # Himax hx83112b touchscreen driver
  "INPUT_MISC" = yes; # Miscellaneous devices
  "INPUT_AD714X" = no; # Analog Devices AD714x Capacitance Touch Sensor
  "INPUT_ATMEL_CAPTOUCH" = no; # Atmel Capacitive Touch Button Driver
  "INPUT_BMA150" = no; # BMA150/SMB380 acceleration sensor support
  "INPUT_E3X0_BUTTON" = no; # NI Ettus Research USRP E3xx Button support.
  "INPUT_PM8941_PWRKEY" = yes; # Qualcomm PM8941 power key support
  "INPUT_PM8XXX_VIBRATOR" = module; # Qualcomm PM8XXX vibrator support
  "INPUT_QCOM_SPMI_HAPTICS" = module; # Qualcomm SPMI HAPTICS
  "INPUT_MAX77693_HAPTIC" = module; # MAXIM MAX77693/MAX77705/MAX77843 haptic controller support
  "INPUT_MMA8450" = no; # MMA8450 - Freescale's 3-Axis, 8/12-bit Digital Accelerometer
  "INPUT_GPIO_BEEPER" = no; # Generic GPIO Beeper support
  "INPUT_GPIO_DECODER" = no; # Polled GPIO Decoder Input driver
  "INPUT_GPIO_VIBRA" = no; # GPIO vibrator support
  "INPUT_ATI_REMOTE2" = no; # ATI / Philips USB RF remote control
  "INPUT_KEYSPAN_REMOTE" = no; # Keyspan DMR USB remote control
  "INPUT_KXTJ9" = no; # Kionix KXTJ9 tri-axis digital accelerometer
  "INPUT_POWERMATE" = no; # Griffin PowerMate and Contour Jog support
  "INPUT_YEALINK" = no; # Yealink usb-p1k voip phone
  "INPUT_CM109" = no; # C-Media CM109 USB I/O Controller
  "INPUT_REGULATOR_HAPTIC" = no; # Regulator haptics support
  "INPUT_TPS65219_PWRBUTTON" = module; # TPS65219 Power button driver
  "INPUT_UINPUT" = module; # User level driver support
  "INPUT_PCF8574" = no; # PCF8574 Keypad input device
  "INPUT_PWM_BEEPER" = module; # PWM beeper support
  "INPUT_PWM_VIBRA" = module; # PWM vibrator support
  "INPUT_RK805_PWRKEY" = module; # Rockchip RK805 PMIC power key support
  "INPUT_GPIO_ROTARY_ENCODER" = no; # Rotary encoders connected to GPIO pins
  "INPUT_DA7280_HAPTICS" = no; # Dialog Semiconductor DA7280 haptics support
  "INPUT_DA9063_ONKEY" = module; # Dialog DA9063/62/61 OnKey
  "INPUT_ADXL34X" = no; # Analog Devices ADXL34x Three-Axis Digital Accelerometer
  "INPUT_IBM_PANEL" = no; # IBM Operation Panel driver
  "INPUT_IMS_PCU" = no; # IMS Passenger Control Unit driver
  "INPUT_IQS269A" = no; # Azoteq IQS269A capacitive touch controller
  "INPUT_IQS626A" = no; # Azoteq IQS626A capacitive touch controller
  "INPUT_IQS7222" = no; # Azoteq IQS7222A/B/C/D capacitive touch controller
  "INPUT_CMA3000" = no; # VTI CMA3000 Tri-axis accelerometer
  "INPUT_XEN_KBDDEV_FRONTEND" = yes; # Xen virtual keyboard and mouse support
  "INPUT_SOC_BUTTON_ARRAY" = no; # Windows-compatible SoC Button Array
  "INPUT_DRV260X_HAPTICS" = no; # TI DRV260X haptics support
  "INPUT_DRV2665_HAPTICS" = no; # TI DRV2665 haptics support
  "INPUT_DRV2667_HAPTICS" = no; # TI DRV2667 haptics support
  "RMI4_CORE" = module; # Synaptics RMI4 bus support
  "RMI4_I2C" = module; # RMI4 I2C Support
  "RMI4_SPI" = no; # RMI4 SPI Support
  "RMI4_SMB" = no; # RMI4 SMB Support
  "RMI4_F03" = yes; # RMI4 Function 03 (PS2 Guest)
  "RMI4_F11" = yes; # RMI4 Function 11 (2D pointing)
  "RMI4_F12" = yes; # RMI4 Function 12 (2D pointing)
  "RMI4_F30" = yes; # RMI4 Function 30 (GPIO LED)
  "RMI4_F34" = no; # RMI4 Function 34 (Device reflash)
  "RMI4_F3A" = yes; # RMI4 Function 3A (GPIO)
  "RMI4_F54" = no; # RMI4 Function 54 (Analog diagnostics)
  "RMI4_F55" = yes; # RMI4 Function 55 (Sensor tuning)

  #### Device Drivers -> Input device support -> Hardware I/O ports
  "SERIO" = yes; # Serial I/O support
  "SERIO_SERPORT" = no; # Serial port line discipline
  "SERIO_AMBAKMI" = yes; # AMBA KMI keyboard controller
  "SERIO_PCIPS2" = no; # PCI PS/2 keyboard and PS/2 mouse controller
  "SERIO_LIBPS2" = yes; # PS/2 driver library
  "SERIO_RAW" = no; # Raw access to serio ports
  "SERIO_ALTERA_PS2" = no; # Altera UP PS/2 controller
  "SERIO_PS2MULT" = no; # TQC PS/2 multiplexer
  "SERIO_ARC_PS2" = no; # ARC PS/2 support
  "SERIO_APBPS2" = no; # GRLIB APBPS2 PS/2 keyboard/mouse controller
  "SERIO_GPIO_PS2" = no; # GPIO PS/2 bit banging driver
  "USERIO" = no; # User space serio port driver support
  "GAMEPORT" = no; # Gameport support
  #### Device Drivers -> Input device support: end of Hardware I/O ports
  ### Device Drivers: end of Input device support

  ### Device Drivers -> Character devices
  "TTY" = yes; # Enable TTY
  "VT" = yes; # Virtual terminal
  "VT_HW_CONSOLE_BINDING" = yes; # Support for binding and unbinding console drivers
  "LEGACY_PTYS" = yes; # Legacy (BSD) PTY support
  "LEGACY_PTY_COUNT" = freeform "16"; # Maximum number of legacy PTY in use
  "LEGACY_TIOCSTI" = yes; # Allow legacy TIOCSTI usage
  "LDISC_AUTOLOAD" = yes; # Automatically load TTY Line Disciplines

  ##### Serial drivers
  "SERIAL_8250" = yes; # 8250/16550 and compatible serial support
  "SERIAL_8250_DEPRECATED_OPTIONS" = yes; # Support 8250_core.* kernel options (DEPRECATED)
  "SERIAL_8250_16550A_VARIANTS" = yes; # Support for variants of the 16550A serial port
  "SERIAL_8250_FINTEK" = no; # Support for Fintek variants
  "SERIAL_8250_CONSOLE" = yes; # Console on 8250/16550 and compatible serial port
  "SERIAL_8250_PCI" = yes; # 8250/16550 PCI device support
  "SERIAL_8250_EXAR" = yes; # 8250/16550 Exar/Commtech PCI/PCIe device support
  "SERIAL_8250_NR_UARTS" = freeform "8"; # Maximum number of 8250/16550 serial ports
  "SERIAL_8250_RUNTIME_UARTS" = freeform "4"; # Number of 8250/16550 serial ports to register at runtime
  "SERIAL_8250_EXTENDED" = yes; # Extended 8250/16550 serial driver options
  "SERIAL_8250_MANY_PORTS" = no; # Support more than 4 legacy serial ports
  "SERIAL_8250_PCI1XXXX" = no; # Microchip 8250 based serial port
  "SERIAL_8250_SHARE_IRQ" = yes; # Support for sharing serial interrupts
  "SERIAL_8250_DETECT_IRQ" = no; # Autodetect IRQ on standard ports (unsafe)
  "SERIAL_8250_RSA" = no; # Support RSA serial ports
  "SERIAL_8250_DW" = yes; # Support for Synopsys DesignWare 8250 quirks
  "SERIAL_8250_RT288X" = no; # Ralink RT288x/RT305x/RT3662/RT3883 serial port support
  "SERIAL_8250_PERICOM" = yes; # Support for Pericom and Acces I/O serial ports
  "SERIAL_OF_PLATFORM" = yes; # Devicetree based probing for 8250 ports
  "SERIAL_AMBA_PL010" = no; # ARM AMBA PL010 serial port support
  "SERIAL_AMBA_PL011" = yes; # ARM AMBA PL011 serial port support
  "SERIAL_AMBA_PL011_CONSOLE" = yes; # Support for console on AMBA serial port
  "SERIAL_EARLYCON_SEMIHOST" = no; # Early console using Arm compatible semihosting
  "SERIAL_MAX3100" = no; # MAX3100/3110/3111/3222 support
  "SERIAL_MAX310X" = no; # MAX310X support
  "SERIAL_UARTLITE" = no; # Xilinx uartlite serial port support
  "SERIAL_JSM" = no; # Digi International NEO and Classic PCI Support
  "SERIAL_MSM" = yes; # MSM on-chip serial port support
  "SERIAL_MSM_CONSOLE" = yes; # MSM serial console support
  "SERIAL_QCOM_GENI" = yes; # QCOM on-chip GENI based serial port support
  "SERIAL_QCOM_GENI_CONSOLE" = yes; # QCOM GENI Serial Console support
  "SERIAL_SIFIVE" = no; # SiFive UART support
  "SERIAL_SCCNXP" = no; # SCCNXP serial port support
  "SERIAL_SC16IS7XX" = no; # NXP SC16IS7xx UART support
  "SERIAL_ALTERA_JTAGUART" = no; # Altera JTAG UART support
  "SERIAL_ALTERA_UART" = no; # Altera UART support
  "SERIAL_XILINX_PS_UART" = no; # Cadence (Xilinx Zynq) UART support
  "SERIAL_ARC" = no; # ARC UART driver support
  "SERIAL_RP2" = no; # Comtrol RocketPort EXPRESS/INFINITY support
  "SERIAL_FSL_LPUART" = no; # Freescale lpuart serial port support
  "SERIAL_FSL_LINFLEXUART" = no; # Freescale LINFlexD UART serial port support
  "SERIAL_CONEXANT_DIGICOLOR" = no; # Conexant Digicolor CX92xxx USART serial port support
  "SERIAL_SPRD" = no; # Support for Spreadtrum serial
  "SERIAL_STM32" = yes; # STMicroelectronics STM32 serial port support
  "SERIAL_STM32_CONSOLE" = yes; # Support for console on STM32
  "SERIAL_NUVOTON_MA35D1" = no; # Nuvoton MA35D1 family UART support
  ##### end of Serial drivers

  "SERIAL_NONSTANDARD" = no; # Non-standard serial port support
  "N_GSM" = no; # GSM MUX line discipline support (EXPERIMENTAL)
  "NOZOMI" = no; # HSDPA Broadband Wireless Data Card - Globe Trotter
  "NULL_TTY" = yes; # NULL TTY driver
  "HVC_XEN" = yes; # Xen Hypervisor Console support
  "HVC_XEN_FRONTEND" = yes; # Xen Hypervisor Multiple Consoles support
  "HVC_DCC" = no; # ARM JTAG DCC console
  "RPMSG_TTY" = no; # RPMSG tty driver
  "SERIAL_DEV_BUS" = yes; # Serial device bus
  "SERIAL_DEV_CTRL_TTYPORT" = yes; # Serial device TTY port controller
  "VIRTIO_CONSOLE" = yes; # Virtio console
  "IPMI_HANDLER" = module; # IPMI top-level message handler
  "IPMI_PANIC_EVENT" = no; # Generate a panic event to all BMCs on a panic
  "IPMI_DEVICE_INTERFACE" = module; # Device interface for IPMI
  "IPMI_SI" = module; # IPMI System Interface handler
  "IPMI_SSIF" = no; # IPMI SMBus handler (SSIF)
  "IPMI_IPMB" = no; # IPMI IPMB interface
  "IPMI_WATCHDOG" = no; # IPMI Watchdog Timer
  "IPMI_POWEROFF" = no; # IPMI Poweroff
  "SSIF_IPMI_BMC" = no; # SSIF IPMI BMC driver
  "IPMB_DEVICE_INTERFACE" = no; # IPMB Interface handler
  "HW_RANDOM" = yes; # Hardware Random Number Generator Core support
  "HW_RANDOM_TIMERIOMEM" = no; # Timer IOMEM HW Random Number Generator support
  "HW_RANDOM_AIROHA" = yes; # Airoha True HW Random Number Generator support
  "HW_RANDOM_BA431" = no; # Silex Insight BA431 Random Number Generator support
  "HW_RANDOM_VIRTIO" = yes; # VirtIO Random Number Generator support
  "HW_RANDOM_STM32" = yes; # STMicroelectronics STM32 random number generator
  "HW_RANDOM_OPTEE" = yes; # OP-TEE based Random Number Generator support
  "HW_RANDOM_CCTRNG" = no; # Arm CryptoCell True Random Number Generator support
  "HW_RANDOM_XIPHERA" = no; # Xiphera FPGA based True Random Number Generator support
  "HW_RANDOM_ARM_SMCCC_TRNG" = yes; # Arm SMCCC TRNG firmware interface support
  "HW_RANDOM_CN10K" = yes; # Marvell CN10K Random Number Generator support
  "APPLICOM" = no; # Applicom intelligent fieldbus card support
  "DEVMEM" = yes; # /dev/mem virtual device support
  "DEVPORT" = yes; # /dev/port character device
  "TCG_TPM" = no; # TPM Hardware Support
  "XILLYBUS" = no; # Xillybus generic FPGA interface
  "XILLYUSB" = no; # XillyUSB: Xillybus generic FPGA interface for USB
  ### Device Drivers: end of Character devices

  ### Device Drivers -> I2C support
  "I2C" = yes; # I2C support
  "ACPI_I2C_OPREGION" = yes; # ACPI I2C Operation region support
  "I2C_CHARDEV" = yes; # I2C device interface
  "I2C_MUX" = yes; # I2C bus multiplexing support

  ###### Multiplexer I2C Chip support
  "I2C_ARB_GPIO_CHALLENGE" = no; # GPIO-based I2C arbitration
  "I2C_MUX_GPIO" = no; # GPIO-based I2C multiplexer
  "I2C_MUX_GPMUX" = no; # General Purpose I2C multiplexer
  "I2C_MUX_LTC4306" = no; # LTC LTC4306/5 I2C multiplexer
  "I2C_MUX_PCA9541" = no; # NXP PCA9541 I2C Master Selector
  "I2C_MUX_PCA954x" = no; # NXP PCA954x/PCA984x and Maxim MAX735x/MAX736x I2C Mux/switches
  "I2C_MUX_PINCTRL" = module; # pinctrl-based I2C multiplexer
  "I2C_MUX_REG" = no; # Register-based I2C multiplexer
  "I2C_DEMUX_PINCTRL" = no; # pinctrl-based I2C demultiplexer
  "I2C_MUX_MLXCPLD" = no; # Mellanox CPLD based I2C multiplexer
  ###### end of Multiplexer I2C Chip support

  "I2C_HELPER_AUTO" = yes; # Autoselect pertinent helper modules

  ##### I2C Hardware Bus support
  "I2C_ALI1535" = no; # ALI 1535
  "I2C_ALI1563" = no; # ALI 1563
  "I2C_ALI15X3" = no; # ALI 15x3
  "I2C_AMD756" = no; # AMD 756/766/768/8111 and nVidia nForce
  "I2C_AMD8111" = no; # AMD 8111
  "I2C_AMD_MP2" = no; # AMD MP2 PCIe
  "I2C_I801" = no; # Intel 82801 (ICH/PCH)
  "I2C_ISCH" = no; # Intel SCH SMBus 1.0
  "I2C_NFORCE2" = no; # Nvidia nForce2, nForce3 and nForce4
  "I2C_NVIDIA_GPU" = no; # NVIDIA GPU I2C controller
  "I2C_SIS5595" = no; # SiS 5595
  "I2C_SIS630" = no; # SiS 630/730/964
  "I2C_SIS96X" = no; # SiS 96x
  "I2C_VIA" = no; # VIA VT82C586B
  "I2C_VIAPRO" = no; # VIA VT82C596/82C686/82xx and CX700/VX8xx/VX900
  "I2C_ZHAOXIN" = no; # Zhaoxin I2C Interface
  "I2C_SCMI" = no; # SMBus Control Method Interface
  "I2C_CADENCE" = module; # Cadence I2C Controller
  "I2C_CBUS_GPIO" = no; # CBUS I2C driver
  "I2C_DESIGNWARE_CORE" = yes; # Synopsys DesignWare I2C adapter
  "I2C_DESIGNWARE_SLAVE" = no; # Synopsys DesignWare Slave
  "I2C_DESIGNWARE_PLATFORM" = no; # Synopsys DesignWare Platform driver
  "I2C_DESIGNWARE_PCI" = no; # Synopsys DesignWare PCI driver
  "I2C_EMEV2" = no; # EMMA Mobile series I2C adapter
  "I2C_GPIO" = module; # GPIO-based bitbanging I2C
  "I2C_GPIO_FAULT_INJECTOR" = no; # GPIO-based fault injector
  "I2C_HISI" = no; # HiSilicon I2C controller
  "I2C_MT7621" = no; # MT7621/MT7628 I2C Controller
  "I2C_NOMADIK" = no; # ST-Ericsson Nomadik/Ux500 I2C Controller
  "I2C_OCORES" = no; # OpenCores I2C Controller
  "I2C_PCA_PLATFORM" = no; # PCA9564/PCA9665 as platform device
  "I2C_QCOM_CCI" = module; # Qualcomm Camera Control Interface
  "I2C_QCOM_GENI" = yes; # Qualcomm Technologies Inc.'s GENI based I2C controller
  "I2C_QUP" = yes; # Qualcomm QUP based I2C controller
  "I2C_RK3X" = no; # Rockchip RK3xxx I2C adapter
  "I2C_SIMTEC" = no; # Simtec Generic I2C interface
  "I2C_STM32F4" = no; # STMicroelectronics STM32F4 I2C support
  "I2C_STM32F7" = no; # STMicroelectronics STM32F7 I2C support
  "I2C_THUNDERX" = no; # Cavium ThunderX I2C bus support
  "I2C_XILINX" = no; # Xilinx I2C Controller
  "I2C_DIOLAN_U2C" = no; # Diolan U2C-12 USB adapter
  "I2C_CP2615" = no; # Silicon Labs CP2615 USB sound card and I2C adapter
  "I2C_PCI1XXXX" = no; # PCI1XXXX I2C Host Adapter
  "I2C_ROBOTFUZZ_OSIF" = no; # RobotFuzz Open Source InterFace USB adapter
  "I2C_TAOS_EVM" = no; # TAOS evaluation module
  "I2C_TINY_USB" = no; # Tiny-USB adapter
  "I2C_MLXCPLD" = no; # Mellanox I2C driver
  "I2C_CROS_EC_TUNNEL" = yes; # ChromeOS EC tunnel I2C bus
  "I2C_VIRTIO" = no; # Virtio I2C Adapter
  ##### end of I2C Hardware Bus support

  "I2C_STUB" = no; # I2C/SMBus Test Stub
  "I2C_SLAVE" = yes; # I2C slave support
  "I2C_SLAVE_EEPROM" = no; # I2C eeprom slave driver
  "I2C_SLAVE_TESTUNIT" = no; # I2C testunit driver
  "I2C_DEBUG_CORE" = no; # I2C Core debugging messages
  "I2C_DEBUG_ALGO" = no; # I2C Algorithm debugging messages
  "I2C_DEBUG_BUS" = no; # I2C Bus debugging messages
  ### Device Drivers: end of I2C support

  "I3C" = no; # I3C support
  "SPI" = yes; # SPI support
  "SPI_DEBUG" = no; # Debug support for SPI drivers
  "SPI_MEM" = yes; # SPI memory extension
  "SPI_AIROHA_SNFI" = no; # Airoha SPI NAND Flash Interface
  "SPI_ALTERA" = no; # Altera SPI Controller platform driver
  "SPI_AXI_SPI_ENGINE" = no; # Analog Devices AXI SPI Engine controller
  "SPI_BITBANG" = no; # Utilities for Bitbanging SPI host controllers
  "SPI_CADENCE" = no; # Cadence SPI controller
  "SPI_CADENCE_QUADSPI" = no; # Cadence Quad SPI controller
  "SPI_CADENCE_XSPI" = no; # Cadence XSPI controller
  "SPI_CH341" = no; # CH341 USB2SPI adapter
  "SPI_DESIGNWARE" = no; # DesignWare SPI controller core support
  "SPI_HISI_KUNPENG" = no; # HiSilicon SPI Controller for Kunpeng SoCs
  "SPI_HISI_SFC_V3XX" = no; # HiSilicon SPI NOR Flash Controller for Hi16XX chipsets
  "SPI_GPIO" = no; # GPIO-based bitbanging SPI Master
  "SPI_FSL_SPI" = no; # Freescale SPI controller and Aeroflex Gaisler GRLIB SPI controller
  "SPI_MICROCHIP_CORE" = no; # Microchip FPGA SPI controllers
  "SPI_MICROCHIP_CORE_QSPI" = no; # Microchip FPGA QSPI controllers
  "SPI_OC_TINY" = no; # OpenCores tiny SPI
  "SPI_PCI1XXXX" = no; # PCI1XXXX SPI Bus support
  "SPI_PL022" = no; # ARM AMBA PL022 SSP controller
  "SPI_QCOM_QSPI" = module; # QTI QSPI controller
  "SPI_QUP" = yes; # Qualcomm SPI controller with QUP interface
  "SPI_QCOM_GENI" = module; # Qualcomm GENI based SPI controller
  "SPI_SC18IS602" = no; # NXP SC18IS602/602B/603 I2C to SPI bridge
  "SPI_SIFIVE" = no; # SiFive SPI controller
  "SPI_SN_F_OSPI" = no; # Socionext F_OSPI SPI flash controller
  "SPI_STM32" = no; # STMicroelectronics STM32 SPI controller
  "SPI_STM32_OSPI" = no; # STMicroelectronics STM32 OCTO SPI controller
  "SPI_STM32_QSPI" = no; # STMicroelectronics STM32 QUAD SPI controller
  "SPI_MXIC" = no; # Macronix MX25F0A SPI controller
  "SPI_THUNDERX" = no; # Cavium ThunderX SPI controller
  "SPI_XCOMM" = no; # Analog Devices AD-FMCOMMS1-EBZ SPI-I2C-bridge driver
  "SPI_XILINX" = no; # Xilinx SPI controller common module
  "SPI_ZYNQMP_GQSPI" = no; # Xilinx ZynqMP GQSPI controller
  "SPI_AMD" = no; # AMD SPI controller
  "SPI_MUX" = no; # SPI multiplexer support
  "SPI_SPIDEV" = module; # User mode SPI device driver support
  "SPI_LOOPBACK_TEST" = no; # spi loopback test framework support
  "SPI_TLE62X0" = no; # Infineon TLE62X0 (for power switching)
  "SPI_SLAVE" = no; # SPI slave protocol handlers
  "SPMI" = yes; # SPMI support
  "SPMI_HISI3670" = no; # Hisilicon 3670 SPMI Controller
  "SPMI_MSM_PMIC_ARB" = yes; # Qualcomm MSM SPMI Controller (PMIC Arbiter)
  "HSI" = no; # HSI support
  "PPS" = yes; # PPS support
  "PPS_DEBUG" = no; # PPS debugging messages
  "PPS_CLIENT_KTIMER" = no; # Kernel timer client (Testing client, use for debug)
  "PPS_CLIENT_LDISC" = no; # PPS line discipline
  "PPS_CLIENT_GPIO" = no; # PPS client using GPIO
  "PPS_GENERATOR" = no; # PPS generators support

  ### Device Drivers -> PTP clock support
  "PTP_1588_CLOCK" = yes; # PTP clock support
  "PTP_1588_CLOCK_KVM" = yes; # KVM virtual PTP clock
  "PTP_1588_CLOCK_VMCLOCK" = yes; # Virtual machine PTP clock
  "PTP_1588_CLOCK_IDT82P33" = no; # IDT 82P33xxx PTP clock
  "PTP_1588_CLOCK_IDTCM" = no; # IDT CLOCKMATRIX as PTP clock
  "PTP_1588_CLOCK_FC3W" = no; # RENESAS FemtoClock3 Wireless as PTP clock
  "PTP_1588_CLOCK_MOCK" = no; # Mock-up PTP clock
  ### Device Drivers: end of PTP clock support

  "PINCTRL" = yes; # Pin controllers
  "DEBUG_PINCTRL" = no; # Debug PINCTRL calls
  "PINCTRL_AMD" = no; # AMD GPIO pin control
  "PINCTRL_AW9523" = no; # Awinic AW9523/AW9523B I2C GPIO expander pinctrl driver
  "PINCTRL_CY8C95X0" = no; # Cypress CY8C95X0 I2C pinctrl and GPIO driver
  "PINCTRL_DA9062" = module; # Dialog Semiconductor DA9062 PMIC pinctrl and GPIO Support
  "PINCTRL_MCP23S08" = no; # Microchip MCP23xxx I/O expander
  "PINCTRL_MICROCHIP_SGPIO" = no; # Pinctrl driver for Microsemi/Microchip Serial GPIO
  "PINCTRL_OCELOT" = no; # Pinctrl driver for the Microsemi Ocelot and Jaguar2 SoCs
  "PINCTRL_RK805" = module; # Pinctrl and GPIO driver for RK805 PMIC
  "PINCTRL_SCMI" = no; # Pinctrl driver using SCMI protocol interface
  "PINCTRL_SINGLE" = yes; # One-register-per-pin type device tree based pinctrl driver
  "PINCTRL_STMFX" = no; # STMicroelectronics STMFX GPIO expander pinctrl driver
  "PINCTRL_SX150X" = no; # Semtech SX150x I2C GPIO expander pinctrl driver
  "PINCTRL_TPS6594" = module; # Pinctrl and GPIO driver for TI TPS6594 PMIC
  "PINCTRL_IMX_SCMI" = no; # i.MX95 pinctrl driver using SCMI protocol interface

  #### MediaTek pinctrl drivers
  "EINT_MTK" = yes; # MediaTek External Interrupt Support
  "PINCTRL_AIROHA" = no; # Airoha EN7581 pin control
  "PINCTRL_MT2712" = yes; # MediaTek MT2712 pin control
  "PINCTRL_MT6765" = yes; # MediaTek MT6765 pin control
  "PINCTRL_MT6779" = yes; # MediaTek MT6779 pin control
  "PINCTRL_MT6795" = yes; # MediaTek MT6795 pin control
  "PINCTRL_MT6797" = yes; # MediaTek MT6797 pin control
  "PINCTRL_MT6893" = yes; # MediaTek Dimensity MT6893 pin control
  "PINCTRL_MT7622" = yes; # MediaTek MT7622 pin control
  "PINCTRL_MT7981" = yes; # MediaTek MT7981 pin control
  "PINCTRL_MT7986" = yes; # MediaTek MT7986 pin control
  "PINCTRL_MT7988" = yes; # Mediatek MT7988 pin control
  "PINCTRL_MT8167" = yes; # MediaTek MT8167 pin control
  "PINCTRL_MT8173" = yes; # MediaTek MT8173 pin control
  "PINCTRL_MT8183" = yes; # MediaTek MT8183 pin control
  "PINCTRL_MT8186" = yes; # MediaTek MT8186 pin control
  "PINCTRL_MT8188" = yes; # MediaTek MT8188 pin control
  "PINCTRL_MT8192" = yes; # MediaTek MT8192 pin control
  "PINCTRL_MT8195" = yes; # MediaTek MT8195 pin control
  "PINCTRL_MT8196" = yes; # MediaTek MT8196 pin control
  "PINCTRL_MT8365" = yes; # MediaTek MT8365 pin control
  "PINCTRL_MT8516" = yes; # MediaTek MT8516 pin control
  #### end of MediaTek pinctrl drivers

  "PINCTRL_MA35D1" = no; # Pinctrl and GPIO driver for Nuvoton MA35D1
  "PINCTRL_MSM" = yes; # Qualcomm core pin controller driver
  "PINCTRL_IPQ5018" = yes; # Qualcomm Technologies, Inc. IPQ5018 pin controller driver
  "PINCTRL_IPQ5332" = yes; # Qualcomm Technologies Inc IPQ5332 pin controller driver
  "PINCTRL_IPQ5424" = yes; # Qualcomm Technologies, Inc. IPQ5424 pin controller driver
  "PINCTRL_IPQ8074" = yes; # Qualcomm Technologies, Inc. IPQ8074 pin controller driver
  "PINCTRL_IPQ6018" = yes; # Qualcomm Technologies, Inc. IPQ6018 pin controller driver
  "PINCTRL_IPQ9574" = yes; # Qualcomm Technologies, Inc. IPQ9574 pin controller driver
  "PINCTRL_MDM9607" = no; # Qualcomm 9607 pin controller driver
  "PINCTRL_MSM8916" = yes; # Qualcomm 8916 pin controller driver
  "PINCTRL_MSM8917" = no; # Qualcomm 8917/8937 pin controller driver
  "PINCTRL_MSM8953" = yes; # Qualcomm 8953 pin controller driver
  "PINCTRL_MSM8976" = yes; # Qualcomm 8976 pin controller driver
  "PINCTRL_MSM8994" = yes; # Qualcomm 8994 pin controller driver
  "PINCTRL_MSM8996" = yes; # Qualcomm MSM8996 pin controller driver
  "PINCTRL_MSM8998" = yes; # Qualcomm MSM8998 pin controller driver
  "PINCTRL_QCM2290" = yes; # Qualcomm QCM2290 pin controller driver
  "PINCTRL_QCS404" = yes; # Qualcomm QCS404 pin controller driver
  "PINCTRL_QCS615" = yes; # Qualcomm Technologies QCS615 pin controller driver
  "PINCTRL_QCS8300" = yes; # Qualcomm Technologies QCS8300 pin controller driver
  "PINCTRL_QDF2XXX" = yes; # Qualcomm Technologies QDF2xxx pin controller driver
  "PINCTRL_QDU1000" = yes; # Qualcomm Technologies Inc QDU1000/QRU1000 pin controller driver
  "PINCTRL_SA8775P" = yes; # Qualcomm Technologies Inc SA8775P pin controller driver
  "PINCTRL_SAR2130P" = no; # Qualcomm Technologies Inc SAR2130P pin controller driver
  "PINCTRL_SC7180" = yes; # Qualcomm Technologies Inc SC7180 pin controller driver
  "PINCTRL_SC7280" = yes; # Qualcomm Technologies Inc SC7280 pin controller driver
  "PINCTRL_SC8180X" = no; # Qualcomm Technologies Inc SC8180x pin controller driver
  "PINCTRL_SC8280XP" = no; # Qualcomm Technologies Inc SC8280xp pin controller driver
  "PINCTRL_SDM660" = yes; # Qualcomm Technologies Inc SDM660 pin controller driver
  "PINCTRL_SDM670" = yes; # Qualcomm Technologies Inc SDM670 pin controller driver
  "PINCTRL_SDM845" = yes; # Qualcomm Technologies Inc SDM845 pin controller driver
  "PINCTRL_SDX75" = yes; # Qualcomm Technologies Inc SDX75 pin controller driver
  "PINCTRL_SM4450" = yes; # Qualcomm Technologies Inc SM4450 pin controller driver
  "PINCTRL_SM6115" = yes; # Qualcomm Technologies Inc SM6115,SM4250 pin controller driver
  "PINCTRL_SM6125" = yes; # Qualcomm Technologies Inc SM6125 pin controller driver
  "PINCTRL_SM6350" = yes; # Qualcomm Technologies Inc SM6350 pin controller driver
  "PINCTRL_SM6375" = yes; # Qualcomm Technologies Inc SM6375 pin controller driver
  "PINCTRL_SM7150" = no; # Qualcomm Technologies Inc SM7150 pin controller driver
  "PINCTRL_SM8150" = yes; # Qualcomm Technologies Inc SM8150 pin controller driver
  "PINCTRL_SM8250" = yes; # Qualcomm Technologies Inc SM8250 pin controller driver
  "PINCTRL_SM8350" = yes; # Qualcomm Technologies Inc SM8350 pin controller driver
  "PINCTRL_SM8450" = yes; # Qualcomm Technologies Inc SM8450 pin controller driver
  "PINCTRL_SM8550" = yes; # Qualcomm Technologies Inc SM8550 pin controller driver
  "PINCTRL_SM8650" = yes; # Qualcomm Technologies Inc SM8650 pin controller driver
  "PINCTRL_SM8750" = yes; # Qualcomm Technologies Inc SM8750 pin controller driver
  "PINCTRL_X1E80100" = yes; # Qualcomm Technologies Inc X1E80100 pin controller driver
  "PINCTRL_QCOM_SPMI_PMIC" = yes; # Qualcomm SPMI PMIC pin controller driver
  "PINCTRL_QCOM_SSBI_PMIC" = no; # Qualcomm SSBI PMIC pin controller driver
  "PINCTRL_LPASS_LPI" = module; # Qualcomm Technologies Inc LPASS LPI pin controller driver
  "PINCTRL_SC7280_LPASS_LPI" = module; # Qualcomm Technologies Inc SC7280 LPASS LPI pin controller driver
  "PINCTRL_SM4250_LPASS_LPI" = no; # Qualcomm Technologies Inc SM4250 LPASS LPI pin controller driver
  "PINCTRL_SM6115_LPASS_LPI" = module; # Qualcomm Technologies Inc SM6115 LPASS LPI pin controller driver
  "PINCTRL_SM8250_LPASS_LPI" = module; # Qualcomm Technologies Inc SM8250 LPASS LPI pin controller driver
  "PINCTRL_SM8350_LPASS_LPI" = module; # Qualcomm Technologies Inc SM8350 LPASS LPI pin controller driver
  "PINCTRL_SM8450_LPASS_LPI" = module; # Qualcomm Technologies Inc SM8450 LPASS LPI pin controller driver
  "PINCTRL_SC8280XP_LPASS_LPI" = module; # Qualcomm Technologies Inc SC8280XP LPASS LPI pin controller driver
  "PINCTRL_SM8550_LPASS_LPI" = module; # Qualcomm Technologies Inc SM8550 LPASS LPI pin controller driver
  "PINCTRL_SM8650_LPASS_LPI" = module; # Qualcomm Technologies Inc SM8650 LPASS LPI pin controller driver
  "PINCTRL_RTD" = yes; # Realtek DHC core pin controller driver
  "PINCTRL_RTD1619B" = yes; # Realtek DHC 1619B pin controller driver
  "PINCTRL_RTD1319D" = yes; # Realtek DHC 1319D pin controller driver
  "PINCTRL_RTD1315E" = yes; # Realtek DHC 1315E pin controller driver
  "GPIOLIB" = yes; # GPIO Support
  "GPIOLIB_FASTPATH_LIMIT" = freeform "512"; # Maximum number of GPIOs for fast path
  "DEBUG_GPIO" = no; # Debug GPIO calls
  "GPIO_CDEV" = yes; # Character device (/dev/gpiochipN) support
  "GPIO_CDEV_V1" = yes; # Support GPIO ABI Version 1

  #### Memory mapped GPIO drivers
  "GPIO_74XX_MMIO" = no; # GPIO driver for 74xx-ICs with MMIO access
  "GPIO_ALTERA" = no; # Altera GPIO
  "GPIO_AMDPT" = no; # AMD Promontory GPIO support
  "GPIO_CADENCE" = no; # Cadence GPIO support
  "GPIO_DWAPB" = no; # Synopsys DesignWare APB GPIO driver
  "GPIO_EN7523" = yes; # Airoha GPIO support
  "GPIO_EXAR" = no; # Support for GPIO pins on XR17V352/354/358
  "GPIO_FTGPIO010" = no; # Faraday FTGPIO010 GPIO
  "GPIO_GENERIC_PLATFORM" = yes; # Generic memory-mapped GPIO controller support (MMIO platform device)
  "GPIO_GRGPIO" = no; # Aeroflex Gaisler GRGPIO support
  "GPIO_HISI" = no; # HiSilicon GPIO controller driver
  "GPIO_HLWD" = no; # Nintendo Wii (Hollywood) GPIO
  "GPIO_LOGICVC" = no; # Xylon LogiCVC GPIO support
  "GPIO_MB86S7X" = no; # GPIO support for Fujitsu MB86S7x Platforms
  "GPIO_PL061" = no; # PrimeCell PL061 GPIO support
  "GPIO_POLARFIRE_SOC" = no; # Microchip FPGA GPIO support
  "GPIO_RTD" = yes; # Realtek DHC GPIO support
  "GPIO_SIFIVE" = no; # SiFive GPIO support
  "GPIO_SYSCON" = yes; # GPIO based on SYSCON
  "GPIO_WCD934X" = module; # Qualcomm Technologies Inc WCD9340/WCD9341 GPIO controller driver
  "GPIO_XGENE" = no; # APM X-Gene GPIO controller support
  "GPIO_XILINX" = no; # Xilinx GPIO support
  "GPIO_AMD_FCH" = no; # GPIO support for AMD Fusion Controller Hub (G-series SOCs)
  #### end of Memory mapped GPIO drivers

  #### I2C GPIO expanders
  "GPIO_ADNP" = no; # Avionic Design N-bit GPIO expander
  "GPIO_FXL6408" = no; # FXL6408 I2C GPIO expander
  "GPIO_DS4520" = no; # DS4520 I2C GPIO expander
  "GPIO_GW_PLD" = no; # Gateworks PLD GPIO Expander
  "GPIO_MAX7300" = no; # Maxim MAX7300 GPIO expander
  "GPIO_MAX732X" = no; # MAX7319, MAX7320-7327 I2C Port Expanders
  "GPIO_PCA953X" = no; # PCA95[357]x, PCA9698, TCA64xx, and MAX7310 I/O ports
  "GPIO_PCA9570" = no; # PCA9570 4-Bit I2C GPO expander
  "GPIO_PCF857X" = module; # PCF857x, PCA{85,96}7x, and MAX732[89] I2C GPIO expanders
  "GPIO_TPIC2810" = module; # TPIC2810 8-Bit I2C GPO expander
  #### end of I2C GPIO expanders

  #### MFD GPIO expanders
  "GPIO_ADP5585" = module; # GPIO Support for ADP5585
  "GPIO_CROS_EC" = no; # ChromeOS EC GPIO support
  "GPIO_LP873X" = no; # TI LP873X GPO
  "GPIO_TPS65219" = yes; # TPS65219 GPIO
  "GPIO_WM8994" = no; # WM8994 GPIOs
  #### end of MFD GPIO expanders

  #### PCI GPIO expanders
  "GPIO_BT8XX" = no; # BT8XX GPIO abuser
  "GPIO_PCI_IDIO_16" = no; # ACCES PCI-IDIO-16 GPIO support
  "GPIO_PCIE_IDIO_24" = no; # ACCES PCIe-IDIO-24 GPIO support
  "GPIO_RDC321X" = no; # RDC R-321x GPIO support
  #### end of PCI GPIO expanders

  #### SPI GPIO expanders
  "GPIO_74X164" = no; # 74x164 serial-in/parallel-out 8-bits shift register
  "GPIO_MAX3191X" = no; # Maxim MAX3191x industrial serializer
  "GPIO_MAX7301" = no; # Maxim MAX7301 GPIO expander
  "GPIO_MC33880" = no; # Freescale MC33880 high-side/low-side switch
  "GPIO_PISOSR" = no; # Generic parallel-in/serial-out shift register
  "GPIO_XRA1403" = no; # EXAR XRA1403 16-bit GPIO expander
  #### end of SPI GPIO expanders

  #### USB GPIO expanders
  "GPIO_MPSSE" = no; # FTDI MPSSE GPIO support
  #### end of USB GPIO expanders

  #### Virtual GPIO drivers
  "GPIO_AGGREGATOR" = module; # GPIO Aggregator
  "GPIO_LATCH" = no; # GPIO latch driver
  "GPIO_MOCKUP" = no; # GPIO Testing Driver (DEPRECATED)
  "GPIO_VIRTIO" = no; # VirtIO GPIO support
  "GPIO_SIM" = no; # GPIO Simulator Module
  #### end of Virtual GPIO drivers

  #### GPIO Debugging utilities
  "GPIO_VIRTUSER" = no; # GPIO Virtual User Testing Module
  #### end of GPIO Debugging utilities

  "W1" = no; # Dallas's 1-wire support
  "POWER_RESET" = yes; # Board level reset or power off
  "POWER_RESET_GPIO" = no; # GPIO power-off driver
  "POWER_RESET_GPIO_RESTART" = no; # GPIO restart driver
  "POWER_RESET_MSM" = yes; # Qualcomm MSM power-off driver
  "POWER_RESET_QCOM_PON" = yes; # Qualcomm power-on driver
  "POWER_RESET_LTC2952" = no; # LTC2952 PowerPath power-off driver
  "POWER_RESET_REGULATOR" = no; # Regulator subsystem power-off driver
  "POWER_RESET_RESTART" = no; # Restart power-off driver
  "POWER_RESET_TORADEX_EC" = module; # Toradex Embedded Controller power-off and reset driver
  "POWER_RESET_VEXPRESS" = no; # ARM Versatile Express power-off and reset driver
  "POWER_RESET_XGENE" = no; # APM SoC X-Gene reset driver
  "POWER_RESET_SYSCON" = no; # Generic SYSCON regmap reset driver
  "POWER_RESET_SYSCON_POWEROFF" = yes; # Generic SYSCON regmap poweroff driver
  "SYSCON_REBOOT_MODE" = yes; # Generic SYSCON regmap reboot mode driver
  "NVMEM_REBOOT_MODE" = module; # Generic NVMEM reboot mode driver
  "POWER_SEQUENCING" = module; # Power Sequencing support
  "POWER_SEQUENCING_QCOM_WCN" = module; # Qualcomm WCN family PMU driver
  "POWER_SUPPLY" = yes; # Power supply class support
  "POWER_SUPPLY_DEBUG" = no; # Power supply debug
  "POWER_SUPPLY_HWMON" = yes; # Expose power supply sensors as hwmon device
  "GENERIC_ADC_BATTERY" = no; # Generic battery support using IIO
  "IP5XXX_POWER" = no; # Injoinic IP5xxx power bank IC driver
  "TEST_POWER" = no; # Test power driver
  "CHARGER_ADP5061" = no; # ADP5061 battery charger driver
  "BATTERY_CHAGALL" = no; # Pegatron Chagall battery driver
  "BATTERY_CW2015" = no; # CW2015 Battery driver
  "BATTERY_DS2780" = no; # DS2780 battery driver
  "BATTERY_DS2781" = no; # DS2781 battery driver
  "BATTERY_DS2782" = no; # DS2782/DS2786 standalone gas-gauge
  "BATTERY_LENOVO_YOGA_C630" = module; # Lenovo Yoga C630 battery
  "BATTERY_QCOM_BATTMGR" = module; # Qualcomm PMIC GLINK battery manager support
  "BATTERY_SAMSUNG_SDI" = no; # Samsung SDI batteries
  "BATTERY_SBS" = no; # SBS Compliant gas gauge
  "CHARGER_SBS" = no; # SBS Compliant charger
  "MANAGER_SBS" = no; # Smart Battery System Manager
  "BATTERY_BQ27XXX" = module; # BQ27xxx battery driver
  "BATTERY_BQ27XXX_I2C" = module; # BQ27xxx I2C support
  "BATTERY_BQ27XXX_DT_UPDATES_NVM" = no; # BQ27xxx support for update of NVM/flash data memory
  "BATTERY_MAX17040" = no; # Maxim MAX17040/17041/17043 family Fuel Gauge
  "BATTERY_MAX17042" = module; # Maxim MAX17042/17047/17050/8997/8966 family Fuel Gauge
  "BATTERY_MAX1720X" = no; # Maxim MAX17201/MAX17205 Fuel Gauge
  "CHARGER_MAX8903" = no; # MAX8903 Battery DC-DC Charger for USB and Adapter Power
  "CHARGER_LP8727" = no; # TI/National Semiconductor LP8727 charger driver
  "CHARGER_GPIO" = no; # GPIO charger
  "CHARGER_MANAGER" = no; # Battery charger manager for multiple chargers
  "CHARGER_LT3651" = no; # Analog Devices LT3651 charger
  "CHARGER_LTC4162L" = no; # LTC4162-L charger
  "CHARGER_DETECTOR_MAX14656" = no; # Maxim MAX14656 USB charger detector
  "CHARGER_MAX77705" = module; # Maxim MAX77705 battery charger driver
  "CHARGER_MAX77976" = no; # Maxim MAX77976 battery charger driver
  "CHARGER_MAX8971" = no; # Maxim MAX8971 battery charger driver
  "CHARGER_MT6360" = module; # Mediatek MT6360 Charger Driver
  "CHARGER_QCOM_SMBB" = no; # Qualcomm Switch-Mode Battery Charger and Boost
  "BATTERY_PM8916_BMS_VM" = no; # Qualcomm PM8916 BMS-VM support
  "CHARGER_PM8916_LBC" = no; # Qualcomm PM8916 Linear Battery Charger support
  "CHARGER_BQ2415X" = no; # TI BQ2415x battery charger driver
  "CHARGER_BQ24190" = no; # TI BQ24190 battery charger driver
  "CHARGER_BQ24257" = no; # TI BQ24250/24251/24257 battery charger driver
  "CHARGER_BQ24735" = no; # TI BQ24735 battery charger support
  "CHARGER_BQ2515X" = no; # TI BQ2515X battery charger family
  "CHARGER_BQ25890" = module; # TI BQ25890 battery charger driver
  "CHARGER_BQ25980" = module; # TI BQ25980 battery charger driver
  "CHARGER_BQ256XX" = no; # TI BQ256XX battery charger driver
  "CHARGER_RK817" = module; # Rockchip RK817 PMIC Battery Charger
  "CHARGER_SMB347" = no; # Summit Microelectronics SMB3XX Battery Charger
  "BATTERY_GAUGE_LTC2941" = no; # LTC2941/LTC2943 Battery Gauge Driver
  "BATTERY_GOLDFISH" = no; # Goldfish battery driver
  "BATTERY_RT5033" = no; # RT5033 fuel gauge support
  "CHARGER_RT9455" = no; # Richtek RT9455 battery charger driver
  "CHARGER_RT9467" = no; # Richtek RT9467 Battery Charger Driver
  "CHARGER_RT9471" = no; # Richtek RT9471 battery charger driver
  "CHARGER_CROS_USBPD" = no; # ChromeOS EC based USBPD charger
  "CHARGER_CROS_PCHG" = yes; # ChromeOS EC based peripheral charger
  "CHARGER_CROS_CONTROL" = yes; # ChromeOS EC based charge control
  "FUEL_GAUGE_STC3117" = no; # STMicroelectronics STC3117 fuel gauge driver
  "CHARGER_UCS1002" = no; # Microchip UCS1002 USB Port Power Controller
  "CHARGER_BD99954" = no; # ROHM bd99954 charger driver
  "BATTERY_UG3105" = no; # uPI uG3105 battery monitor driver
  "BATTERY_QCOM_FG" = module; # Qualcomm PMIC fuel gauge driver
  "CHARGER_QCOM_SMB2" = module; # Qualcomm PMI8998 PMIC charger driver
  "FUEL_GAUGE_MM8013" = no; # Mitsumi MM8013 fuel gauge driver
  "HWMON" = yes; # Hardware Monitoring support
  "HWMON_DEBUG_CHIP" = no; # Hardware Monitoring Chip debugging messages
  "SENSORS_AD7314" = no; # Analog Devices AD7314 and compatibles
  "SENSORS_AD7414" = no; # Analog Devices AD7414
  "SENSORS_AD7418" = no; # Analog Devices AD7416, AD7417 and AD7418
  "SENSORS_ADM1025" = no; # Analog Devices ADM1025 and compatibles
  "SENSORS_ADM1026" = no; # Analog Devices ADM1026 and compatibles
  "SENSORS_ADM1029" = no; # Analog Devices ADM1029
  "SENSORS_ADM1031" = no; # Analog Devices ADM1031 and compatibles
  "SENSORS_ADM1177" = no; # Analog Devices ADM1177 and compatibles
  "SENSORS_ADM9240" = no; # Analog Devices ADM9240 and compatibles
  "SENSORS_ADT7310" = no; # Analog Devices ADT7310/ADT7320
  "SENSORS_ADT7410" = no; # Analog Devices ADT7410/ADT7420
  "SENSORS_ADT7411" = no; # Analog Devices ADT7411
  "SENSORS_ADT7462" = no; # Analog Devices ADT7462
  "SENSORS_ADT7470" = no; # Analog Devices ADT7470
  "SENSORS_ADT7475" = no; # Analog Devices ADT7473, ADT7475, ADT7476 and ADT7490
  "SENSORS_AHT10" = no; # Aosong AHT10, AHT20
  "SENSORS_AQUACOMPUTER_D5NEXT" = no; # Aquacomputer D5 Next, Octo, Quadro, Farbwerk, Farbwerk 360, High Flow Next
  "SENSORS_AS370" = no; # Synaptics AS370 SoC hardware monitoring driver
  "SENSORS_ASC7621" = no; # Andigilog aSC7621
  "SENSORS_ASUS_ROG_RYUJIN" = no; # ASUS ROG RYUJIN II 360 hardware monitoring driver
  "SENSORS_AXI_FAN_CONTROL" = no; # Analog Devices FAN Control HDL Core driver
  "SENSORS_ARM_SCMI" = yes; # ARM SCMI Sensors
  "SENSORS_ARM_SCPI" = no; # ARM SCPI Sensors
  "SENSORS_ATXP1" = no; # Attansic ATXP1 VID controller
  "SENSORS_CHIPCAP2" = no; # Amphenol ChipCap 2 relative humidity and temperature sensor
  "SENSORS_CORSAIR_CPRO" = no; # Corsair Commander Pro controller
  "SENSORS_CORSAIR_PSU" = no; # Corsair PSU HID controller
  "SENSORS_CROS_EC" = yes; # ChromeOS Embedded Controller sensors
  "SENSORS_DS620" = no; # Dallas Semiconductor DS620
  "SENSORS_DS1621" = no; # Dallas Semiconductor DS1621 and compatibles
  "SENSORS_I5K_AMB" = no; # FB-DIMM AMB temperature sensor on Intel 5000 series chipsets
  "SENSORS_F71805F" = no; # Fintek F71805F/FG, F71806F/FG and F71872F/FG
  "SENSORS_F71882FG" = no; # Fintek F71882FG and compatibles
  "SENSORS_F75375S" = no; # Fintek F75375S/SP, F75373 and F75387
  "SENSORS_FTSTEUTATES" = no; # Fujitsu Technology Solutions sensor chip Teutates
  "SENSORS_GIGABYTE_WATERFORCE" = no; # Gigabyte Waterforce X240/X280/X360 AIO CPU coolers
  "SENSORS_GL518SM" = no; # Genesys Logic GL518SM
  "SENSORS_GL520SM" = no; # Genesys Logic GL520SM
  "SENSORS_G760A" = no; # GMT G760A
  "SENSORS_G762" = no; # GMT G762 and G763
  "SENSORS_GPIO_FAN" = no; # GPIO fan
  "SENSORS_HIH6130" = no; # Honeywell Humidicon HIH-6130 humidity/temperature sensor
  "SENSORS_HS3001" = no; # Renesas HS3001 humidity and temperature sensors
  "SENSORS_HTU31" = no; # Measurement Specialties HTU31 humidity and temperature sensor
  "SENSORS_IBMAEM" = no; # IBM Active Energy Manager temperature/power sensors and control
  "SENSORS_IBMPEX" = no; # IBM PowerExecutive temperature/power sensors
  "SENSORS_IIO_HWMON" = no; # Hwmon driver that uses channels specified via iio maps
  "SENSORS_ISL28022" = no; # Renesas ISL28022
  "SENSORS_IT87" = no; # ITE IT87xx and compatibles
  "SENSORS_JC42" = module; # JEDEC JC42.4 compliant memory module temperature sensors
  "SENSORS_POWERZ" = no; # ChargerLAB POWER-Z USB-C tester
  "SENSORS_POWR1220" = no; # Lattice POWR1220 Power Monitoring
  "SENSORS_LINEAGE" = no; # Lineage Compact Power Line Power Entry Module
  "SENSORS_LTC2945" = no; # Linear Technology LTC2945
  "SENSORS_LTC2947_I2C" = no; # Analog Devices LTC2947 High Precision Power and Energy Monitor over I2C
  "SENSORS_LTC2947_SPI" = no; # Analog Devices LTC2947 High Precision Power and Energy Monitor over SPI
  "SENSORS_LTC2990" = no; # Linear Technology LTC2990
  "SENSORS_LTC2991" = no; # Analog Devices LTC2991
  "SENSORS_LTC2992" = no; # Linear Technology LTC2992
  "SENSORS_LTC4151" = no; # Linear Technology LTC4151
  "SENSORS_LTC4215" = no; # Linear Technology LTC4215
  "SENSORS_LTC4222" = no; # Linear Technology LTC4222
  "SENSORS_LTC4245" = no; # Linear Technology LTC4245
  "SENSORS_LTC4260" = no; # Linear Technology LTC4260
  "SENSORS_LTC4261" = no; # Linear Technology LTC4261
  "SENSORS_LTC4282" = no; # Analog Devices LTC4282
  "SENSORS_MAX1111" = no; # Maxim MAX1111 Serial 8-bit ADC chip and compatibles
  "SENSORS_MAX127" = no; # Maxim MAX127 12-bit 8-channel Data Acquisition System
  "SENSORS_MAX16065" = no; # Maxim MAX16065 System Manager and compatibles
  "SENSORS_MAX1619" = no; # Maxim MAX1619 sensor chip
  "SENSORS_MAX1668" = no; # Maxim MAX1668 and compatibles
  "SENSORS_MAX197" = no; # Maxim MAX197 and compatibles
  "SENSORS_MAX31722" = no; # MAX31722 temperature sensor
  "SENSORS_MAX31730" = no; # MAX31730 temperature sensor
  "SENSORS_MAX31760" = no; # MAX31760 fan speed controller
  "MAX31827" = no; # MAX31827 low-power temperature switch and similar devices
  "SENSORS_MAX6620" = no; # Maxim MAX6620 fan controller
  "SENSORS_MAX6621" = no; # Maxim MAX6621 sensor chip
  "SENSORS_MAX6639" = no; # Maxim MAX6639 sensor chip
  "SENSORS_MAX6650" = no; # Maxim MAX6650 sensor chip
  "SENSORS_MAX6697" = no; # Maxim MAX6697 and compatibles
  "SENSORS_MAX31790" = no; # Maxim MAX31790 sensor chip
  "SENSORS_MAX77705" = no; # MAX77705 current and voltage sensor
  "SENSORS_MC34VR500" = no; # NXP MC34VR500 hardware monitoring driver
  "SENSORS_MCP3021" = no; # Microchip MCP3021 and compatibles
  "SENSORS_TC654" = no; # Microchip TC654/TC655 and compatibles
  "SENSORS_TPS23861" = no; # Texas Instruments TPS23861 PoE PSE
  "SENSORS_MR75203" = no; # Moortec Semiconductor MR75203 PVT Controller
  "SENSORS_ADCXX" = no; # National Semiconductor ADCxxxSxxx
  "SENSORS_LM63" = no; # National Semiconductor LM63 and compatibles
  "SENSORS_LM70" = no; # National Semiconductor LM70 and compatibles
  "SENSORS_LM73" = no; # National Semiconductor LM73
  "SENSORS_LM75" = module; # National Semiconductor LM75 and compatibles
  "SENSORS_LM77" = no; # National Semiconductor LM77
  "SENSORS_LM78" = no; # National Semiconductor LM78 and compatibles
  "SENSORS_LM80" = no; # National Semiconductor LM80 and LM96080
  "SENSORS_LM83" = no; # National Semiconductor LM83 and compatibles
  "SENSORS_LM85" = no; # National Semiconductor LM85 and compatibles
  "SENSORS_LM87" = no; # National Semiconductor LM87 and compatibles
  "SENSORS_LM90" = no; # National Semiconductor LM90 and compatibles
  "SENSORS_LM92" = no; # National Semiconductor LM92 and compatibles
  "SENSORS_LM93" = no; # National Semiconductor LM93 and compatibles
  "SENSORS_LM95234" = no; # National Semiconductor LM95234 and compatibles
  "SENSORS_LM95241" = no; # National Semiconductor LM95241 and compatibles
  "SENSORS_LM95245" = no; # National Semiconductor LM95245 and compatibles
  "SENSORS_PC87360" = no; # National Semiconductor PC87360 family
  "SENSORS_PC87427" = no; # National Semiconductor PC87427
  "SENSORS_NTC_THERMISTOR" = no; # NTC thermistor support
  "SENSORS_NCT6683" = no; # Nuvoton NCT6683D
  "SENSORS_NCT6775" = no; # Platform driver for Nuvoton NCT6775F and compatibles
  "SENSORS_NCT6775_I2C" = no; # I2C driver for Nuvoton NCT6775F and compatibles
  "SENSORS_NCT7363" = no; # Nuvoton NCT7363Y
  "SENSORS_NCT7802" = no; # Nuvoton NCT7802Y
  "SENSORS_NCT7904" = no; # Nuvoton NCT7904
  "SENSORS_NPCM7XX" = no; # Nuvoton NPCM750 and compatible PWM and Fan controllers
  "SENSORS_NZXT_KRAKEN2" = no; # NZXT Kraken X42/X51/X62/X72 liquid coolers
  "SENSORS_NZXT_KRAKEN3" = no; # NZXT Kraken X53/X63/X73, Z53/Z63/Z73 coolers
  "SENSORS_NZXT_SMART2" = no; # NZXT RGB & Fan Controller/Smart Device v2
  "SENSORS_OCC_P8_I2C" = no; # POWER8 OCC through I2C
  "SENSORS_PCF8591" = no; # Philips PCF8591 ADC/DAC
  "PMBUS" = no; # PMBus support
  "SENSORS_PT5161L" = no; # Astera Labs PT5161L PCIe retimer hardware monitoring
  "SENSORS_PWM_FAN" = no; # PWM fan
  "SENSORS_SBTSI" = no; # Emulated SB-TSI temperature sensor
  "SENSORS_SHT15" = no; # Sensiron humidity and temperature sensors. SHT15 and compat.
  "SENSORS_SHT21" = no; # Sensiron humidity and temperature sensors. SHT21 and compat.
  "SENSORS_SHT3x" = no; # Sensiron humidity and temperature sensors. SHT3x and compat.
  "SENSORS_SHT4x" = no; # Sensiron humidity and temperature sensors. SHT4x and compat.
  "SENSORS_SHTC1" = no; # Sensiron humidity and temperature sensors. SHTC1 and compat.
  "SENSORS_SIS5595" = no; # Silicon Integrated Systems Corp. SiS5595
  "SENSORS_DME1737" = no; # SMSC DME1737, SCH311x and compatibles
  "SENSORS_EMC1403" = no; # SMSC EMC1403/23 thermal sensor
  "SENSORS_EMC2103" = no; # SMSC EMC2103
  "SENSORS_EMC2305" = no; # Microchip EMC2305 and compatible EMC2301/2/3
  "SENSORS_EMC6W201" = no; # SMSC EMC6W201
  "SENSORS_SMSC47M1" = no; # SMSC LPC47M10x and compatibles
  "SENSORS_SMSC47M192" = no; # SMSC LPC47M192 and compatibles
  "SENSORS_SMSC47B397" = no; # SMSC LPC47B397-NC
  "SENSORS_SCH5627" = no; # SMSC SCH5627
  "SENSORS_SCH5636" = no; # SMSC SCH5636
  "SENSORS_STTS751" = no; # ST Microelectronics STTS751
  "SENSORS_ADC128D818" = no; # Texas Instruments ADC128D818
  "SENSORS_ADS7828" = no; # Texas Instruments ADS7828 and compatibles
  "SENSORS_ADS7871" = no; # Texas Instruments ADS7871 A/D converter
  "SENSORS_AMC6821" = no; # Texas Instruments AMC6821
  "SENSORS_INA209" = no; # TI / Burr Brown INA209
  "SENSORS_INA2XX" = no; # Texas Instruments INA219 and compatibles
  "SENSORS_INA238" = no; # Texas Instruments INA238
  "SENSORS_INA3221" = no; # Texas Instruments INA3221 Triple Power Monitor
  "SENSORS_SPD5118" = no; # SPD5118 Compliant Temperature Sensors
  "SENSORS_TC74" = no; # Microchip TC74
  "SENSORS_THMC50" = no; # Texas Instruments THMC50 / Analog Devices ADM1022
  "SENSORS_TMP102" = module; # Texas Instruments TMP102
  "SENSORS_TMP103" = no; # Texas Instruments TMP103
  "SENSORS_TMP108" = no; # Texas Instruments TMP108
  "SENSORS_TMP401" = no; # Texas Instruments TMP401 and compatibles
  "SENSORS_TMP421" = no; # Texas Instruments TMP421 and compatible
  "SENSORS_TMP464" = no; # Texas Instruments TMP464 and compatible
  "SENSORS_TMP513" = no; # Texas Instruments TMP513 and compatibles
  "SENSORS_VEXPRESS" = no; # Versatile Express
  "SENSORS_VIA686A" = no; # VIA686A
  "SENSORS_VT1211" = no; # VIA VT1211
  "SENSORS_VT8231" = no; # VIA VT8231
  "SENSORS_W83773G" = no; # Nuvoton W83773G
  "SENSORS_W83781D" = no; # Winbond W83781D, W83782D, W83783S, Asus AS99127F
  "SENSORS_W83791D" = no; # Winbond W83791D
  "SENSORS_W83792D" = no; # Winbond W83792D
  "SENSORS_W83793" = no; # Winbond W83793
  "SENSORS_W83795" = no; # Winbond/Nuvoton W83795G/ADG
  "SENSORS_W83L785TS" = no; # Winbond W83L785TS-S
  "SENSORS_W83L786NG" = no; # Winbond W83L786NG, W83L786NR
  "SENSORS_W83627HF" = no; # Winbond W83627HF, W83627THF, W83637HF, W83687THF, W83697HF
  "SENSORS_W83627EHF" = no; # Winbond W83627EHF/EHG/DHG/UHG, W83667HG
  "SENSORS_XGENE" = no; # APM X-Gene SoC hardware monitoring driver
  "SENSORS_ACPI_POWER" = no; # ACPI 4.0 power meter
  "THERMAL" = yes; # Thermal drivers
  "THERMAL_NETLINK" = no; # Thermal netlink management
  "THERMAL_STATISTICS" = no; # Thermal state transition statistics
  "THERMAL_DEBUGFS" = no; # Thermal subsystem debug support
  "THERMAL_CORE_TESTING" = no; # Thermal core testing facility
  "THERMAL_EMERGENCY_POWEROFF_DELAY_MS" = freeform "0"; # Emergency poweroff delay in milli-seconds
  "THERMAL_HWMON" = yes; # Expose thermal sensors as hwmon device
  "THERMAL_OF" = yes; # APIs to parse thermal data out of device tree
  "THERMAL_DEFAULT_GOV_STEP_WISE" = yes; # step_wise
  "THERMAL_DEFAULT_GOV_FAIR_SHARE" = no; # fair_share
  "THERMAL_DEFAULT_GOV_USER_SPACE" = no; # user_space
  "THERMAL_DEFAULT_GOV_POWER_ALLOCATOR" = no; # power_allocator
  "THERMAL_GOV_FAIR_SHARE" = no; # Fair-share thermal governor
  "THERMAL_GOV_STEP_WISE" = yes; # Step_wise thermal governor
  "THERMAL_GOV_BANG_BANG" = no; # Bang Bang thermal governor
  "THERMAL_GOV_USER_SPACE" = no; # User_space thermal governor
  "THERMAL_GOV_POWER_ALLOCATOR" = yes; # Power allocator thermal governor
  "CPU_THERMAL" = yes; # Generic cpu cooling support
  "CPU_FREQ_THERMAL" = yes; # CPU frequency cooling device
  "DEVFREQ_THERMAL" = yes; # Generic device cooling support
  "PCIE_THERMAL" = no; # PCIe cooling support
  "THERMAL_EMULATION" = yes; # Thermal emulation mode support
  "THERMAL_MMIO" = no; # Generic Thermal MMIO driver
  "AIROHA_THERMAL" = no; # Airoha thermal sensor driver
  "DA9062_THERMAL" = no; # DA9062/DA9061 Dialog Semiconductor thermal driver

  #### STMicroelectronics thermal drivers
  "ST_THERMAL" = no; # Thermal sensors on STMicroelectronics STi series of SoCs
  "ST_THERMAL_MEMMAP" = no; # STi series memory mapped access based thermal sensors
  #### end of STMicroelectronics thermal drivers

  "GENERIC_ADC_THERMAL" = module; # Generic ADC based thermal sensor

  #### Qualcomm thermal drivers
  "QCOM_TSENS" = yes; # Qualcomm TSENS Temperature Alarm
  "QCOM_SPMI_ADC_TM5" = module; # Qualcomm SPMI PMIC Thermal Monitor ADC5
  "QCOM_SPMI_TEMP_ALARM" = yes; # Qualcomm SPMI PMIC Temperature Alarm
  "QCOM_LMH" = yes; # Qualcomm Limits Management Hardware
  #### end of Qualcomm thermal drivers

  "WATCHDOG" = yes; # Watchdog Timer Support
  "WATCHDOG_CORE" = yes; # WatchDog Timer Driver Core
  "WATCHDOG_NOWAYOUT" = no; # Disable watchdog shutdown on close
  "WATCHDOG_HANDLE_BOOT_ENABLED" = yes; # Update boot-enabled watchdog until userspace takes over
  "WATCHDOG_OPEN_TIMEOUT" = freeform "0"; # Timeout value for opening watchdog device
  "WATCHDOG_SYSFS" = no; # Read different watchdog information through sysfs
  "WATCHDOG_HRTIMER_PRETIMEOUT" = no; # Enable watchdog hrtimer-based pretimeouts
  "WATCHDOG_PRETIMEOUT_GOV" = no; # Enable watchdog pretimeout governors
  "SOFT_WATCHDOG" = no; # Software watchdog
  "CROS_EC_WATCHDOG" = no; # ChromeOS EC-based watchdog
  "DA9062_WATCHDOG" = no; # Dialog DA9062/61 Watchdog
  "GPIO_WATCHDOG" = no; # Watchdog device controlled through GPIO-line
  "WDAT_WDT" = no; # ACPI Watchdog Action Table (WDAT)
  "XILINX_WATCHDOG" = no; # Xilinx Watchdog timer
  "XILINX_WINDOW_WATCHDOG" = no; # Xilinx window watchdog timer
  "ZIIRAVE_WATCHDOG" = no; # Zodiac RAVE Watchdog Timer
  "AIROHA_WATCHDOG" = no; # Airoha EN7581 Watchdog
  "ARM_SP805_WATCHDOG" = no; # ARM SP805 Watchdog
  "ARM_SBSA_WATCHDOG" = no; # ARM SBSA Generic Watchdog
  "CADENCE_WATCHDOG" = no; # Cadence Watchdog Timer
  "DW_WATCHDOG" = no; # Synopsys DesignWare watchdog
  "MAX63XX_WATCHDOG" = no; # Max63xx watchdog
  "QCOM_WDT" = module; # QCOM watchdog
  "ARM_SMC_WATCHDOG" = no; # ARM Secure Monitor Call based watchdog support
  "STM32_WATCHDOG" = yes; # STM32 Independent WatchDoG (IWDG) support
  "RTD119X_WATCHDOG" = yes; # Realtek RTD119x/RTD129x watchdog support
  "PM8916_WATCHDOG" = module; # QCOM PM8916 pmic watchdog
  "ALIM7101_WDT" = no; # ALi M7101 PMU Computer Watchdog
  "I6300ESB_WDT" = no; # Intel 6300ESB Timer/Watchdog
  "HP_WATCHDOG" = no; # HP ProLiant iLO2+ Hardware Watchdog Timer
  "NIC7018_WDT" = no; # NIC7018 Watchdog
  "MEN_A21_WDT" = no; # MEN A21 VME CPU Carrier Board Watchdog Timer
  "XEN_WDT" = no; # Xen Watchdog support
  "PCIPCWATCHDOG" = no; # Berkshire Products PCI-PC Watchdog
  "WDTPCI" = no; # PCI-WDT500/501 Watchdog timer
  "USBPCWATCHDOG" = no; # Berkshire Products USB-PC Watchdog
  "SSB" = no; # Sonics Silicon Backplane support
  "BCMA" = no; # Broadcom specific AMBA

  ### Device Drivers -> Multifunction device drivers
  "MFD_ADP5585" = module; # Analog Devices ADP5585 keypad decoder and I/O expander driver
  "MFD_ACT8945A" = no; # Active-semi ACT8945A
  "MFD_AS3711" = no; # AMS AS3711
  "MFD_SMPRO" = no; # Ampere Computing SMpro core driver
  "MFD_AS3722" = no; # ams AS3722 Power Management IC
  "PMIC_ADP5520" = no; # Analog Devices ADP5520/01 MFD PMIC Core Support
  "MFD_AAT2870_CORE" = no; # AnalogicTech AAT2870
  "MFD_ATMEL_FLEXCOM" = no; # Atmel Flexcom (Flexible Serial Communication Unit)
  "MFD_ATMEL_HLCDC" = no; # Atmel HLCDC (High-end LCD Controller)
  "MFD_BCM590XX" = no; # Broadcom BCM590xx PMUs
  "MFD_BD9571MWV" = no; # ROHM BD9571MWV PMIC
  "MFD_AXP20X_I2C" = no; # X-Powers AXP series PMICs with I2C
  "MFD_CROS_EC_DEV" = yes; # ChromeOS Embedded Controller multifunction device
  "MFD_CS42L43_I2C" = no; # Cirrus Logic CS42L43 (I2C)
  "MFD_CS42L43_SDW" = no; # Cirrus Logic CS42L43 (SoundWire)
  "MFD_MADERA" = no; # Cirrus Logic Madera codecs
  "MFD_MAX5970" = no; # Maxim 5970/5978 power switch and monitor
  "PMIC_DA903X" = no; # Dialog Semiconductor DA9030/DA9034 PMIC Support
  "MFD_DA9052_SPI" = no; # Dialog Semiconductor DA9052/53 PMIC variants with SPI
  "MFD_DA9052_I2C" = no; # Dialog Semiconductor DA9052/53 PMIC variants with I2C
  "MFD_DA9055" = no; # Dialog Semiconductor DA9055 PMIC Support
  "MFD_DA9062" = module; # Dialog Semiconductor DA9062/61 PMIC Support
  "MFD_DA9063" = no; # Dialog Semiconductor DA9063 PMIC Support
  "MFD_DA9150" = no; # Dialog Semiconductor DA9150 Charger Fuel-Gauge chip
  "MFD_DLN2" = no; # Diolan DLN2 support
  "MFD_GATEWORKS_GSC" = no; # Gateworks System Controller
  "MFD_MC13XXX_SPI" = no; # Freescale MC13783 and MC13892 SPI interface
  "MFD_MC13XXX_I2C" = no; # Freescale MC13892 I2C interface
  "MFD_MP2629" = no; # Monolithic Power Systems MP2629 ADC and Battery charger
  "MFD_HI6421_PMIC" = no; # HiSilicon Hi6421 PMU/Codec IC
  "MFD_HI6421_SPMI" = no; # HiSilicon Hi6421v600 SPMI PMU/Codec IC
  "LPC_ICH" = no; # Intel ICH LPC
  "LPC_SCH" = no; # Intel SCH LPC
  "MFD_IQS62X" = no; # Azoteq IQS620A/621/622/624/625 core support
  "MFD_JANZ_CMODIO" = no; # Janz CMOD-IO PCI MODULbus Carrier Board
  "MFD_KEMPLD" = no; # Kontron module PLD device
  "MFD_88PM800" = no; # Marvell 88PM800
  "MFD_88PM805" = no; # Marvell 88PM805
  "MFD_88PM860X" = no; # Marvell 88PM8606/88PM8607
  "MFD_88PM886_PMIC" = no; # Marvell 88PM886 PMIC
  "MFD_MAX14577" = no; # Maxim Semiconductor MAX14577/77836 MUIC + Charger Support
  "MFD_MAX77541" = no; # Analog Devices MAX77541/77540 PMIC Support
  "MFD_MAX77620" = no; # Maxim Semiconductor MAX77620 and MAX20024 PMIC Support
  "MFD_MAX77650" = no; # Maxim MAX77650/77651 PMIC Support
  "MFD_MAX77686" = no; # Maxim Semiconductor MAX77686/802 PMIC Support
  "MFD_MAX77693" = no; # Maxim Semiconductor MAX77693 PMIC Support
  "MFD_MAX77705" = module; # Maxim MAX77705 PMIC Support
  "MFD_MAX77714" = no; # Maxim Semiconductor MAX77714 PMIC Support
  "MFD_MAX77759" = no; # Maxim Integrated MAX77759 PMIC
  "MFD_MAX77843" = no; # Maxim Semiconductor MAX77843 PMIC Support
  "MFD_MAX8907" = no; # Maxim Semiconductor MAX8907 PMIC Support
  "MFD_MAX8925" = no; # Maxim Semiconductor MAX8925 PMIC Support
  "MFD_MAX8997" = no; # Maxim Semiconductor MAX8997/8966 PMIC Support
  "MFD_MAX8998" = no; # Maxim Semiconductor MAX8998/National LP3974 PMIC Support
  "MFD_MT6360" = yes; # Mediatek MT6360 SubPMIC
  "MFD_MT6370" = no; # MediaTek MT6370 SubPMIC
  "MFD_MT6397" = no; # MediaTek MT6397 PMIC Support
  "MFD_MENF21BMC" = no; # MEN 14F021P00 Board Management Controller Support
  "MFD_OCELOT" = no; # Microsemi Ocelot External Control Support
  "EZX_PCAP" = no; # Motorola EZXPCAP Support
  "MFD_CPCAP" = no; # Support for Motorola CPCAP
  "MFD_VIPERBOARD" = no; # Nano River Technologies Viperboard
  "MFD_NTXEC" = no; # Netronix embedded controller (EC)
  "MFD_RETU" = no; # Nokia Retu and Tahvo multi-function device
  "MFD_QCOM_RPM" = yes; # Qualcomm Resource Power Manager (RPM)
  "MFD_SPMI_PMIC" = yes; # Qualcomm SPMI PMICs
  "MFD_SY7636A" = no; # Silergy SY7636A voltage regulator
  "MFD_RDC321X" = no; # RDC R-321x southbridge
  "MFD_RT4831" = no; # Richtek RT4831 four channel WLED and Display Bias Voltage
  "MFD_RT5033" = no; # Richtek RT5033 Power Management IC
  "MFD_RT5120" = no; # Richtek RT5120 Power Management IC
  "MFD_RC5T583" = no; # Ricoh RC5T583 Power Management system device
  "MFD_RK8XX_I2C" = yes; # Rockchip RK805/RK808/RK809/RK816/RK817/RK818 Power Management Chip
  "MFD_RK8XX_SPI" = yes; # Rockchip RK806 Power Management Chip
  "MFD_RN5T618" = no; # Ricoh RN5T567/618 PMIC
  "MFD_SEC_I2C" = yes; # Samsung Electronics S2MPA/S2MPS1X/S2MPU/S5M series PMICs
  "MFD_SI476X_CORE" = no; # Silicon Laboratories 4761/64/68 AM/FM radio.
  "MFD_SM501" = no; # Silicon Motion SM501
  "MFD_SKY81452" = no; # Skyworks Solutions SKY81452
  "MFD_STMPE" = no; # STMicroelectronics STMPE
  "MFD_SYSCON" = yes; # System Controller Register R/W Based on Regmap
  "MFD_LP3943" = no; # TI/National Semiconductor LP3943 MFD Driver
  "MFD_LP8788" = no; # TI LP8788 Power Management Unit Driver
  "MFD_TI_LMU" = no; # TI Lighting Management Unit driver
  "MFD_PALMAS" = no; # TI Palmas series chips
  "TPS6105X" = no; # TI TPS61050/61052 Boost Converters
  "TPS65010" = no; # TI TPS6501x Power Management chips
  "TPS6507X" = no; # TI TPS6507x Power Management / Touch Screen chips
  "MFD_TPS65086" = no; # TI TPS65086 Power Management Integrated Chips (PMICs)
  "MFD_TPS65090" = no; # TI TPS65090 Power Management chips
  "MFD_TPS65217" = no; # TI TPS65217 Power Management / White LED chips
  "MFD_TI_LP873X" = module; # TI LP873X Power Management IC
  "MFD_TI_LP87565" = no; # TI LP87565 Power Management IC
  "MFD_TPS65218" = no; # TI TPS65218 Power Management chips
  "MFD_TPS65219" = yes; # TI TPS65219 Power Management IC
  "MFD_TPS6586X" = no; # TI TPS6586x Power Management chips
  "MFD_TPS65910" = no; # TI TPS65910 Power Management chip
  "MFD_TPS65912_I2C" = no; # TI TPS65912 Power Management chip with I2C
  "MFD_TPS65912_SPI" = no; # TI TPS65912 Power Management chip with SPI
  "MFD_TPS6594_I2C" = module; # TI TPS6594 Power Management chip with I2C
  "MFD_TPS6594_SPI" = no; # TI TPS6594 Power Management chip with SPI
  "TWL4030_CORE" = no; # TI TWL4030/TWL5030/TWL6030/TPS659x0 Support
  "TWL6040_CORE" = no; # TI TWL6040 audio codec
  "MFD_WL1273_CORE" = no; # TI WL1273 FM radio
  "MFD_LM3533" = no; # TI/National Semiconductor LM3533 Lighting Power chip
  "MFD_TC3589X" = no; # Toshiba TC35892 and variants
  "MFD_TQMX86" = no; # TQ-Systems IO controller TQMX86
  "MFD_VX855" = no; # VIA VX855/VX875 integrated south bridge
  "MFD_LOCHNAGAR" = no; # Cirrus Logic Lochnagar Audio Development Board
  "MFD_ARIZONA_I2C" = no; # Cirrus Logic/Wolfson Microelectronics Arizona platform with I2C
  "MFD_ARIZONA_SPI" = no; # Cirrus Logic/Wolfson Microelectronics Arizona platform with SPI
  "MFD_WM8400" = no; # Wolfson Microelectronics WM8400
  "MFD_WM831X_I2C" = no; # Wolfson Microelectronics WM831x/2x PMICs with I2C
  "MFD_WM831X_SPI" = no; # Wolfson Microelectronics WM831x/2x PMICs with SPI
  "MFD_WM8350_I2C" = no; # Wolfson Microelectronics WM8350 with I2C
  "MFD_WM8994" = module; # Wolfson Microelectronics WM8994
  "MFD_ROHM_BD718XX" = no; # ROHM BD71837 Power Management IC
  "MFD_ROHM_BD71828" = no; # ROHM BD71828 and BD71815 Power Management IC
  "MFD_ROHM_BD957XMUF" = no; # ROHM BD9576MUF and BD9573MUF Power Management ICs
  "MFD_ROHM_BD96801" = no; # ROHM BD96801 Power Management IC
  "MFD_STM32_LPTIMER" = module; # Support for STM32 Low-Power Timer
  "MFD_STM32_TIMERS" = no; # Support for STM32 Timers
  "MFD_STPMIC1" = no; # Support for STPMIC1 PMIC
  "MFD_STMFX" = no; # Support for STMicroelectronics Multi-Function eXpander (STMFX)
  "MFD_WCD934X" = module; # Support for WCD9340/WCD9341 Codec
  "MFD_ATC260X_I2C" = no; # Actions Semi ATC260x PMICs with I2C
  "MFD_QCOM_PM8008" = no; # QCOM PM8008 Power Management IC
  "MFD_CS40L50_I2C" = no; # Cirrus Logic CS40L50 (I2C)
  "MFD_CS40L50_SPI" = no; # Cirrus Logic CS40L50 (SPI)
  "MFD_VEXPRESS_SYSREG" = yes; # Versatile Express System Registers
  "RAVE_SP_CORE" = no; # RAVE SP MCU core driver
  "MFD_INTEL_M10_BMC_SPI" = no; # Intel MAX 10 Board Management Controller with SPI
  "MFD_QNAP_MCU" = no; # QNAP microcontroller unit core driver
  "MFD_RSMU_I2C" = no; # Renesas Synchronization Management Unit with I2C
  "MFD_RSMU_SPI" = no; # Renesas Synchronization Management Unit with SPI
  ### Device Drivers: end of Multifunction device drivers

  "REGULATOR" = yes; # Voltage and Current Regulator Support
  "REGULATOR_DEBUG" = no; # Regulator debug support
  "REGULATOR_FIXED_VOLTAGE" = yes; # Fixed voltage regulator support
  "REGULATOR_VIRTUAL_CONSUMER" = no; # Virtual regulator consumer support
  "REGULATOR_USERSPACE_CONSUMER" = no; # Userspace regulator consumer support
  "REGULATOR_NETLINK_EVENTS" = no; # Enable support for receiving regulator events via netlink
  "REGULATOR_88PG86X" = no; # Marvell 88PG86X voltage regulators
  "REGULATOR_ACT8865" = no; # Active-semi act8865 voltage regulator
  "REGULATOR_AD5398" = no; # Analog Devices AD5398/AD5821 regulators
  "REGULATOR_ADP5055" = no; # Analog Devices ADP5055 Triple Buck Regulator
  "REGULATOR_ARM_SCMI" = yes; # SCMI based regulator driver
  "REGULATOR_AW37503" = no; # Awinic AW37503 Dual Output Power regulators
  "REGULATOR_CROS_EC" = yes; # ChromeOS EC regulators
  "REGULATOR_DA9062" = no; # Dialog Semiconductor DA9061/62 regulators
  "REGULATOR_DA9121" = no; # Dialog Semiconductor DA9121/DA9122/DA9220/DA9217/DA9130/DA9131/DA9132 regulator
  "REGULATOR_DA9210" = no; # Dialog Semiconductor DA9210 regulator
  "REGULATOR_DA9211" = module; # Dialog Semiconductor DA9211/DA9212/DA9213/DA9223/DA9214/DA9224/DA9215/DA9225 regulator
  "REGULATOR_FAN53555" = no; # Fairchild FAN53555 Regulator
  "REGULATOR_FAN53880" = no; # Fairchild FAN53880 Regulator
  "REGULATOR_GPIO" = yes; # GPIO regulator support
  "REGULATOR_ISL9305" = no; # Intersil ISL9305 regulator
  "REGULATOR_ISL6271A" = no; # Intersil ISL6271A Power regulator
  "REGULATOR_LP3971" = no; # National Semiconductors LP3971 PMIC regulator driver
  "REGULATOR_LP3972" = no; # National Semiconductors LP3972 PMIC regulator driver
  "REGULATOR_LP872X" = no; # TI/National Semiconductor LP8720/LP8725 voltage regulators
  "REGULATOR_LP873X" = module; # TI LP873X Power regulators
  "REGULATOR_LP8755" = no; # TI LP8755 High Performance PMU driver
  "REGULATOR_LTC3589" = no; # LTC3589 8-output voltage regulator
  "REGULATOR_LTC3676" = no; # LTC3676 8-output voltage regulator
  "REGULATOR_MAX1586" = no; # Maxim 1586/1587 voltage regulator
  "REGULATOR_MAX77503" = no; # Analog Devices MAX77503 Regulator
  "REGULATOR_MAX77857" = no; # ADI MAX77857/MAX77831 regulator support
  "REGULATOR_MAX8649" = no; # Maxim 8649 voltage regulator
  "REGULATOR_MAX8660" = no; # Maxim 8660/8661 voltage regulator
  "REGULATOR_MAX8893" = no; # Maxim 8893 voltage regulator
  "REGULATOR_MAX8952" = no; # Maxim MAX8952 Power Management IC
  "REGULATOR_MAX8973" = no; # Maxim MAX8973A voltage regulator
  "REGULATOR_MAX20086" = no; # Maxim MAX20086-MAX20089 Camera Power Protectors
  "REGULATOR_MAX20411" = module; # Maxim MAX20411 High-Efficiency Single Step-Down Converter
  "REGULATOR_MAX77826" = no; # Maxim 77826 regulator
  "REGULATOR_MCP16502" = no; # Microchip MCP16502 PMIC
  "REGULATOR_MP5416" = no; # Monolithic MP5416 PMIC
  "REGULATOR_MP8859" = no; # MPS MP8859 regulator driver
  "REGULATOR_MP886X" = no; # MPS MP8869 regulator driver
  "REGULATOR_MPQ7920" = no; # Monolithic MPQ7920 PMIC
  "REGULATOR_MT6311" = no; # MediaTek MT6311 PMIC
  "REGULATOR_MT6315" = module; # MediaTek MT6315 PMIC
  "REGULATOR_MT6360" = yes; # MT6360 SubPMIC Regulator
  "REGULATOR_PCA9450" = no; # NXP PCA9450A/PCA9450B/PCA9450C regulator driver
  "REGULATOR_PF9453" = no; # NXP PF9453 regulator driver
  "REGULATOR_PF8X00" = no; # NXP PF8100/PF8121A/PF8200 regulator driver
  "REGULATOR_PFUZE100" = no; # Freescale PFUZE100/200/3000/3001 regulator driver
  "REGULATOR_PV88060" = no; # Powerventure Semiconductor PV88060 regulator
  "REGULATOR_PV88080" = no; # Powerventure Semiconductor PV88080 regulator
  "REGULATOR_PV88090" = no; # Powerventure Semiconductor PV88090 regulator
  "REGULATOR_PWM" = yes; # PWM voltage regulator
  "REGULATOR_QCOM_REFGEN" = module; # Qualcomm REFGEN regulator driver
  "REGULATOR_QCOM_RPM" = no; # Qualcomm RPM regulator driver
  "REGULATOR_QCOM_RPMH" = yes; # Qualcomm Technologies, Inc. RPMh regulator driver
  "REGULATOR_QCOM_SMD_RPM" = yes; # Qualcomm SMD based RPM regulator driver
  "REGULATOR_QCOM_SPMI" = yes; # Qualcomm SPMI regulator driver
  "REGULATOR_QCOM_USB_VBUS" = module; # Qualcomm USB Vbus regulator driver
  "REGULATOR_RAA215300" = yes; # Renesas RAA215300 driver
  "REGULATOR_RASPBERRYPI_TOUCHSCREEN_ATTINY" = no; # Raspberry Pi 7-inch touchscreen panel ATTINY regulator
  "REGULATOR_RK808" = no; # Rockchip RK805/RK808/RK809/RK817/RK818 Power regulators
  "REGULATOR_RT4801" = no; # Richtek RT4801 Regulators
  "REGULATOR_RT4803" = no; # Richtek RT4803 boost regualtor
  "REGULATOR_RT5190A" = no; # Richtek RT5190A PMIC
  "REGULATOR_RT5739" = no; # Richtek RT5739 Regulator
  "REGULATOR_RT5759" = no; # Richtek RT5759 Regulator
  "REGULATOR_RT6160" = no; # Richtek RT6160 BuckBoost voltage regulator
  "REGULATOR_RT6190" = no; # Richtek RT6190 4-Switch BuckBoost controller
  "REGULATOR_RT6245" = no; # Richtek RT6245 voltage regulator
  "REGULATOR_RTQ2134" = no; # Richtek RTQ2134 SubPMIC Regulator
  "REGULATOR_RTMV20" = no; # Richtek RTMV20 Laser Diode Regulator
  "REGULATOR_RTQ6752" = no; # Richtek RTQ6752 TFT LCD voltage regulator
  "REGULATOR_RTQ2208" = no; # Richtek RTQ2208 SubPMIC Regulator
  "REGULATOR_S2DOS05" = module; # Samsung S2DOS05 voltage regulator
  "REGULATOR_S2MPA01" = no; # Samsung S2MPA01 voltage regulator
  "REGULATOR_S2MPS11" = no; # Samsung S2MPS11/13/14/15/S2MPU02/05 voltage regulator
  "REGULATOR_S5M8767" = no; # Samsung S5M8767A voltage regulator
  "REGULATOR_SLG51000" = no; # Dialog Semiconductor SLG51000 regulators
  "REGULATOR_STM32_BOOSTER" = no; # STMicroelectronics STM32 BOOSTER
  "REGULATOR_STM32_VREFBUF" = no; # STMicroelectronics STM32 VREFBUF
  "REGULATOR_STM32_PWR" = no; # STMicroelectronics STM32 PWR
  "REGULATOR_SY8106A" = no; # Silergy SY8106A regulator
  "REGULATOR_SY8824X" = no; # Silergy SY8824C/SY8824E regulator
  "REGULATOR_SY8827N" = no; # Silergy SY8827N regulator
  "REGULATOR_TPS51632" = no; # TI TPS51632 Power Regulator
  "REGULATOR_TPS62360" = no; # TI TPS6236x Power Regulator
  "REGULATOR_TPS6286X" = no; # TI TPS6286x Power Regulator
  "REGULATOR_TPS6287X" = no; # TI TPS6287x Power Regulator
  "REGULATOR_TPS65023" = no; # TI TPS65023 Power regulators
  "REGULATOR_TPS6507X" = no; # TI TPS6507X Power regulators
  "REGULATOR_TPS65132" = no; # TI TPS65132 Dual Output Power regulators
  "REGULATOR_TPS65219" = yes; # TI TPS65219 Power regulators
  "REGULATOR_TPS6594" = module; # TI TPS6594 Power regulators
  "REGULATOR_TPS6524X" = no; # TI TPS6524X Power regulators
  "REGULATOR_VCTRL" = no; # Voltage controlled regulators
  "REGULATOR_VEXPRESS" = no; # Versatile Express regulators
  "REGULATOR_VQMMC_IPQ4019" = no; # IPQ4019 VQMMC SD LDO regulator support
  "REGULATOR_WM8994" = no; # Wolfson Microelectronics WM8994 CODEC
  "REGULATOR_QCOM_LABIBB" = yes; # QCOM LAB/IBB regulator support
  "RC_CORE" = module; # Remote Controller support
  "LIRC" = no; # LIRC user interface
  "RC_MAP" = module; # Compile Remote Controller keymap modules
  "RC_DECODERS" = yes; # Remote controller decoders
  "IR_IMON_DECODER" = no; # Enable IR raw decoder for the iMON protocol
  "IR_JVC_DECODER" = no; # Enable IR raw decoder for the JVC protocol
  "IR_MCE_KBD_DECODER" = no; # Enable IR raw decoder for the MCE keyboard/mouse protocol
  "IR_NEC_DECODER" = no; # Enable IR raw decoder for the NEC protocol
  "IR_RC5_DECODER" = no; # Enable IR raw decoder for the RC-5 protocol
  "IR_RC6_DECODER" = no; # Enable IR raw decoder for the RC6 protocol
  "IR_RCMM_DECODER" = no; # Enable IR raw decoder for the RC-MM protocol
  "IR_SANYO_DECODER" = no; # Enable IR raw decoder for the Sanyo protocol
  "IR_SHARP_DECODER" = no; # Enable IR raw decoder for the Sharp protocol
  "IR_SONY_DECODER" = no; # Enable IR raw decoder for the Sony protocol
  "IR_XMP_DECODER" = no; # Enable IR raw decoder for the XMP protocol
  "RC_DEVICES" = yes; # Remote Controller devices
  "IR_ENE" = no; # ENE eHome Receiver/Transceiver (pnp id: ENE0100/ENE02xxx)
  "IR_FINTEK" = no; # Fintek Consumer Infrared Transceiver
  "IR_GPIO_CIR" = module; # GPIO IR remote control
  "IR_HIX5HD2" = no; # Hisilicon hix5hd2 IR remote control
  "IR_IGORPLUGUSB" = no; # IgorPlug-USB IR Receiver
  "IR_IGUANA" = no; # IguanaWorks USB IR Transceiver
  "IR_IMON" = no; # SoundGraph iMON Receiver and Display
  "IR_IMON_RAW" = no; # SoundGraph iMON Receiver (early raw IR models)
  "IR_ITE_CIR" = no; # ITE Tech Inc. IT8712/IT8512 Consumer Infrared Transceiver
  "IR_MCEUSB" = no; # Windows Media Center Ed. eHome Infrared Transceiver
  "IR_NUVOTON" = no; # Nuvoton w836x7hg Consumer Infrared Transceiver
  "IR_REDRAT3" = no; # RedRat3 IR Transceiver
  "IR_SERIAL" = no; # Homebrew Serial Port Receiver
  "IR_STREAMZAP" = no; # Streamzap PC Remote IR Receiver
  "IR_TOY" = no; # Infrared Toy and IR Droid
  "IR_TTUSBIR" = no; # TechnoTrend USB IR Receiver
  "RC_ATI_REMOTE" = no; # ATI / X10 based USB RF remote controls
  "RC_LOOPBACK" = no; # Remote Control Loopback Driver
  "RC_XBOX_DVD" = no; # Xbox DVD Movie Playback Kit

  ### Device Drivers -> CEC support
  "MEDIA_CEC_RC" = no; # HDMI CEC RC integration
  "MEDIA_CEC_SUPPORT" = yes; # HDMI CEC drivers
  "CEC_CH7322" = no; # Chrontel CH7322 CEC controller
  "CEC_NXP_TDA9950" = module; # NXP Semiconductors TDA9950/TDA998X HDMI CEC
  "CEC_CROS_EC" = no; # ChromeOS EC CEC driver
  "CEC_GPIO" = no; # Generic GPIO-based CEC driver
  "CEC_STM32" = no; # STMicroelectronics STM32 HDMI CEC driver
  "USB_EXTRON_DA_HD_4K_PLUS_CEC" = no; # Extron DA HD 4K Plus CEC driver
  "USB_PULSE8_CEC" = no; # Pulse Eight HDMI CEC
  "USB_RAINSHADOW_CEC" = no; # RainShadow Tech HDMI CEC
  ### Device Drivers: end of CEC support

  "MEDIA_SUPPORT" = module; # Multimedia support
  "MEDIA_SUPPORT_FILTER" = yes; # Filter media drivers
  "MEDIA_SUBDRV_AUTOSELECT" = yes; # Autoselect ancillary drivers (tuners, sensors, i2c, spi, frontends)

  #### Media device types
  "MEDIA_CAMERA_SUPPORT" = yes; # Cameras and video grabbers
  "MEDIA_ANALOG_TV_SUPPORT" = no; # Analog TV
  "MEDIA_DIGITAL_TV_SUPPORT" = no; # Digital TV
  "MEDIA_RADIO_SUPPORT" = no; # AM/FM radio receivers/transmitters
  "MEDIA_SDR_SUPPORT" = no; # Software defined radio
  "MEDIA_PLATFORM_SUPPORT" = yes; # Platform-specific devices
  "MEDIA_TEST_SUPPORT" = no; # Test drivers
  #### end of Media device types

  #### Video4Linux options
  "VIDEO_ADV_DEBUG" = no; # Enable advanced debug functionality on V4L2 drivers
  "VIDEO_FIXED_MINOR_RANGES" = no; # Enable old-style fixed minor ranges on drivers/video devices
  "V4L2_FLASH_LED_CLASS" = no; # V4L2 flash API for LED flash class devices
  #### end of Video4Linux options

  #### Media drivers
  "MEDIA_USB_SUPPORT" = yes; # Media USB Adapters
  "USB_GSPCA" = no; # GSPCA based webcams
  "USB_PWC" = no; # USB Philips Cameras
  "USB_S2255" = no; # USB Sensoray 2255 video capture device
  "VIDEO_USBTV" = no; # USBTV007 video capture support
  "USB_VIDEO_CLASS" = module; # USB Video Class (UVC)
  "USB_VIDEO_CLASS_INPUT_EVDEV" = yes; # UVC input events device support
  "VIDEO_EM28XX" = no; # Empia EM28xx USB devices support
  "MEDIA_PCI_SUPPORT" = no; # Media PCI Adapters
  "MEDIA_PLATFORM_DRIVERS" = yes; # Media platform devices
  "V4L_PLATFORM_DRIVERS" = yes; # V4L platform devices
  "V4L_MEM2MEM_DRIVERS" = yes; # Memory-to-memory multimedia devices
  "VIDEO_MEM2MEM_DEINTERLACE" = no; # Deinterlace support
  "VIDEO_MUX" = no; # Video Multiplexer
  "VIDEO_CADENCE_CSI2RX" = module; # Cadence MIPI-CSI2 RX Controller
  "VIDEO_CADENCE_CSI2TX" = no; # Cadence MIPI-CSI2 TX Controller
  "VIDEO_CAFE_CCIC" = no; # Marvell 88ALP01 (Cafe) CMOS Camera Controller support
  "VIDEO_QCOM_CAMSS" = module; # Qualcomm V4L2 Camera Subsystem driver
  "VIDEO_QCOM_IRIS" = module; # Qualcomm iris V4L2 decoder driver
  "VIDEO_QCOM_VENUS" = module; # Qualcomm Venus V4L2 encoder/decoder driver
  "VIDEO_RP1_CFE" = no; # Raspberry Pi RP1 Camera Front End (CFE) video capture driver
  "VIDEO_STM32_CSI" = no; # STM32 Camera Serial Interface (CSI) support
  "VIDEO_STM32_DCMI" = no; # STM32 Digital Camera Memory Interface (DCMI) support
  "VIDEO_STM32_DCMIPP" = no; # STM32 Digital Camera Memory Interface Pixel Processor (DCMIPP) support
  "VIDEO_STM32_DMA2D" = no; # STM32 Chrom-Art Accelerator (DMA2D)
  "VIDEO_HANTRO" = module; # Hantro VPU driver
  "VIDEO_HANTRO_HEVC_RFC" = no; # Use reference frame compression for HEVC
  "VIDEO_HANTRO_STM32MP25" = yes; # Hantro STM32MP25 support
  "VIDEO_XILINX" = no; # Xilinx Video IP (EXPERIMENTAL)
  #### end of Media drivers

  #### Media ancillary drivers
  "VIDEO_CAMERA_SENSOR" = yes; # Camera sensor devices
  "VIDEO_ALVIUM_CSI2" = no; # Allied Vision ALVIUM MIPI CSI-2 camera support
  "VIDEO_AR0521" = no; # ON Semiconductor AR0521 sensor support
  "VIDEO_GC0308" = no; # GalaxyCore GC0308 sensor support
  "VIDEO_GC05A2" = no; # GalaxyCore gc05a2 sensor support
  "VIDEO_GC08A3" = no; # GalaxyCore gc08a3 sensor support
  "VIDEO_GC2145" = no; # GalaxyCore GC2145 sensor support
  "VIDEO_HI556" = no; # Hynix Hi-556 sensor support
  "VIDEO_HI846" = no; # Hynix Hi-846 sensor support
  "VIDEO_HI847" = no; # Hynix Hi-847 sensor support
  "VIDEO_IMX208" = no; # Sony IMX208 sensor support
  "VIDEO_IMX214" = no; # Sony IMX214 sensor support
  "VIDEO_IMX219" = no; # Sony IMX219 sensor support
  "VIDEO_IMX258" = no; # Sony IMX258 sensor support
  "VIDEO_IMX274" = no; # Sony IMX274 sensor support
  "VIDEO_IMX283" = no; # Sony IMX283 sensor support
  "VIDEO_IMX290" = no; # Sony IMX290 sensor support
  "VIDEO_IMX296" = no; # Sony IMX296 sensor support
  "VIDEO_IMX319" = no; # Sony IMX319 sensor support
  "VIDEO_IMX334" = no; # Sony IMX334 sensor support
  "VIDEO_IMX335" = no; # Sony IMX335 sensor support
  "VIDEO_IMX355" = no; # Sony IMX355 sensor support
  "VIDEO_IMX363" = module; # Sony IMX363 sensor support
  "VIDEO_IMX371" = module; # Sony IMX371 sensor support
  "VIDEO_IMX376" = module; # Sony IMX376 sensor support
  "VIDEO_IMX412" = module; # Sony IMX412 sensor support
  "VIDEO_IMX415" = no; # Sony IMX415 sensor support
  "VIDEO_IMX519" = module; # Sony IMX519 sensor support
  "VIDEO_MT9M001" = no; # mt9m001 support
  "VIDEO_MT9M111" = no; # mt9m111, mt9m112 and mt9m131 support
  "VIDEO_MT9M114" = no; # onsemi MT9M114 sensor support
  "VIDEO_MT9P031" = no; # Aptina MT9P031 support
  "VIDEO_MT9T112" = no; # Aptina MT9T111/MT9T112 support
  "VIDEO_MT9V011" = no; # Micron mt9v011 sensor support
  "VIDEO_MT9V032" = no; # Micron MT9V032 sensor support
  "VIDEO_MT9V111" = no; # Aptina MT9V111 sensor support
  "VIDEO_OG01A1B" = no; # OmniVision OG01A1B sensor support
  "VIDEO_OV01A10" = no; # OmniVision OV01A10 sensor support
  "VIDEO_OV02A10" = no; # OmniVision OV02A10 sensor support
  "VIDEO_OV02E10" = no; # OmniVision OV02E10 sensor support
  "VIDEO_OV02C10" = no; # OmniVision OV02C10 sensor support
  "VIDEO_OV08D10" = no; # OmniVision OV08D10 sensor support
  "VIDEO_OV08X40" = no; # OmniVision OV08X40 sensor support
  "VIDEO_OV13858" = no; # OmniVision OV13858 sensor support
  "VIDEO_OV13B10" = no; # OmniVision OV13B10 sensor support
  "VIDEO_OV2640" = no; # OmniVision OV2640 sensor support
  "VIDEO_OV2659" = no; # OmniVision OV2659 sensor support
  "VIDEO_OV2680" = no; # OmniVision OV2680 sensor support
  "VIDEO_OV2685" = no; # OmniVision OV2685 sensor support
  "VIDEO_OV2740" = no; # OmniVision OV2740 sensor support
  "VIDEO_OV4689" = no; # OmniVision OV4689 sensor support
  "VIDEO_OV5640" = module; # OmniVision OV5640 sensor support
  "VIDEO_OV5645" = no; # OmniVision OV5645 sensor support
  "VIDEO_OV5647" = no; # OmniVision OV5647 sensor support
  "VIDEO_OV5648" = no; # OmniVision OV5648 sensor support
  "VIDEO_OV5670" = no; # OmniVision OV5670 sensor support
  "VIDEO_OV5675" = no; # OmniVision OV5675 sensor support
  "VIDEO_OV5693" = no; # OmniVision OV5693 sensor support
  "VIDEO_OV5695" = no; # OmniVision OV5695 sensor support
  "VIDEO_OV64A40" = no; # OmniVision OV64A40 sensor support
  "VIDEO_OV6650" = no; # OmniVision OV6650 sensor support
  "VIDEO_OV7251" = no; # OmniVision OV7251 sensor support
  "VIDEO_OV7640" = no; # OmniVision OV7640 sensor support
  "VIDEO_OV7670" = no; # OmniVision OV7670 sensor support
  "VIDEO_OV772X" = no; # OmniVision OV772x sensor support
  "VIDEO_OV7740" = no; # OmniVision OV7740 sensor support
  "VIDEO_OV8856" = no; # OmniVision OV8856 sensor support
  "VIDEO_OV8858" = no; # OmniVision OV8858 sensor support
  "VIDEO_OV8865" = no; # OmniVision OV8865 sensor support
  "VIDEO_OV9282" = no; # OmniVision OV9282 sensor support
  "VIDEO_OV9640" = no; # OmniVision OV9640 sensor support
  "VIDEO_OV9650" = no; # OmniVision OV9650/OV9652 sensor support
  "VIDEO_OV9734" = no; # OmniVision OV9734 sensor support
  "VIDEO_RDACM20" = no; # IMI RDACM20 camera support
  "VIDEO_RDACM21" = no; # IMI RDACM21 camera support
  "VIDEO_RJ54N1" = no; # Sharp RJ54N1CB0C sensor support
  "VIDEO_S5C73M3" = no; # Samsung S5C73M3 sensor support
  "VIDEO_S5K5BAF" = no; # Samsung S5K5BAF sensor support
  "VIDEO_S5K6A3" = no; # Samsung S5K6A3 sensor support
  "VIDEO_VD55G1" = no; # ST VD55G1 sensor support
  "VIDEO_VD56G3" = no; # ST VD56G3 sensor support
  "VIDEO_VGXY61" = no; # ST VGXY61 sensor support
  "VIDEO_CCS" = no; # MIPI CCS/SMIA++/SMIA sensor support
  "VIDEO_ET8EK8" = no; # ET8EK8 camera sensor support

  ##### Media ancillary drivers -> Camera ISPs
  "VIDEO_THP7312" = no; # THine THP7312 support
  ##### Media ancillary drivers: end of Camera ISPs

  ##### Media ancillary drivers -> Lens drivers
  "VIDEO_AD5820" = no; # AD5820 lens voice coil support
  "VIDEO_AK7375" = no; # AK7375 lens voice coil support
  "VIDEO_BU64748" = module; # BU64748 lens voice coil support
  "VIDEO_DW9714" = no; # DW9714 lens voice coil support
  "VIDEO_DW9719" = no; # DW9719 lens voice coil support
  "VIDEO_DW9768" = no; # DW9768 lens voice coil support
  "VIDEO_DW9807_VCM" = no; # DW9807 lens voice coil support
  "VIDEO_LC898217XC" = module; # LC898217XC lens voice coil support
  ##### Media ancillary drivers: end of Lens drivers

  ##### Media ancillary drivers -> Flash devices
  "VIDEO_ADP1653" = no; # ADP1653 flash support
  "VIDEO_LM3560" = no; # LM3560 dual flash driver support
  "VIDEO_LM3646" = no; # LM3646 dual flash driver support
  ##### Media ancillary drivers: end of Flash devices

  ##### Media ancillary drivers -> Video serializers and deserializers
  "VIDEO_DS90UB913" = no; # TI DS90UB913 FPD-Link III Serializer
  "VIDEO_DS90UB953" = no; # TI FPD-Link III/IV CSI-2 Serializers
  "VIDEO_DS90UB960" = no; # TI FPD-Link III/IV Deserializers
  "VIDEO_MAX96714" = no; # Maxim MAX96714 GMSL2 deserializer
  "VIDEO_MAX96717" = no; # Maxim MAX96717 GMSL2 Serializer support
  ##### Media ancillary drivers: end of Video serializers and deserializers

  ##### Media ancillary drivers -> Media SPI Adapters
  "VIDEO_GS1662" = no; # Gennum Serializers video
  ##### Media ancillary drivers: end of Media SPI Adapters
  #### end of Media ancillary drivers

  ### Device Drivers -> Graphics support
  "AUXDISPLAY" = no; # Auxiliary Display support
  "DRM" = yes; # Direct Rendering Manager (XFree86 4.1.0 and higher DRI support)

  ##### DRM debugging options
  "DRM_DEBUG_MM" = no; # Insert extra checks and debug info into the DRM range managers
  ##### end of DRM debugging options

  "DRM_PANIC" = no; # Display a user-friendly message when a kernel panic occurs

  ##### Supported DRM clients
  "DRM_FBDEV_EMULATION" = yes; # Enable legacy fbdev support for your modesetting driver
  "DRM_FBDEV_OVERALLOC" = freeform "100"; # Overallocation of the fbdev buffer
  "DRM_CLIENT_LOG" = no; # Print the kernel boot message on the screen
  "DRM_CLIENT_DEFAULT_FBDEV" = yes; # fbdev
  ##### end of Supported DRM clients

  "DRM_LOAD_EDID_FIRMWARE" = no; # Allow to specify an EDID data set instead of probing for it
  "DRM_DISPLAY_DP_AUX_CEC" = no; # Enable DisplayPort CEC-Tunneling-over-AUX HDMI support
  "DRM_DISPLAY_DP_AUX_CHARDEV" = no; # DRM DP AUX Interface

  ##### Drivers for system framebuffers
  "DRM_EFIDRM" = no; # EFI framebuffer driver
  "DRM_SIMPLEDRM" = no; # Simple framebuffer driver
  ##### end of Drivers for system framebuffers

  ##### ARM devices
  "DRM_HDLCD" = module; # ARM HDLCD
  "DRM_HDLCD_SHOW_UNDERRUN" = no; # Show underrun conditions
  "DRM_MALI_DISPLAY" = no; # ARM Mali Display Processor
  "DRM_KOMEDA" = module; # ARM Komeda display driver
  ##### end of ARM devices

  "DRM_RADEON" = no; # ATI Radeon
  "DRM_AMDGPU" = no; # AMD GPU
  "DRM_NOUVEAU" = no; # Nouveau (NVIDIA) cards
  "DRM_XE" = no; # Intel Xe Graphics
  "DRM_VGEM" = no; # Virtual GEM provider
  "DRM_VKMS" = no; # Virtual KMS (EXPERIMENTAL)
  "DRM_VMWGFX" = no; # DRM driver for VMware Virtual GPU
  "DRM_UDL" = module; # DisplayLink
  "DRM_AST" = no; # AST server chips
  "DRM_MGAG200" = no; # Matrox G200
  "DRM_QXL" = no; # QXL virtual GPU
  "DRM_VIRTIO_GPU" = no; # Virtio GPU driver
  "DRM_MSM" = yes; # MSM DRM
  "DRM_MSM_MDP4" = yes; # Enable MDP4 support in MSM DRM driver
  "DRM_MSM_MDP5" = yes; # Enable MDP5 support in MSM DRM driver
  "DRM_MSM_DPU" = yes; # Enable DPU support in MSM DRM driver
  "DRM_MSM_DP" = yes; # Enable DisplayPort support in MSM DRM driver
  "DRM_MSM_DSI" = yes; # Enable DSI support in MSM DRM driver
  "DRM_MSM_DSI_28NM_PHY" = yes; # Enable DSI 28nm PHY driver in MSM DRM
  "DRM_MSM_DSI_20NM_PHY" = yes; # Enable DSI 20nm PHY driver in MSM DRM
  "DRM_MSM_DSI_28NM_8960_PHY" = yes; # Enable DSI 28nm 8960 PHY driver in MSM DRM
  "DRM_MSM_DSI_14NM_PHY" = yes; # Enable DSI 14nm PHY driver in MSM DRM (used by MSM8996/APQ8096)
  "DRM_MSM_DSI_10NM_PHY" = yes; # Enable DSI 10nm PHY driver in MSM DRM (used by SDM845)
  "DRM_MSM_DSI_7NM_PHY" = yes; # Enable DSI 7nm/5nm/4nm PHY driver in MSM DRM
  "DRM_MSM_HDMI" = yes; # Enable HDMI support in MSM DRM driver
  "DRM_MSM_HDMI_HDCP" = yes; # Enable HDMI HDCP support in MSM DRM driver
  "DRM_STM" = no; # DRM Support for STMicroelectronics SoC Series

  ##### Display Panels
  "DRM_PANEL_ABT_Y030XX067A" = no; # ABT Y030XX067A 320x480 LCD panel
  "DRM_PANEL_ARM_VERSATILE" = no; # ARM Versatile panel driver
  "DRM_PANEL_ASUS_Z00T_TM5P5_NT35596" = no; # ASUS Z00T TM5P5 NT35596 panel
  "DRM_PANEL_AUO_A030JTN01" = no; # AUO A030JTN01
  "DRM_PANEL_BOE_BF060Y8M_AJ0" = no; # Boe BF060Y8M-AJ0 panel
  "DRM_PANEL_BOE_HIMAX8279D" = no; # Boe Himax8279d panel
  "DRM_PANEL_BOE_TD4320" = no; # BOE TD4320 DSI panel
  "DRM_PANEL_BOE_TH101MB31UIG002_28A" = no; # Boe TH101MB31UIG002-28A panel
  "DRM_PANEL_BOE_TV101WUM_NL6" = module; # BOE TV101WUM and AUO KD101N80 45NA 1200x1920 panel
  "DRM_PANEL_BOE_TV101WUM_LL2" = no; # BOE TV101WUM LL2 1200x1920 panel
  "DRM_PANEL_EBBG_FT8719" = yes; # EBBG FT8719 panel driver
  "DRM_PANEL_ELIDA_KD35T133" = no; # Elida KD35T133 panel driver
  "DRM_PANEL_FEIXIN_K101_IM2BA02" = no; # Feixin K101 IM2BA02 panel
  "DRM_PANEL_FEIYANG_FY07024DI26A30D" = no; # Feiyang FY07024DI26A30-D MIPI-DSI LCD panel
  "DRM_PANEL_DSI_CM" = no; # Generic DSI command mode panels
  "DRM_PANEL_LVDS" = no; # Generic LVDS panel driver
  "DRM_PANEL_HIMAX_HX8279" = module; # Himax HX8279-based panels
  "DRM_PANEL_HIMAX_HX83102" = no; # Himax HX83102-based panels
  "DRM_PANEL_HIMAX_HX83112A" = no; # Himax HX83112A-based DSI panel
  "DRM_PANEL_HIMAX_HX8394" = no; # HIMAX HX8394 MIPI-DSI LCD panels
  "DRM_PANEL_ILITEK_IL9322" = no; # Ilitek ILI9322 320x240 QVGA panels
  "DRM_PANEL_ILITEK_ILI9341" = no; # Ilitek ILI9341 240x320 QVGA panels
  "DRM_PANEL_ILITEK_ILI9805" = no; # Ilitek ILI9805-based panels
  "DRM_PANEL_ILITEK_ILI9806E" = no; # Ilitek ILI9806E-based panels
  "DRM_PANEL_ILITEK_ILI9881C" = no; # Ilitek ILI9881C-based panels
  "DRM_PANEL_ILITEK_ILI9882T" = module; # Ilitek ILI9882t-based panels
  "DRM_PANEL_INNOLUX_EJ030NA" = no; # Innolux EJ030NA 320x480 LCD panel
  "DRM_PANEL_INNOLUX_P079ZCA" = no; # Innolux P079ZCA panel
  "DRM_PANEL_JADARD_JD9365DA_H3" = no; # Jadard JD9365DA-H3 WXGA DSI panel
  "DRM_PANEL_JDI_LPM102A188A" = no; # JDI LPM102A188A DSI panel
  "DRM_PANEL_JDI_LT070ME05000" = no; # JDI LT070ME05000 WUXGA DSI panel
  "DRM_PANEL_JDI_R63452" = no; # JDI R63452 Full HD DSI panel
  "DRM_PANEL_KHADAS_TS050" = module; # Khadas TS050 panel
  "DRM_PANEL_KINGDISPLAY_KD097D04" = no; # Kingdisplay kd097d04 panel
  "DRM_PANEL_LEADTEK_LTK050H3146W" = no; # Leadtek LTK050H3146W panel
  "DRM_PANEL_LEADTEK_LTK500HD1829" = no; # Leadtek LTK500HD1829 panel
  "DRM_PANEL_LINCOLNTECH_LCD197" = no; # Lincoln Technologies lcd197 panel
  "DRM_PANEL_LG_LB035Q02" = no; # LG LB035Q024573 RGB panel
  "DRM_PANEL_LG_LG4573" = no; # LG4573 RGB/SPI panel
  "DRM_PANEL_LG_SW43408" = yes; # LG SW43408 panel
  "DRM_PANEL_LG_SW49410" = yes; # LG SW49410 panel
  "DRM_PANEL_MAGNACHIP_D53E6EA8966" = no; # Magnachip D53E6EA8966 DSI panel
  "DRM_PANEL_MANTIX_MLAF057WE51" = module; # Mantix MLAF057WE51-X MIPI-DSI LCD panel
  "DRM_PANEL_NEC_NL8048HL11" = no; # NEC NL8048HL11 RGB panel
  "DRM_PANEL_NEWVISION_NV3051D" = no; # NewVision NV3051D DSI panel
  "DRM_PANEL_NEWVISION_NV3052C" = no; # NewVision NV3052C RGB/SPI panel
  "DRM_PANEL_NOVATEK_NT35510" = no; # Novatek NT35510 RGB panel driver
  "DRM_PANEL_NOVATEK_NT35560" = no; # Novatek NT35560 DSI command mode panel
  "DRM_PANEL_NOVATEK_NT35596S" = yes; # Novatek NT35596S DSI panel
  "DRM_PANEL_NOVATEK_NT35950" = no; # Novatek NT35950 DSI panel
  "DRM_PANEL_NOVATEK_NT36523" = no; # Novatek NT36523 panel driver
  "DRM_PANEL_NOVATEK_NT36672A" = yes; # Novatek NT36672A DSI panel
  "DRM_PANEL_NOVATEK_NT36672E" = module; # Novatek NT36672E DSI panel
  "DRM_PANEL_NOVATEK_NT37801" = no; # Novatek NT37801/NT37810 AMOLED DSI panel
  "DRM_PANEL_NOVATEK_NT39016" = no; # Novatek NT39016 RGB/SPI panel
  "DRM_PANEL_OLIMEX_LCD_OLINUXINO" = no; # Olimex LCD-OLinuXino panel
  "DRM_PANEL_ORISETECH_OTA5601A" = no; # Orise Technology ota5601a RGB/SPI panel
  "DRM_PANEL_ORISETECH_OTM8009A" = no; # Orise Technology otm8009a 480x800 dsi 2dl panel
  "DRM_PANEL_OSD_OSD101T2587_53TS" = no; # OSD OSD101T2587-53TS DSI 1920x1200 video mode panel
  "DRM_PANEL_PANASONIC_VVX10F034N00" = no; # Panasonic VVX10F034N00 1920x1200 video mode panel
  "DRM_PANEL_RASPBERRYPI_TOUCHSCREEN" = no; # Raspberry Pi 7-inch touchscreen panel
  "DRM_PANEL_RAYDIUM_RM67191" = no; # Raydium RM67191 FHD 1080x1920 DSI video mode panel
  "DRM_PANEL_RAYDIUM_RM67200" = no; # Raydium RM67200-based DSI panel
  "DRM_PANEL_RAYDIUM_RM68200" = no; # Raydium RM68200 720x1280 DSI video mode panel
  "DRM_PANEL_RAYDIUM_RM692E5" = no; # Raydium RM692E5-based DSI panel
  "DRM_PANEL_RAYDIUM_RM69380" = no; # Raydium RM69380-based DSI panel
  "DRM_PANEL_RONBO_RB070D30" = no; # Ronbo Electronics RB070D30 panel
  "DRM_PANEL_SAMSUNG_AMS581VF01" = no; # Samsung AMS581VF01 panel
  "DRM_PANEL_SAMSUNG_AMS639RQ08" = no; # Samsung AMS639RQ08 panel
  "DRM_PANEL_SAMSUNG_S6E88A0_AMS427AP24" = no; # Samsung AMS427AP24 panel with S6E88A0 controller
  "DRM_PANEL_SAMSUNG_S6E88A0_AMS452EF01" = no; # Samsung AMS452EF01 panel with S6E88A0 DSI video mode controller
  "DRM_PANEL_SAMSUNG_ATNA33XC20" = module; # Samsung ATNA33XC20 eDP panel
  "DRM_PANEL_SAMSUNG_DB7430" = no; # Samsung DB7430-based DPI panels
  "DRM_PANEL_SAMSUNG_LD9040" = no; # Samsung LD9040 RGB/SPI panel
  "DRM_PANEL_SAMSUNG_EA8076" = no; # Samsung EA8076 DSI cmd mode panels
  "DRM_PANEL_SAMSUNG_S6E3FA7" = no; # Samsung S6E3FA7 panel driver
  "DRM_PANEL_SAMSUNG_S6D16D0" = no; # Samsung S6D16D0 DSI video mode panel
  "DRM_PANEL_SAMSUNG_S6D27A1" = no; # Samsung S6D27A1 DPI panel driver
  "DRM_PANEL_SAMSUNG_S6D7AA0" = no; # Samsung S6D7AA0 MIPI-DSI video mode panel controller
  "DRM_PANEL_SAMSUNG_S6E3HA2" = no; # Samsung S6E3HA2 DSI video mode panel
  "DRM_PANEL_SAMSUNG_S6E3HA8" = yes; # Samsung S6E3HA8 DSI video mode panel
  "DRM_PANEL_SAMSUNG_S6E63J0X03" = no; # Samsung S6E63J0X03 DSI command mode panel
  "DRM_PANEL_SAMSUNG_S6E63M0" = no; # Samsung S6E63M0 RGB panel
  "DRM_PANEL_SAMSUNG_S6E8AA0" = no; # Samsung S6E8AA0 DSI video mode panel
  "DRM_PANEL_SAMSUNG_SOFEF00" = yes; # Samsung sofef00/s6e3fc2x01 OnePlus 6/6T DSI cmd mode panels
  "DRM_PANEL_SAMSUNG_S6E3FC2X01" = yes; # Samsung s6e3fc2x01 OnePlus 6T DSI cmd mode panel
  "DRM_PANEL_SEIKO_43WVF1G" = no; # Seiko 43WVF1G panel
  "DRM_PANEL_SHARP_LQ101R1SX01" = no; # Sharp LQ101R1SX01 panel
  "DRM_PANEL_SHARP_LS037V7DW01" = no; # Sharp LS037V7DW01 VGA LCD panel
  "DRM_PANEL_SHARP_LS043T1LE01" = no; # Sharp LS043T1LE01 qHD video mode panel
  "DRM_PANEL_SHARP_LS060T1SX01" = no; # Sharp LS060T1SX01 FullHD video mode panel
  "DRM_PANEL_SITRONIX_ST7701" = no; # Sitronix ST7701 panel driver
  "DRM_PANEL_SITRONIX_ST7703" = no; # Sitronix ST7703 based MIPI touchscreen panels
  "DRM_PANEL_SITRONIX_ST7789V" = no; # Sitronix ST7789V panel
  "DRM_PANEL_SONY_ACX565AKM" = no; # Sony ACX565AKM panel
  "DRM_PANEL_SONY_TD4353_JDI" = no; # Sony TD4353 JDI panel
  "DRM_PANEL_SONY_TULIP_TRULY_NT35521" = no; # Sony Tulip Truly NT35521 panel
  "DRM_PANEL_STARTEK_KD070FHFID015" = module; # STARTEK KD070FHFID015 panel
  "DRM_PANEL_EDP" = yes; # support for simple Embedded DisplayPort panels
  "DRM_PANEL_SIMPLE" = module; # support for simple panels (other than eDP ones)
  "DRM_PANEL_SUMMIT" = no; # Apple Summit display panel
  "DRM_PANEL_SYNAPTICS_R63353" = no; # Synaptics R63353-based panels
  "DRM_PANEL_TDO_TL070WSH30" = no; # TDO TL070WSH30 DSI panel
  "DRM_PANEL_TPO_TD028TTEC1" = no; # Toppoly (TPO) TD028TTEC1 panel driver
  "DRM_PANEL_TPO_TD043MTEA1" = no; # Toppoly (TPO) TD043MTEA1 panel driver
  "DRM_PANEL_TPO_TPG110" = no; # TPO TPG 800x400 panel
  "DRM_PANEL_TRULY_NT35597_WQXGA" = module; # Truly WQXGA
  "DRM_PANEL_VISIONOX_G2647FB105" = no; # Visionox G2647FB105
  "DRM_PANEL_VISIONOX_R66451" = no; # Visionox R66451
  "DRM_PANEL_VISIONOX_RM69299" = no; # Visionox RM69299
  "DRM_PANEL_VISIONOX_RM692E5" = no; # Visionox RM692E5
  "DRM_PANEL_VISIONOX_RM69299_SHIFT" = yes; # Visionox RM69299 SHIFT6mq
  "DRM_PANEL_VISIONOX_VTDR6130" = module; # Visionox VTDR6130
  "DRM_PANEL_WIDECHIPS_WS2401" = no; # Widechips WS2401 DPI panel driver
  "DRM_PANEL_XINPENG_XPP055C272" = no; # Xinpeng XPP055C272 panel driver
  ##### end of Display Panels

  ##### Display Interface Bridges
  "DRM_CHIPONE_ICN6211" = no; # Chipone ICN6211 MIPI-DSI/RGB Converter bridge
  "DRM_CHRONTEL_CH7033" = no; # Chrontel CH7033 Video Encoder
  "DRM_CROS_EC_ANX7688" = no; # ChromeOS EC ANX7688 bridge
  "DRM_DISPLAY_CONNECTOR" = module; # Display connector support
  "DRM_I2C_NXP_TDA998X" = no; # NXP Semiconductors TDA998X HDMI encoder
  "DRM_ITE_IT6263" = module; # ITE IT6263 LVDS/HDMI bridge
  "DRM_ITE_IT6505" = no; # ITE IT6505 DisplayPort bridge
  "DRM_LONTIUM_LT8912B" = module; # Lontium LT8912B DSI/HDMI bridge
  "DRM_LONTIUM_LT9211" = no; # Lontium LT9211 DSI/LVDS/DPI bridge
  "DRM_LONTIUM_LT9611" = module; # Lontium LT9611 DSI/HDMI bridge
  "DRM_LONTIUM_LT9611UXC" = module; # Lontium LT9611UXC DSI/HDMI bridge
  "DRM_ITE_IT66121" = module; # ITE IT66121 HDMI bridge
  "DRM_LVDS_CODEC" = no; # Transparent LVDS encoders and decoders support
  "DRM_MEGACHIPS_STDPXXXX_GE_B850V3_FW" = no; # MegaChips stdp4028-ge-b850v3-fw and stdp2690-ge-b850v3-fw
  "DRM_NWL_MIPI_DSI" = no; # Northwest Logic MIPI DSI Host controller
  "DRM_NXP_PTN3460" = no; # NXP PTN3460 DP/LVDS bridge
  "DRM_PARADE_PS8622" = no; # Parade eDP/LVDS bridge
  "DRM_PARADE_PS8640" = no; # Parade PS8640 MIPI DSI to eDP Converter
  "DRM_SAMSUNG_DSIM" = module; # Samsung MIPI DSIM bridge driver
  "DRM_SIL_SII8620" = no; # Silicon Image SII8620 HDMI/MHL bridge
  "DRM_SII902X" = no; # Silicon Image sii902x RGB/HDMI bridge
  "DRM_SII9234" = no; # Silicon Image SII9234 HDMI/MHL bridge
  "DRM_SIMPLE_BRIDGE" = module; # Simple DRM bridge support
  "DRM_THINE_THC63LVD1024" = no; # Thine THC63LVD1024 LVDS decoder bridge
  "DRM_TOSHIBA_TC358762" = no; # TC358762 DSI/DPI bridge
  "DRM_TOSHIBA_TC358764" = no; # TC358764 DSI/LVDS bridge
  "DRM_TOSHIBA_TC358767" = module; # Toshiba TC358767 eDP bridge
  "DRM_TOSHIBA_TC358768" = module; # Toshiba TC358768 MIPI DSI bridge
  "DRM_TOSHIBA_TC358775" = no; # Toshiba TC358775 DSI/LVDS bridge
  "DRM_TI_DLPC3433" = no; # TI DLPC3433 Display controller
  "DRM_TI_TDP158" = no; # TI TDP158 HDMI/TMDS bridge
  "DRM_TI_TFP410" = module; # TI TFP410 DVI/HDMI bridge
  "DRM_TI_SN65DSI83" = module; # TI SN65DSI83 and SN65DSI84 DSI to LVDS bridge
  "DRM_TI_SN65DSI86" = yes; # TI SN65DSI86 DSI to eDP bridge
  "DRM_TI_TPD12S015" = no; # TI TPD12S015 HDMI level shifter and ESD protection
  "DRM_ANALOGIX_ANX6345" = no; # Analogix ANX6345 bridge
  "DRM_ANALOGIX_ANX78XX" = no; # Analogix ANX78XX bridge
  "DRM_ANALOGIX_ANX7625" = module; # Analogix Anx7625 MIPI to DP interface support
  "DRM_I2C_ADV7511" = module; # ADV7511 encoder
  "DRM_I2C_ADV7511_AUDIO" = yes; # ADV7511 HDMI Audio driver
  "DRM_I2C_ADV7511_CEC" = yes; # ADV7511/33/35 HDMI CEC driver
  "DRM_CDNS_DSI" = module; # Cadence DPI/DSI bridge
  "DRM_CDNS_DSI_J721E" = yes; # J721E Cadence DSI wrapper support
  "DRM_CDNS_MHDP8546" = module; # Cadence DPI/DP bridge
  ##### end of Display Interface Bridges

  "DRM_ETNAVIV" = no; # ETNAVIV (DRM support for Vivante GPU IP cores)
  "DRM_HISI_HIBMC" = no; # DRM Support for Hisilicon Hibmc
  "DRM_HISI_KIRIN" = no; # DRM Support for Hisilicon Kirin series SoCs Platform
  "DRM_LOGICVC" = no; # LogiCVC DRM
  "DRM_ARCPGU" = no; # ARC PGU
  "DRM_BOCHS" = no; # DRM Support for bochs dispi vga interface (qemu stdvga)
  "DRM_CIRRUS_QEMU" = no; # Cirrus driver for QEMU emulated device
  "DRM_GM12U320" = no; # GM12U320 driver for USB projectors
  "DRM_PANEL_MIPI_DBI" = no; # DRM support for MIPI DBI compatible panels
  "TINYDRM_HX8357D" = no; # DRM support for HX8357D display panels
  "TINYDRM_ILI9163" = no; # DRM support for ILI9163 display panels
  "TINYDRM_ILI9225" = no; # DRM support for ILI9225 display panels
  "TINYDRM_ILI9341" = no; # DRM support for ILI9341 display panels
  "TINYDRM_ILI9486" = no; # DRM support for ILI9486 display panels
  "TINYDRM_MI0283QT" = no; # DRM support for MI0283QT
  "TINYDRM_REPAPER" = no; # DRM support for Pervasive Displays RePaper panels (V231)
  "TINYDRM_SHARP_MEMORY" = no; # DRM support for Sharp Memory LCD panels
  "DRM_PL111" = no; # DRM Support for PL111 CLCD Controller
  "DRM_XEN_FRONTEND" = no; # Para-virtualized frontend driver for Xen guest OS
  "DRM_LIMA" = no; # LIMA (DRM support for ARM Mali 400/450 GPU)
  "DRM_PANFROST" = no; # Panfrost (DRM support for ARM Mali Midgard/Bifrost GPUs)
  "DRM_PANTHOR" = module; # Panthor (DRM support for ARM Mali CSF-based GPUs)
  "DRM_TIDSS" = module; # DRM Support for TI Keystone
  "DRM_GUD" = module; # GUD USB Display
  "DRM_ST7571_I2C" = no; # DRM support for Sitronix ST7571 display panels (I2C)
  "DRM_ST7586" = no; # DRM support for Sitronix ST7586 display panels
  "DRM_ST7735R" = no; # DRM support for Sitronix ST7715R/ST7735R display panels
  "DRM_SSD130X" = no; # DRM support for Solomon SSD13xx OLED displays
  "DRM_POWERVR" = module; # Imagination Technologies PowerVR (Series 6 and later) & IMG Graphics

  #### Device Drivers -> Graphics support -> Frame buffer Devices
  "FB" = yes; # Support for frame buffer device drivers
  "FB_CIRRUS" = no; # Cirrus Logic support
  "FB_PM2" = no; # Permedia2 support
  "FB_CYBER2000" = no; # CyberPro 2000/2010/5000 support
  "FB_ASILIANT" = no; # Asiliant (Chips) 69000 display support
  "FB_IMSTT" = no; # IMS Twin Turbo display support
  "FB_EFI" = no; # EFI-based Framebuffer Support
  "FB_OPENCORES" = no; # OpenCores VGA/LCD core 2.0 framebuffer support
  "FB_S1D13XXX" = no; # Epson S1D13XXX framebuffer support
  "FB_NVIDIA" = no; # nVidia Framebuffer Support
  "FB_RIVA" = no; # nVidia Riva support
  "FB_I740" = no; # Intel740 support
  "FB_MATROX" = no; # Matrox acceleration
  "FB_RADEON" = no; # ATI Radeon display support
  "FB_ATY128" = no; # ATI Rage128 display support
  "FB_ATY" = no; # ATI Mach64 display support
  "FB_S3" = no; # S3 Trio/Virge support
  "FB_SAVAGE" = no; # S3 Savage support
  "FB_SIS" = no; # SiS/XGI display support
  "FB_NEOMAGIC" = no; # NeoMagic display support
  "FB_KYRO" = no; # IMG Kyro support
  "FB_3DFX" = no; # 3Dfx Banshee/Voodoo3/Voodoo5 display support
  "FB_VOODOO1" = no; # 3Dfx Voodoo Graphics (sst1) support
  "FB_VT8623" = no; # VIA VT8623 support
  "FB_TRIDENT" = no; # Trident/CyberXXX/CyberBlade support
  "FB_ARK" = no; # ARK 2000PV support
  "FB_PM3" = no; # Permedia3 support
  "FB_CARMINE" = no; # Fujitsu carmine frame buffer support
  "FB_SMSCUFX" = no; # SMSC UFX6000/7000 USB Framebuffer support
  "FB_UDL" = no; # Displaylink USB Framebuffer support
  "FB_IBM_GXT4500" = no; # Framebuffer support for IBM GXT4000P/4500P/6000P/6500P adaptors
  "FB_VIRTUAL" = no; # Virtual Frame Buffer support (ONLY FOR TESTING!)
  "XEN_FBDEV_FRONTEND" = yes; # Xen virtual frame buffer support
  "FB_METRONOME" = no; # E-Ink Metronome/8track controller support
  "FB_MB862XX" = no; # Fujitsu MB862xx GDC support
  "FB_SIMPLE" = yes; # Simple framebuffer support
  "FB_SSD1307" = no; # Solomon SSD1307 framebuffer support
  "FB_SM712" = no; # Silicon Motion SM712 framebuffer support
  "FIRMWARE_EDID" = no; # Enable firmware EDID
  "FB_DEVICE" = yes; # Provide legacy /dev/fb* device
  "FB_FOREIGN_ENDIAN" = no; # Framebuffer foreign endianness support
  "FB_MODE_HELPERS" = yes; # Enable Video Mode Handling Helpers
  "FB_TILEBLITTING" = no; # Enable Tile Blitting Support
  #### Device Drivers -> Graphics support: end of Frame buffer Devices

  #### Device Drivers -> Graphics support -> Backlight & LCD device support
  "LCD_CLASS_DEVICE" = module; # Lowlevel LCD controls
  "LCD_L4F00242T03" = no; # Epson L4F00242T03 LCD
  "LCD_LMS283GF05" = no; # Samsung LMS283GF05 LCD
  "LCD_LTV350QV" = no; # Samsung LTV350QV LCD Panel
  "LCD_ILI922X" = no; # ILI Technology ILI9221/ILI9222 support
  "LCD_ILI9320" = no; # ILI Technology ILI9320 controller support
  "LCD_TDO24M" = no; # Toppoly TDO24M and TDO35S LCD Panels support
  "LCD_VGG2432A4" = no; # VGG2432A4 LCM device support
  "LCD_PLATFORM" = no; # Platform LCD controls
  "LCD_AMS369FG06" = no; # AMS369FG06 AMOLED LCD Driver
  "LCD_LMS501KF03" = no; # LMS501KF03 LCD Driver
  "LCD_HX8357" = no; # Himax HX-8357 LCD Driver
  "LCD_OTM3225A" = no; # ORISE Technology OTM3225A support
  "BACKLIGHT_CLASS_DEVICE" = yes; # Lowlevel Backlight controls
  "BACKLIGHT_KTD253" = no; # Backlight Driver for Kinetic KTD253
  "BACKLIGHT_KTD2801" = no; # Backlight Driver for Kinetic KTD2801
  "BACKLIGHT_KTZ8866" = no; # Backlight Driver for Kinetic KTZ8866
  "BACKLIGHT_PWM" = yes; # Generic PWM based Backlight Driver
  "BACKLIGHT_QCOM_WLED" = yes; # Qualcomm PMIC WLED Driver
  "BACKLIGHT_ADP8860" = no; # Backlight Driver for ADP8860/ADP8861/ADP8863 using WLED
  "BACKLIGHT_ADP8870" = no; # Backlight Driver for ADP8870 using WLED
  "BACKLIGHT_LM3509" = no; # Backlight Driver for LM3509
  "BACKLIGHT_LM3630A" = no; # Backlight Driver for LM3630A
  "BACKLIGHT_LM3639" = no; # Backlight Driver for LM3639
  "BACKLIGHT_LP855X" = no; # Backlight driver for TI LP855X
  "BACKLIGHT_MP3309C" = no; # Backlight Driver for MPS MP3309C
  "BACKLIGHT_GPIO" = no; # Generic GPIO based Backlight Driver
  "BACKLIGHT_LV5207LP" = no; # Sanyo LV5207LP Backlight
  "BACKLIGHT_BD6107" = no; # Rohm BD6107 Backlight
  "BACKLIGHT_ARCXCNN" = no; # Backlight driver for the Arctic Sands ARCxCnnnn family
  "BACKLIGHT_LED" = no; # Generic LED based Backlight Driver
  #### Device Drivers -> Graphics support: end of Backlight & LCD device support

  #### Device Drivers -> Graphics support -> Console display driver support
  "DUMMY_CONSOLE_COLUMNS" = freeform "80"; # Initial number of console screen columns
  "DUMMY_CONSOLE_ROWS" = freeform "25"; # Initial number of console screen rows
  "FRAMEBUFFER_CONSOLE" = yes; # Framebuffer Console support
  "FRAMEBUFFER_CONSOLE_LEGACY_ACCELERATION" = no; # Enable legacy fbcon hardware acceleration code
  "FRAMEBUFFER_CONSOLE_DETECT_PRIMARY" = yes; # Map the console to the primary display device
  "FRAMEBUFFER_CONSOLE_ROTATION" = no; # Framebuffer Console Rotation
  "FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER" = no; # Framebuffer Console Deferred Takeover
  #### Device Drivers -> Graphics support: end of Console display driver support

  "LOGO" = yes; # Bootup logo
  "LOGO_LINUX_MONO" = no; # Standard black and white Linux logo
  "LOGO_LINUX_VGA16" = no; # Standard 16-color Linux logo
  "LOGO_LINUX_CLUT224" = yes; # Standard 224-color Linux logo
  ### Device Drivers: end of Graphics support

  "DRM_ACCEL" = no; # Compute Acceleration Framework
  "SOUND" = yes; # Sound card support
  "SND" = yes; # Advanced Linux Sound Architecture
  "SND_OSSEMUL" = no; # Enable OSS Emulation
  "SND_HRTIMER" = no; # HR-timer backend support
  "SND_DYNAMIC_MINORS" = yes; # Dynamic device file minor numbers
  "SND_MAX_CARDS" = freeform "32"; # Max number of sound cards
  "SND_SUPPORT_OLD_API" = yes; # Support old ALSA API
  "SND_PROC_FS" = yes; # Sound Proc FS Support
  "SND_VERBOSE_PROCFS" = yes; # Verbose procfs contents
  "SND_DEBUG" = no; # Debug
  "SND_CTL_INPUT_VALIDATION" = no; # Validate input data to control API
  "SND_UTIMER" = no; # Enable support for userspace-controlled virtual timers
  "SND_SEQUENCER" = no; # Sequencer support
  "SND_DRIVERS" = yes; # Generic sound devices
  "SND_DUMMY" = no; # Dummy (/dev/null) soundcard
  "SND_ALOOP" = module; # Generic loopback driver (PCM)
  "SND_PCMTEST" = no; # Virtual PCM test driver
  "SND_MTPAV" = no; # MOTU MidiTimePiece AV multiport MIDI
  "SND_SERIAL_U16550" = no; # UART16550 serial MIDI driver
  "SND_SERIAL_GENERIC" = no; # Generic serial MIDI driver
  "SND_MPU401" = no; # Generic MPU-401 UART driver
  "SND_PCI" = yes; # PCI sound devices
  "SND_AD1889" = no; # Analog Devices AD1889
  "SND_ALS300" = no; # Avance Logic ALS300/ALS300+
  "SND_ALI5451" = no; # ALi M5451 PCI Audio Controller
  "SND_ATIIXP" = no; # ATI IXP AC97 Controller
  "SND_ATIIXP_MODEM" = no; # ATI IXP Modem
  "SND_AU8810" = no; # Aureal Advantage
  "SND_AU8820" = no; # Aureal Vortex
  "SND_AU8830" = no; # Aureal Vortex 2
  "SND_AW2" = no; # Emagic Audiowerk 2
  "SND_AZT3328" = no; # Aztech AZF3328 / PCI168
  "SND_BT87X" = no; # Bt87x Audio Capture
  "SND_CA0106" = no; # SB Audigy LS / Live 24bit
  "SND_CMIPCI" = no; # C-Media 8338, 8738, 8768, 8770
  "SND_OXYGEN" = no; # C-Media 8786, 8787, 8788 (Oxygen)
  "SND_CS4281" = no; # Cirrus Logic (Sound Fusion) CS4281
  "SND_CS46XX" = no; # Cirrus Logic (Sound Fusion) CS4280/CS461x/CS462x/CS463x
  "SND_CTXFI" = no; # Creative Sound Blaster X-Fi
  "SND_DARLA20" = no; # (Echoaudio) Darla20
  "SND_GINA20" = no; # (Echoaudio) Gina20
  "SND_LAYLA20" = no; # (Echoaudio) Layla20
  "SND_DARLA24" = no; # (Echoaudio) Darla24
  "SND_GINA24" = no; # (Echoaudio) Gina24
  "SND_LAYLA24" = no; # (Echoaudio) Layla24
  "SND_MONA" = no; # (Echoaudio) Mona
  "SND_MIA" = no; # (Echoaudio) Mia
  "SND_ECHO3G" = no; # (Echoaudio) 3G cards
  "SND_INDIGO" = no; # (Echoaudio) Indigo
  "SND_INDIGOIO" = no; # (Echoaudio) Indigo IO
  "SND_INDIGODJ" = no; # (Echoaudio) Indigo DJ
  "SND_INDIGOIOX" = no; # (Echoaudio) Indigo IOx
  "SND_INDIGODJX" = no; # (Echoaudio) Indigo DJx
  "SND_EMU10K1" = no; # Emu10k1 (SB Live!, Audigy, E-MU APS/0404/1010/1212/1616/1820)
  "SND_EMU10K1X" = no; # Emu10k1X (Dell OEM Version)
  "SND_ENS1370" = no; # (Creative) Ensoniq AudioPCI 1370
  "SND_ENS1371" = no; # (Creative) Ensoniq AudioPCI 1371/1373
  "SND_ES1938" = no; # ESS ES1938/1946/1969 (Solo-1)
  "SND_ES1968" = no; # ESS ES1968/1978 (Maestro-1/2/2E)
  "SND_FM801" = no; # ForteMedia FM801
  "SND_HDSP" = no; # RME Hammerfall DSP Audio
  "SND_HDSPM" = no; # RME Hammerfall DSP MADI/RayDAT/AIO
  "SND_ICE1712" = no; # ICEnsemble ICE1712 (Envy24)
  "SND_ICE1724" = no; # ICE/VT1724/1720 (Envy24HT/PT)
  "SND_INTEL8X0" = no; # Intel/SiS/nVidia/AMD/ALi AC97 Controller
  "SND_INTEL8X0M" = no; # Intel/SiS/nVidia/AMD MC97 Modem
  "SND_KORG1212" = no; # Korg 1212 IO
  "SND_LOLA" = no; # Digigram Lola
  "SND_LX6464ES" = no; # Digigram LX6464ES
  "SND_MAESTRO3" = no; # ESS Allegro/Maestro3
  "SND_MIXART" = no; # Digigram miXart
  "SND_NM256" = no; # NeoMagic NM256AV/ZX
  "SND_PCXHR" = no; # Digigram PCXHR
  "SND_RIPTIDE" = no; # Conexant Riptide
  "SND_RME32" = no; # RME Digi32, 32/8, 32 PRO
  "SND_RME96" = no; # RME Digi96, 96/8, 96/8 PRO
  "SND_RME9652" = no; # RME Digi9652 (Hammerfall)
  "SND_SE6X" = no; # Studio Evolution SE6X
  "SND_SONICVIBES" = no; # S3 SonicVibes
  "SND_TRIDENT" = no; # Trident 4D-Wave DX/NX; SiS 7018
  "SND_VIA82XX" = no; # VIA 82C686A/B, 8233/8235 AC97 Controller
  "SND_VIA82XX_MODEM" = no; # VIA 82C686A/B, 8233 based Modems
  "SND_VIRTUOSO" = no; # Asus Virtuoso 66/100/200 (Xonar)
  "SND_VX222" = no; # Digigram VX222
  "SND_YMFPCI" = no; # Yamaha YMF724/740/744/754

  ##### HD-Audio
  "SND_HDA_INTEL" = no; # HD Audio PCI
  "SND_HDA_ACPI" = no; # HD Audio ACPI
  ##### end of HD-Audio

  "SND_HDA_PREALLOC_SIZE" = freeform "64"; # Pre-allocated buffer size for HD-audio driver
  "SND_SPI" = yes; # SPI sound devices
  "SND_USB" = yes; # USB sound devices
  "SND_USB_AUDIO" = module; # USB Audio/MIDI driver
  "SND_USB_AUDIO_MIDI_V2" = no; # MIDI 2.0 support by USB Audio driver
  "SND_USB_UA101" = no; # Edirol UA-101/UA-1000 driver
  "SND_USB_CAIAQ" = no; # Native Instruments USB audio devices
  "SND_USB_6FIRE" = no; # TerraTec DMX 6Fire USB
  "SND_USB_HIFACE" = no; # M2Tech hiFace USB-SPDIF driver
  "SND_BCD2000" = no; # Behringer BCD2000 MIDI driver
  "SND_USB_POD" = no; # Line 6 POD USB support
  "SND_USB_PODHD" = no; # Line 6 POD X3/HD300/400/500 USB support
  "SND_USB_TONEPORT" = no; # TonePort GX, UX1 and UX2 USB support
  "SND_USB_VARIAX" = no; # Variax Workbench USB support
  "SND_SOC" = yes; # ALSA for SoC audio support
  "SND_SOC_USB" = no; # SoC based USB audio offloading
  "SND_SOC_ADI" = no; # Audio support for Analog Devices reference designs
  "SND_SOC_AMD_ACP" = no; # AMD Audio Coprocessor support
  "SND_AMD_ACP_CONFIG" = no; # AMD ACP configuration selection
  "SND_ATMEL_SOC" = no; # SoC Audio for the Atmel System-on-Chip
  "SND_BCM63XX_I2S_WHISTLER" = no; # SoC Audio support for the Broadcom BCM63XX I2S module
  "SND_DESIGNWARE_I2S" = no; # Synopsys I2S Device Driver

  ###### SoC Audio for Freescale CPUs
  "SND_SOC_FSL_ASRC" = no; # Asynchronous Sample Rate Converter (ASRC) module support
  "SND_SOC_FSL_SAI" = no; # Synchronous Audio Interface (SAI) module support
  "SND_SOC_FSL_AUDMIX" = no; # Audio Mixer (AUDMIX) module support
  "SND_SOC_FSL_SSI" = module; # Synchronous Serial Interface module (SSI) support
  "SND_SOC_FSL_SPDIF" = no; # Sony/Philips Digital Interface (S/PDIF) module support
  "SND_SOC_FSL_ESAI" = module; # Enhanced Serial Audio Interface (ESAI) module support
  "SND_SOC_FSL_MICFIL" = no; # Pulse Density Modulation Microphone Interface (MICFIL) module support
  "SND_SOC_FSL_XCVR" = no; # NXP Audio Transceiver (XCVR) module support
  "SND_SOC_FSL_RPMSG" = no; # NXP Audio Base On RPMSG support
  "SND_SOC_IMX_AUDMUX" = module; # Digital Audio Mux module support
  ###### end of SoC Audio for Freescale CPUs

  "SND_SOC_CHV3_I2S" = no; # Google Chameleon v3 I2S device
  "SND_I2S_HI6210_I2S" = no; # Hisilicon I2S controller
  "SND_SOC_IMG" = no; # Audio support for Imagination Technologies designs
  "SND_SOC_MTK_BTCVSD" = no; # ALSA BT SCO CVSD/MSBC Driver
  "SND_SOC_QCOM" = module; # ASoC support for QCOM platforms
  "SND_SOC_STORM" = no; # ASoC I2S support for Storm boards
  "SND_SOC_APQ8016_SBC" = module; # SoC Audio support for APQ8016 SBC platforms
  "SND_SOC_QDSP6" = module; # SoC ALSA audio driver for QDSP6
  "SND_SOC_QDSP6_Q6VOICE" = module; # QDSP6 Q6Voice audio driver
  "SND_SOC_MSM8996" = module; # SoC Machine driver for MSM8996 and APQ8096 boards
  "SND_SOC_SDM845" = module; # SoC Machine driver for SDM845 boards
  "SND_SOC_SM8250" = module; # SoC Machine driver for SM8250 boards
  "SND_SOC_SC8280XP" = module; # SoC Machine driver for SC8280XP boards
  "SND_SOC_SC7180" = no; # SoC Machine driver for SC7180 boards
  "SND_SOC_SC7280" = no; # SoC Machine driver for SC7280 boards
  "SND_SOC_X1E80100" = module; # SoC Machine driver for X1E80100 boards
  "SND_SOC_SOF_TOPLEVEL" = yes; # Sound Open Firmware Support
  "SND_SOC_SOF_PCI" = no; # SOF PCI enumeration support
  "SND_SOC_SOF_ACPI" = no; # SOF ACPI enumeration support
  "SND_SOC_SOF_OF" = yes; # SOF OF enumeration support
  "SND_SOC_SOF_IMX_TOPLEVEL" = no; # SOF support for NXP i.MX audio DSPs
  "SND_SOC_SOF_MTK_TOPLEVEL" = yes; # SOF support for MTK audio DSPs

  ###### STMicroelectronics STM32 SOC audio support
  "SND_SOC_STM32_SAI" = no; # STM32 SAI interface (Serial Audio Interface) support
  "SND_SOC_STM32_I2S" = no; # STM32 I2S interface (SPI/I2S block) support
  "SND_SOC_STM32_SPDIFRX" = no; # STM32 S/PDIF receiver (SPDIFRX) support
  ###### end of STMicroelectronics STM32 SOC audio support

  "SND_SOC_XILINX_I2S" = no; # Audio support for the Xilinx I2S
  "SND_SOC_XILINX_AUDIO_FORMATTER" = no; # Audio support for the Xilinx audio formatter
  "SND_SOC_XILINX_SPDIF" = no; # Audio support for the Xilinx SPDIF
  "SND_SOC_XTFPGA_I2S" = no; # XTFPGA I2S master

  ###### CODEC drivers
  "SND_SOC_AC97_CODEC" = no; # Build generic ASoC AC97 CODEC driver
  "SND_SOC_ADAU1372_I2C" = no; # Analog Devices ADAU1372 CODEC (I2C)
  "SND_SOC_ADAU1372_SPI" = no; # Analog Devices ADAU1372 CODEC (SPI)
  "SND_SOC_ADAU1373" = no; # Analog Devices ADAU1373 CODEC
  "SND_SOC_ADAU1701" = no; # Analog Devices ADAU1701 CODEC
  "SND_SOC_ADAU1761_I2C" = no; # Analog Devices AU1761 CODEC - I2C
  "SND_SOC_ADAU1761_SPI" = no; # Analog Devices AU1761 CODEC - SPI
  "SND_SOC_ADAU7002" = no; # Analog Devices ADAU7002 Stereo PDM-to-I2S/TDM Converter
  "SND_SOC_ADAU7118_HW" = no; # Analog Devices ADAU7118 8 Channel PDM-to-I2S/TDM Converter - HW Mode
  "SND_SOC_ADAU7118_I2C" = no; # Analog Devices ADAU7118 8 Channel PDM-to-I2S/TDM Converter - I2C
  "SND_SOC_AK4104" = no; # AKM AK4104 CODEC
  "SND_SOC_AK4118" = no; # AKM AK4118 CODEC
  "SND_SOC_AK4375" = no; # AKM AK4375 CODEC
  "SND_SOC_AK4458" = no; # AKM AK4458 CODEC
  "SND_SOC_AK4554" = no; # AKM AK4554 CODEC
  "SND_SOC_AK4613" = no; # AKM AK4613 CODEC
  "SND_SOC_AK4619" = module; # AKM AK4619 CODEC
  "SND_SOC_AK4642" = no; # AKM AK4642 CODEC
  "SND_SOC_AK5386" = no; # AKM AK5638 CODEC
  "SND_SOC_AK5558" = no; # AKM AK5558 CODEC
  "SND_SOC_ALC5623" = no; # Realtek ALC5623 CODEC
  "SND_SOC_AUDIO_IIO_AUX" = no; # Audio IIO Auxiliary device
  "SND_SOC_AW8738" = no; # Awinic AW8738 Audio Amplifier
  "SND_SOC_AW88395" = no; # Soc Audio for awinic aw88395
  "SND_SOC_AW88166" = no; # Soc Audio for awinic aw88166
  "SND_SOC_AW88261" = no; # Soc Audio for awinic aw88261
  "SND_SOC_AW88081" = no; # Soc Audio for awinic aw88081/aw88083
  "SND_SOC_AW87390" = no; # Soc Audio for awinic aw87390
  "SND_SOC_AW88399" = no; # Soc Audio for awinic aw88399
  "SND_SOC_BD28623" = no; # ROHM BD28623 CODEC
  "SND_SOC_BT_SCO" = module; # Dummy BT SCO codec driver
  "SND_SOC_CHV3_CODEC" = no; # Google Chameleon v3 codec driver
  "SND_SOC_CROS_EC_CODEC" = module; # codec driver for ChromeOS EC
  "SND_SOC_CS35L32" = no; # Cirrus Logic CS35L32 CODEC
  "SND_SOC_CS35L33" = no; # Cirrus Logic CS35L33 CODEC
  "SND_SOC_CS35L34" = no; # Cirrus Logic CS35L34 CODEC
  "SND_SOC_CS35L35" = no; # Cirrus Logic CS35L35 CODEC
  "SND_SOC_CS35L36" = module; # Cirrus Logic CS35L36 CODEC
  "SND_SOC_CS35L41_SPI" = no; # Cirrus Logic CS35L41 CODEC (SPI)
  "SND_SOC_CS35L41_I2C" = no; # Cirrus Logic CS35L41 CODEC (I2C)
  "SND_SOC_CS35L45_SPI" = no; # Cirrus Logic CS35L45 CODEC (SPI)
  "SND_SOC_CS35L45_I2C" = no; # Cirrus Logic CS35L45 CODEC (I2C)
  "SND_SOC_CS35L56_I2C" = no; # Cirrus Logic CS35L56 CODEC (I2C)
  "SND_SOC_CS35L56_SPI" = no; # Cirrus Logic CS35L56 CODEC (SPI)
  "SND_SOC_CS35L56_SDW" = no; # Cirrus Logic CS35L56 CODEC (SDW)
  "SND_SOC_CS42L42" = no; # Cirrus Logic CS42L42 CODEC (I2C)
  "SND_SOC_CS42L42_SDW" = no; # Cirrus Logic CS42L42 CODEC on Soundwire
  "SND_SOC_CS42L51_I2C" = no; # Cirrus Logic CS42L51 CODEC (I2C)
  "SND_SOC_CS42L52" = no; # Cirrus Logic CS42L52 CODEC
  "SND_SOC_CS42L56" = no; # Cirrus Logic CS42L56 CODEC
  "SND_SOC_CS42L73" = no; # Cirrus Logic CS42L73 CODEC
  "SND_SOC_CS42L83" = no; # Cirrus Logic CS42L83 CODEC
  "SND_SOC_CS42L84" = no; # Cirrus Logic CS42L84 CODEC
  "SND_SOC_CS4234" = no; # Cirrus Logic CS4234 CODEC
  "SND_SOC_CS4265" = no; # Cirrus Logic CS4265 CODEC
  "SND_SOC_CS4270" = no; # Cirrus Logic CS4270 CODEC
  "SND_SOC_CS4271_I2C" = no; # Cirrus Logic CS4271 CODEC (I2C)
  "SND_SOC_CS4271_SPI" = no; # Cirrus Logic CS4271 CODEC (SPI)
  "SND_SOC_CS42XX8_I2C" = no; # Cirrus Logic CS42448/CS42888 CODEC (I2C)
  "SND_SOC_CS43130" = no; # Cirrus Logic CS43130 CODEC
  "SND_SOC_CS4341" = no; # Cirrus Logic CS4341 CODEC
  "SND_SOC_CS4349" = no; # Cirrus Logic CS4349 CODEC
  "SND_SOC_CS48L32" = no; # Cirrus Logic CS48L32 audio DSP
  "SND_SOC_CS53L30" = no; # Cirrus Logic CS53L30 CODEC
  "SND_SOC_CS530X_I2C" = no; # Cirrus Logic CS530x ADCs (I2C)
  "SND_SOC_CX2072X" = no; # Conexant CX2072X CODEC
  "SND_SOC_DA7213" = module; # Dialog DA7213 CODEC
  "SND_SOC_DMIC" = module; # Generic Digital Microphone CODEC
  "SND_SOC_ES7134" = no; # Everest Semi ES7134 CODEC
  "SND_SOC_ES7241" = no; # Everest Semi ES7241 CODEC
  "SND_SOC_ES8311" = no; # Everest Semi ES8311 CODEC
  "SND_SOC_ES8316" = module; # Everest Semi ES8316 CODEC
  "SND_SOC_ES8323" = no; # Everest Semi ES8323 CODEC
  "SND_SOC_ES8326" = module; # Everest Semi ES8326 CODEC
  "SND_SOC_ES8328_I2C" = module; # Everest Semi ES8328 CODEC (I2C)
  "SND_SOC_ES8328_SPI" = no; # Everest Semi ES8328 CODEC (SPI)
  "SND_SOC_ES8375" = no; # Everest Semi ES8375 CODEC
  "SND_SOC_ES8389" = no; # Everest Semi ES8389 CODEC
  "SND_SOC_GTM601" = no; # GTM601 UMTS modem audio codec
  "SND_SOC_HDA" = no; # HD-Audio codec driver
  "SND_SOC_ICS43432" = no; # ICS43423 and compatible i2s microphones
  "SND_SOC_IDT821034" = no; # Renesas IDT821034 quad PCM codec
  "SND_SOC_MAX98088" = no; # Maxim MAX98088/9 Low-Power, Stereo Audio Codec
  "SND_SOC_MAX98090" = no; # Maxim MAX98090 CODEC
  "SND_SOC_MAX98357A" = no; # Maxim MAX98357A CODEC
  "SND_SOC_MAX98504" = no; # Maxim MAX98504 speaker amplifier
  "SND_SOC_MAX9867" = no; # Maxim MAX9867 CODEC
  "SND_SOC_MAX98927" = module; # Maxim Integrated MAX98927 Speaker Amplifier
  "SND_SOC_MAX98520" = no; # Maxim Integrated MAX98520 Speaker Amplifier
  "SND_SOC_MAX98363" = no; # Analog Devices MAX98363 Soundwire Speaker Amplifier
  "SND_SOC_MAX98373_I2C" = no; # Maxim Integrated MAX98373 Speaker Amplifier
  "SND_SOC_MAX98373_SDW" = no; # Maxim Integrated MAX98373 Speaker Amplifier - SDW
  "SND_SOC_MAX98388" = no; # Analog Devices MAX98388 Speaker Amplifier
  "SND_SOC_MAX98390" = module; # Maxim Integrated MAX98390 Speaker Amplifier
  "SND_SOC_MAX98396" = no; # Analog Devices MAX98396 Speaker Amplifier
  "SND_SOC_MAX98512" = yes; # Analog Devices MAX98512 Speaker Amplifier
  "SND_SOC_MAX9860" = no; # Maxim MAX9860 Mono Audio Voice Codec
  "SND_SOC_MSM8916_WCD_ANALOG" = module; # Qualcomm MSM8916 WCD Analog Codec
  "SND_SOC_MSM8916_WCD_DIGITAL" = module; # Qualcomm MSM8916 WCD DIGITAL Codec
  "SND_SOC_PCM1681" = no; # Texas Instruments PCM1681 CODEC
  "SND_SOC_PCM1789_I2C" = no; # Texas Instruments PCM1789 CODEC (I2C)
  "SND_SOC_PCM179X_I2C" = no; # Texas Instruments PCM179X CODEC (I2C)
  "SND_SOC_PCM179X_SPI" = no; # Texas Instruments PCM179X CODEC (SPI)
  "SND_SOC_PCM186X_I2C" = no; # Texas Instruments PCM186x CODECs - I2C
  "SND_SOC_PCM186X_SPI" = no; # Texas Instruments PCM186x CODECs - SPI
  "SND_SOC_PCM3060_I2C" = no; # Texas Instruments PCM3060 CODEC - I2C
  "SND_SOC_PCM3060_SPI" = no; # Texas Instruments PCM3060 CODEC - SPI
  "SND_SOC_PCM3168A_I2C" = no; # Texas Instruments PCM3168A CODEC - I2C
  "SND_SOC_PCM3168A_SPI" = no; # Texas Instruments PCM3168A CODEC - SPI
  "SND_SOC_PCM5102A" = no; # Texas Instruments PCM5102A CODEC
  "SND_SOC_PCM512x_I2C" = no; # Texas Instruments PCM512x CODECs - I2C
  "SND_SOC_PCM512x_SPI" = no; # Texas Instruments PCM512x CODECs - SPI
  "SND_SOC_PCM6240" = no; # Texas Instruments PCM6240 Family Audio chips based on I2C
  "SND_SOC_PEB2466" = no; # Infineon PEB2466 quad PCM codec
  "SND_SOC_RK817" = module; # Rockchip RK817 audio CODEC
  "SND_SOC_RT1017_SDCA_SDW" = no; # Realtek RT1017 SDCA Codec - SDW
  "SND_SOC_RT1308_SDW" = no; # Realtek RT1308 Codec - SDW
  "SND_SOC_RT1316_SDW" = no; # Realtek RT1316 Codec - SDW
  "SND_SOC_RT1318_SDW" = no; # Realtek RT1318 Codec - SDW
  "SND_SOC_RT1320_SDW" = no; # Realtek RT1320 Codec - SDW
  "SND_SOC_RT5616" = no; # Realtek RT5616 CODEC
  "SND_SOC_RT5631" = no; # Realtek ALC5631/RT5631 CODEC
  "SND_SOC_RT5640" = module; # Realtek RT5640/RT5639 Codec
  "SND_SOC_RT5659" = no; # Realtek RT5658/RT5659 Codec
  "SND_SOC_RT5682_SDW" = no; # Realtek RT5682 Codec - SDW
  "SND_SOC_RT700_SDW" = no; # Realtek RT700 Codec - SDW
  "SND_SOC_RT711_SDW" = no; # Realtek RT711 Codec - SDW
  "SND_SOC_RT711_SDCA_SDW" = no; # Realtek RT711 SDCA Codec - SDW
  "SND_SOC_RT712_SDCA_SDW" = no; # Realtek RT712 SDCA Codec - SDW
  "SND_SOC_RT712_SDCA_DMIC_SDW" = no; # Realtek RT712 SDCA DMIC Codec - SDW
  "SND_SOC_RT721_SDCA_SDW" = no; # Realtek RT721 SDCA Codec - SDW
  "SND_SOC_RT722_SDCA_SDW" = no; # Realtek RT722 SDCA Codec - SDW
  "SND_SOC_RT715_SDW" = no; # Realtek RT715 Codec - SDW
  "SND_SOC_RT715_SDCA_SDW" = no; # Realtek RT715 SDCA Codec - SDW
  "SND_SOC_RT9120" = no; # Richtek RT9120 Stereo Class-D Amplifier
  "SND_SOC_RT9123" = no; # Richtek RT9123 Mono Class-D Amplifier
  "SND_SOC_RT9123P" = no; # Richtek RT9123P Mono Class-D Amplifier
  "SND_SOC_RTQ9128" = no; # Richtek RTQ9128 45W Digital Input Amplifier
  "SND_SOC_SGTL5000" = module; # Freescale SGTL5000 CODEC
  "SND_SOC_SIMPLE_AMPLIFIER" = no; # Simple Audio Amplifier
  "SND_SOC_SIMPLE_MUX" = module; # Simple Audio Mux
  "SND_SOC_SMA1303" = no; # Iron Device SMA1303 Audio Amplifier
  "SND_SOC_SMA1307" = no; # Iron Device SMA1307 Audio Amplifier
  "SND_SOC_SPDIF" = module; # S/PDIF CODEC
  "SND_SOC_SRC4XXX_I2C" = no; # Texas Instruments SRC4XXX DIR/DIT and SRC codecs
  "SND_SOC_SSM2305" = no; # Analog Devices SSM2305 Class-D Amplifier
  "SND_SOC_SSM2518" = no; # Analog Devices SSM2518 Class-D Amplifier
  "SND_SOC_SSM2602_SPI" = no; # Analog Devices SSM2602 CODEC - SPI
  "SND_SOC_SSM2602_I2C" = no; # Analog Devices SSM2602 CODEC - I2C
  "SND_SOC_SSM3515" = no; # Analog Devices SSM3515 amplifier driver
  "SND_SOC_SSM4567" = no; # Analog Devices ssm4567 amplifier driver support
  "SND_SOC_STA32X" = no; # STA326, STA328 and STA329 speaker amplifier
  "SND_SOC_STA350" = no; # STA350 speaker amplifier
  "SND_SOC_STI_SAS" = no; # codec Audio support for STI SAS codec
  "SND_SOC_TAS2552" = module; # Texas Instruments TAS2552 Mono Audio amplifier
  "SND_SOC_TAS2562" = no; # Texas Instruments TAS2562 Mono Audio amplifier
  "SND_SOC_TAS2764" = no; # Texas Instruments TAS2764 Mono Audio amplifier
  "SND_SOC_TAS2770" = no; # Texas Instruments TAS2770 speaker amplifier
  "SND_SOC_TAS2780" = no; # Texas Instruments TAS2780 Mono Audio amplifier
  "SND_SOC_TAS2781_I2C" = no; # Texas Instruments TAS2781 speaker amplifier based on I2C
  "SND_SOC_TAS5086" = no; # Texas Instruments TAS5086 speaker amplifier
  "SND_SOC_TAS571X" = no; # Texas Instruments TAS571x power amplifiers
  "SND_SOC_TAS5720" = no; # Texas Instruments TAS5720 Mono Audio amplifier
  "SND_SOC_TAS5805M" = no; # Texas Instruments TAS5805M speaker amplifier
  "SND_SOC_TAS6424" = no; # Texas Instruments TAS6424 Quad-Channel Audio amplifier
  "SND_SOC_TDA7419" = no; # ST TDA7419 audio processor
  "SND_SOC_TFA98XX" = module; # NXP/Goodix TFA98XX
  "SND_SOC_TFA9879" = no; # NXP Semiconductors TFA9879 amplifier
  "SND_SOC_TFA989X" = module; # NXP/Goodix TFA989X (TFA1) amplifiers
  "SND_SOC_TLV320ADC3XXX" = no; # Texas Instruments TLV320ADC3001/3101 audio ADC
  "SND_SOC_TLV320AIC23_I2C" = no; # Texas Instruments TLV320AIC23 audio CODEC - I2C
  "SND_SOC_TLV320AIC23_SPI" = no; # Texas Instruments TLV320AIC23 audio CODEC - SPI
  "SND_SOC_TLV320AIC31XX" = module; # Texas Instruments TLV320AIC31xx CODECs
  "SND_SOC_TLV320AIC32X4_I2C" = module; # Texas Instruments TLV320AIC32x4 audio CODECs - I2C
  "SND_SOC_TLV320AIC32X4_SPI" = no; # Texas Instruments TLV320AIC32x4 audio CODECs - SPI
  "SND_SOC_TLV320AIC3X_I2C" = module; # Texas Instruments TLV320AIC3x audio CODECs - I2C
  "SND_SOC_TLV320AIC3X_SPI" = no; # Texas Instruments TLV320AIC3x audio CODECs - SPI
  "SND_SOC_TLV320ADCX140" = no; # Texas Instruments TLV320ADCX140 CODEC family
  "SND_SOC_TS3A227E" = module; # TI Headset/Mic detect and keypress chip
  "SND_SOC_TSCS42XX" = no; # Tempo Semiconductor TSCS42xx CODEC
  "SND_SOC_TSCS454" = no; # Tempo Semiconductor TSCS454 CODEC
  "SND_SOC_UDA1334" = no; # NXP UDA1334 DAC
  "SND_SOC_UDA1342" = no; # NXP UDA1342 CODEC
  "SND_SOC_WCD9335" = module; # WCD9335 Codec
  "SND_SOC_WCD934X" = module; # WCD9340/WCD9341 Codec
  "SND_SOC_WCD937X_SDW" = no; # WCD9370/WCD9375 Codec - SDW
  "SND_SOC_WCD938X_SDW" = no; # WCD9380/WCD9385 Codec - SDW
  "SND_SOC_WCD939X_SDW" = module; # WCD9390/WCD9395 Codec - SDW
  "SND_SOC_WM8510" = no; # Wolfson Microelectronics WM8510 CODEC
  "SND_SOC_WM8523" = no; # Wolfson Microelectronics WM8523 DAC
  "SND_SOC_WM8524" = module; # Wolfson Microelectronics WM8524 DAC
  "SND_SOC_WM8580" = no; # Wolfson Microelectronics WM8580 and WM8581 CODECs
  "SND_SOC_WM8711" = no; # Wolfson Microelectronics WM8711 CODEC
  "SND_SOC_WM8728" = no; # Wolfson Microelectronics WM8728 DAC
  "SND_SOC_WM8731_I2C" = no; # Wolfson Microelectronics WM8731 CODEC with I2C
  "SND_SOC_WM8731_SPI" = no; # Wolfson Microelectronics WM8731 CODEC with SPI
  "SND_SOC_WM8737" = no; # Wolfson Microelectronics WM8737 ADC
  "SND_SOC_WM8741" = no; # Wolfson Microelectronics WM8741 DAC
  "SND_SOC_WM8750" = no; # Wolfson Microelectronics WM8750 CODEC
  "SND_SOC_WM8753" = no; # Wolfson Microelectronics WM8753 CODEC
  "SND_SOC_WM8770" = no; # Wolfson Microelectronics WM8770 CODEC
  "SND_SOC_WM8776" = no; # Wolfson Microelectronics WM8776 CODEC
  "SND_SOC_WM8782" = no; # Wolfson Microelectronics WM8782 ADC
  "SND_SOC_WM8804_I2C" = no; # Wolfson Microelectronics WM8804 S/PDIF transceiver I2C
  "SND_SOC_WM8804_SPI" = no; # Wolfson Microelectronics WM8804 S/PDIF transceiver SPI
  "SND_SOC_WM8903" = no; # Wolfson Microelectronics WM8903 CODEC
  "SND_SOC_WM8904" = no; # Wolfson Microelectronics WM8904 CODEC
  "SND_SOC_WM8940" = no; # Wolfson Microelectronics WM8940 codec
  "SND_SOC_WM8960" = no; # Wolfson Microelectronics WM8960 CODEC
  "SND_SOC_WM8961" = no; # Wolfson Microelectronics WM8961 CODEC
  "SND_SOC_WM8962" = no; # Wolfson Microelectronics WM8962 CODEC
  "SND_SOC_WM8974" = no; # Wolfson Microelectronics WM8974 codec
  "SND_SOC_WM8978" = module; # Wolfson Microelectronics WM8978 codec
  "SND_SOC_WM8985" = no; # Wolfson Microelectronics WM8985 and WM8758 codec driver
  "SND_SOC_WSA881X" = module; # WSA881X Codec
  "SND_SOC_WSA883X" = module; # WSA883X Codec
  "SND_SOC_WSA884X" = module; # WSA884X Codec
  "SND_SOC_ZL38060" = no; # Microsemi ZL38060 Connected Home Audio Processor
  "SND_SOC_MAX9759" = no; # Maxim MAX9759 speaker Amplifier
  "SND_SOC_MT6351" = no; # MediaTek MT6351 Codec
  "SND_SOC_MT6357" = module; # MediaTek MT6357 Codec
  "SND_SOC_MT6358" = module; # MediaTek MT6358 Codec
  "SND_SOC_MT6660" = no; # Mediatek MT6660 Speaker Amplifier
  "SND_SOC_NAU8315" = module; # Nuvoton Technology Corporation NAU8315 CODEC
  "SND_SOC_NAU8540" = no; # Nuvoton Technology Corporation NAU85L40 CODEC
  "SND_SOC_NAU8810" = no; # Nuvoton Technology Corporation NAU88C10 CODEC
  "SND_SOC_NAU8821" = no; # Nuvoton Technology Corporation NAU88L21 CODEC
  "SND_SOC_NAU8822" = module; # Nuvoton Technology Corporation NAU88C22 CODEC
  "SND_SOC_NAU8824" = no; # Nuvoton Technology Corporation NAU88L24 CODEC
  "SND_SOC_NTP8918" = no; # NeoFidelity NTP8918 amplifier
  "SND_SOC_NTP8835" = no; # NeoFidelity NTP8835 and NTP8835C amplifiers
  "SND_SOC_TPA6130A2" = no; # Texas Instruments TPA6130A2 headphone amplifier
  "SND_SOC_LPASS_WSA_MACRO" = module; # Qualcomm WSA Macro in LPASS(Low Power Audio SubSystem)
  "SND_SOC_LPASS_VA_MACRO" = module; # Qualcomm VA Macro in LPASS(Low Power Audio SubSystem)
  "SND_SOC_TAS2557" = no; # Texas Instruments TAS2557 speaker amplifier
  "SND_SOC_TAS2559" = module; # Texas Instruments TAS2559 speaker amplifier
  "SND_SOC_LPASS_RX_MACRO" = module; # Qualcomm RX Macro in LPASS(Low Power Audio SubSystem)
  "SND_SOC_LPASS_TX_MACRO" = module; # Qualcomm TX Macro in LPASS(Low Power Audio SubSystem)
  ###### end of CODEC drivers

  "SND_SIMPLE_CARD" = no; # ASoC Simple sound card support
  "SND_AUDIO_GRAPH_CARD" = no; # ASoC Audio Graph sound card support
  "SND_AUDIO_GRAPH_CARD2" = module; # ASoC Audio Graph sound card2 support
  "SND_AUDIO_GRAPH_CARD2_CUSTOM_SAMPLE" = no; # ASoC Audio Graph Card2 base custom sample support
  "SND_TEST_COMPONENT" = no; # ASoC Test component sound support
  "SND_XEN_FRONTEND" = no; # Xen para-virtualized sound frontend driver
  "SND_VIRTIO" = no; # Virtio sound driver
  "HID_SUPPORT" = yes; # HID bus support
  "HID" = yes; # HID bus core support
  "HID_BATTERY_STRENGTH" = yes; # Battery level reporting for HID devices
  "HIDRAW" = yes; # /dev/hidraw raw HID device support
  "UHID" = module; # User-space I/O driver support for HID subsystem
  "HID_GENERIC" = module; # Generic HID driver

  ##### Special HID drivers
  "HID_A4TECH" = yes; # A4TECH mice
  "HID_ACCUTOUCH" = module; # Accutouch touch device
  "HID_ACRUX" = module; # ACRUX game controller support
  "HID_ACRUX_FF" = yes; # ACRUX force feedback support
  "HID_APPLE" = yes; # Apple {i,Power,Mac}Books
  "HID_APPLEIR" = module; # Apple infrared receiver
  "HID_ASUS" = no; # Asus
  "HID_AUREAL" = module; # Aureal
  "HID_BELKIN" = yes; # Belkin Flip KVM and Wireless keyboard
  "HID_BETOP_FF" = module; # Betop Production Inc. force feedback support
  "HID_BIGBEN_FF" = module; # BigBen Interactive Kids' gamepad support
  "HID_CHERRY" = yes; # Cherry Cymotion keyboard
  "HID_CHICONY" = module; # Chicony devices
  "HID_CORSAIR" = module; # Corsair devices
  "HID_COUGAR" = module; # Cougar devices
  "HID_MACALLY" = module; # Macally devices
  "HID_PRODIKEYS" = module; # Prodikeys PC-MIDI Keyboard support
  "HID_CMEDIA" = module; # CMedia audio chips
  "HID_CP2112" = module; # Silicon Labs CP2112 HID USB-to-SMBus Bridge support
  "HID_CREATIVE_SB0540" = module; # Creative SB0540 infrared receiver
  "HID_CYPRESS" = yes; # Cypress mouse and barcode readers
  "HID_DRAGONRISE" = module; # DragonRise Inc. game controller
  "DRAGONRISE_FF" = no; # DragonRise Inc. force feedback
  "HID_EMS_FF" = module; # EMS Production Inc. force feedback support
  "HID_ELAN" = module; # ELAN USB Touchpad Support
  "HID_ELECOM" = module; # ELECOM HID devices
  "HID_ELO" = module; # ELO USB 4000/4500 touchscreen
  "HID_EVISION" = module; # EVision Keyboards Support
  "HID_EZKEY" = yes; # Ezkey BTC 8193 keyboard
  "HID_FT260" = module; # FTDI FT260 USB HID to I2C host support
  "HID_GEMBIRD" = module; # Gembird Joypad
  "HID_GFRM" = module; # Google Fiber TV Box remote control support
  "HID_GLORIOUS" = module; # Glorious PC Gaming Race mice
  "HID_HOLTEK" = module; # Holtek HID devices
  "HOLTEK_FF" = no; # Holtek On Line Grip force feedback support
  "HID_GOODIX_SPI" = module; # Goodix GT7986U SPI HID touchscreen
  "HID_GOOGLE_HAMMER" = no; # Google Hammer Keyboard
  "HID_GOOGLE_STADIA_FF" = module; # Google Stadia force feedback
  "HID_VIVALDI" = module; # Vivaldi Keyboard
  "HID_GT683R" = module; # MSI GT68xR LED support
  "HID_KEYTOUCH" = module; # Keytouch HID devices
  "HID_KYE" = module; # KYE/Genius devices
  "HID_KYSONA" = no; # Kysona devices
  "HID_UCLOGIC" = module; # UC-Logic
  "HID_WALTOP" = module; # Waltop
  "HID_VIEWSONIC" = module; # ViewSonic/Signotec
  "HID_VRC2" = no; # VRC-2 Car Controller
  "HID_XIAOMI" = module; # Xiaomi
  "HID_GYRATION" = module; # Gyration remote control
  "HID_ICADE" = module; # ION iCade arcade controller
  "HID_ITE" = yes; # ITE devices
  "HID_JABRA" = module; # Jabra USB HID Driver
  "HID_TWINHAN" = module; # Twinhan IR remote control
  "HID_KENSINGTON" = yes; # Kensington Slimblade Trackball
  "HID_LCPOWER" = module; # LC-Power
  "HID_LED" = module; # Simple RGB LED support
  "HID_LENOVO" = module; # Lenovo / Thinkpad devices
  "HID_LETSKETCH" = module; # Letsketch WP9620N tablets
  "HID_LOGITECH" = module; # Logitech devices
  "HID_LOGITECH_DJ" = module; # Logitech receivers full support
  "HID_LOGITECH_HIDPP" = module; # Logitech HID++ devices support
  "LOGITECH_FF" = no; # Logitech force feedback support
  "LOGIRUMBLEPAD2_FF" = no; # Logitech force feedback support (variant 2)
  "LOGIG940_FF" = no; # Logitech Flight System G940 force feedback support
  "LOGIWHEELS_FF" = no; # Logitech wheels configuration and force feedback support
  "HID_MAGICMOUSE" = module; # Apple Magic Mouse/Trackpad multi-touch support
  "HID_MALTRON" = module; # Maltron L90 keyboard
  "HID_MAYFLASH" = module; # Mayflash game controller adapter force feedback
  "HID_MEGAWORLD_FF" = module; # Mega World based game controller force feedback support
  "HID_REDRAGON" = yes; # Redragon keyboards
  "HID_MICROSOFT" = yes; # Microsoft non-fully HID-compliant devices
  "HID_MONTEREY" = yes; # Monterey Genius KB29E keyboard
  "HID_MULTITOUCH" = module; # HID Multitouch panels
  "HID_NINTENDO" = module; # Nintendo Joy-Con, NSO, and Pro Controller support
  "NINTENDO_FF" = no; # Nintendo Switch controller force feedback support
  "HID_NTI" = module; # NTI keyboard adapters
  "HID_NTRIG" = module; # N-Trig touch screen
  "HID_NVIDIA_SHIELD" = module; # NVIDIA SHIELD devices
  "NVIDIA_SHIELD_FF" = no; # NVIDIA SHIELD force feedback support
  "HID_ORTEK" = module; # Ortek PKB-1700/WKB-2000/Skycable wireless keyboard and mouse trackpad
  "HID_PANTHERLORD" = module; # Pantherlord/GreenAsia game controller
  "PANTHERLORD_FF" = no; # Pantherlord force feedback support
  "HID_PENMOUNT" = module; # Penmount touch device
  "HID_PETALYNX" = module; # Petalynx Maxter remote control
  "HID_PICOLCD" = module; # PicoLCD (graphic version)
  "HID_PLANTRONICS" = module; # Plantronics USB HID Driver
  "HID_PLAYSTATION" = module; # PlayStation HID Driver
  "PLAYSTATION_FF" = no; # PlayStation force feedback support
  "HID_PXRC" = module; # PhoenixRC HID Flight Controller
  "HID_RAZER" = module; # Razer non-fully HID-compliant devices
  "HID_PRIMAX" = module; # Primax non-fully HID-compliant devices
  "HID_RETRODE" = module; # Retrode 2 USB adapter for vintage video games
  "HID_ROCCAT" = module; # Roccat device support
  "HID_SAITEK" = module; # Saitek (Mad Catz) non-fully HID-compliant devices
  "HID_SAMSUNG" = module; # Samsung InfraRed remote control or keyboards
  "HID_SEMITEK" = module; # Semitek USB keyboards
  "HID_SIGMAMICRO" = module; # SiGma Micro-based keyboards
  "HID_SONY" = module; # Sony PS2/3/4 accessories
  "SONY_FF" = yes; # Sony PS2/3/4 accessories force feedback support
  "HID_SPEEDLINK" = module; # Speedlink VAD Cezanne mouse support
  "HID_STEAM" = module; # Steam Controller/Deck support
  "STEAM_FF" = no; # Steam Deck force feedback support
  "HID_STEELSERIES" = module; # Steelseries devices support
  "HID_SUNPLUS" = module; # Sunplus wireless desktop
  "HID_RMI" = module; # Synaptics RMI4 device support
  "HID_GREENASIA" = module; # GreenAsia (Product ID 0x12) game controller support
  "GREENASIA_FF" = no; # GreenAsia (Product ID 0x12) force feedback support
  "HID_SMARTJOYPLUS" = module; # SmartJoy PLUS PS2/USB adapter support
  "SMARTJOYPLUS_FF" = no; # SmartJoy PLUS PS2/USB adapter force feedback support
  "HID_TIVO" = module; # TiVo Slide Bluetooth remote control support
  "HID_TOPSEED" = module; # TopSeed Cyberlink, BTC Emprex, Conceptronic remote control support
  "HID_TOPRE" = module; # Topre REALFORCE keyboards
  "HID_THINGM" = module; # ThingM blink(1) USB RGB LED
  "HID_THRUSTMASTER" = module; # ThrustMaster devices support
  "THRUSTMASTER_FF" = no; # ThrustMaster devices force feedback support
  "HID_UDRAW_PS3" = module; # THQ PS3 uDraw tablet
  "HID_U2FZERO" = module; # U2F Zero LED and RNG support
  "HID_UNIVERSAL_PIDFF" = no; # universal-pidff: extended USB PID driver compatibility and usage
  "HID_WACOM" = module; # Wacom Intuos/Graphire tablet support (USB)
  "HID_WIIMOTE" = module; # Nintendo Wii / Wii U peripherals
  "HID_WINWING" = module; # WinWing Orion2 throttle support
  "HID_XINMO" = module; # Xin-Mo non-fully compliant devices
  "HID_ZEROPLUS" = module; # Zeroplus based game controller support
  "ZEROPLUS_FF" = no; # Zeroplus based game controller force feedback support
  "HID_ZYDACRON" = module; # Zydacron remote control support
  "HID_SENSOR_HUB" = module; # HID Sensors framework support
  "HID_SENSOR_CUSTOM_SENSOR" = no; # HID Sensors hub custom sensor support
  "HID_ALPS" = module; # Alps HID device support
  "HID_MCP2200" = no; # Microchip MCP2200 HID USB-to-GPIO bridge
  "HID_MCP2221" = module; # Microchip MCP2221 HID USB-to-I2C/SMbus host support
  ##### end of Special HID drivers

  ##### HID-BPF support
  "HID_BPF" = yes; # HID-BPF support
  ##### end of HID-BPF support

  "I2C_HID" = yes; # I2C HID support
  "I2C_HID_ACPI" = module; # HID over I2C transport layer ACPI driver
  "I2C_HID_OF" = module; # HID over I2C transport layer Open Firmware driver
  "I2C_HID_OF_ELAN" = module; # Driver for Elan hid-i2c based devices on OF systems
  "I2C_HID_OF_GOODIX" = no; # Driver for Goodix hid-i2c based devices on OF systems

  #### USB HID support
  "USB_HID" = module; # USB HID transport layer
  "HID_PID" = yes; # PID device support
  "USB_HIDDEV" = yes; # /dev/hiddev raw HID device support
  #### end of USB HID support

  "USB_SUPPORT" = yes; # USB support
  "USB_LED_TRIG" = no; # USB LED Triggers
  "USB_ULPI_BUS" = yes; # USB ULPI PHY interface support
  "USB_CONN_GPIO" = no; # USB GPIO Based Connection Detection Driver
  "USB" = yes; # Support for Host-side USB
  "USB_PCI" = yes; # PCI based USB host interface
  "USB_PCI_AMD" = no; # AMD PCI USB host support
  "USB_ANNOUNCE_NEW_DEVICES" = yes; # USB announce new devices
  "USB_DEFAULT_PERSIST" = yes; # Enable USB persist by default
  "USB_FEW_INIT_RETRIES" = no; # Limit USB device initialization to only a few retries
  "USB_DYNAMIC_MINORS" = no; # Dynamic USB minor allocation
  "USB_OTG" = yes; # OTG support
  "USB_OTG_PRODUCTLIST" = no; # Rely on OTG and EH Targeted Peripherals List
  "USB_OTG_DISABLE_EXTERNAL_HUB" = no; # Disable external hubs
  "USB_OTG_FSM" = no; # USB 2.0 OTG FSM implementation
  "USB_LEDS_TRIGGER_USBPORT" = no; # USB port LED trigger
  "USB_AUTOSUSPEND_DELAY" = freeform "2"; # Default autosuspend delay
  "USB_DEFAULT_AUTHORIZATION_MODE" = freeform "1"; # Default authorization mode for USB devices
  "USB_MON" = no; # USB Monitor
  "USB_C67X00_HCD" = no; # Cypress C67x00 HCD support
  "USB_XHCI_HCD" = yes; # xHCI HCD (USB 3.0) support
  "USB_XHCI_DBGCAP" = no; # xHCI support for debug capability
  "USB_XHCI_PCI_RENESAS" = no; # Support for additional Renesas xHCI controller with firmware
  "USB_XHCI_PLATFORM" = yes; # Generic xHCI driver for a platform device
  "USB_XHCI_SIDEBAND" = no; # xHCI support for sideband
  "USB_EHCI_HCD" = yes; # EHCI HCD (USB 2.0) support
  "USB_EHCI_ROOT_HUB_TT" = yes; # Root Hub Transaction Translators
  "USB_EHCI_TT_NEWSCHED" = yes; # Improved Transaction Translator scheduling
  "USB_EHCI_FSL" = no; # Support for Freescale on-chip EHCI USB controller
  "USB_EHCI_HCD_PLATFORM" = yes; # Generic EHCI driver for a platform device
  "USB_OXU210HP_HCD" = no; # OXU210HP HCD support
  "USB_ISP116X_HCD" = no; # ISP116X HCD support
  "USB_MAX3421_HCD" = no; # MAX3421 HCD (USB-over-SPI) support
  "USB_OHCI_HCD" = yes; # OHCI HCD (USB 1.1) support
  "USB_OHCI_HCD_PCI" = yes; # OHCI support for PCI-bus USB controllers
  "USB_OHCI_HCD_PLATFORM" = yes; # Generic OHCI driver for a platform device
  "USB_UHCI_HCD" = no; # UHCI HCD (most Intel and VIA) support
  "USB_SL811_HCD" = no; # SL811HS HCD support
  "USB_R8A66597_HCD" = no; # R8A66597 HCD support
  "USB_HCD_TEST_MODE" = no; # HCD test mode support
  "USB_XEN_HCD" = no; # Xen usb virtual host driver
  "USB_ACM" = module; # USB Modem (CDC ACM) support
  "USB_PRINTER" = module; # USB Printer support
  "USB_WDM" = no; # USB Wireless Device Management support
  "USB_TMC" = no; # USB Test and Measurement Class support
  "USB_STORAGE" = yes; # USB Mass Storage support
  "USB_STORAGE_DEBUG" = no; # USB Mass Storage verbose debug
  "USB_STORAGE_REALTEK" = no; # Realtek Card Reader support
  "USB_STORAGE_DATAFAB" = no; # Datafab Compact Flash Reader support
  "USB_STORAGE_FREECOM" = no; # Freecom USB/ATAPI Bridge support
  "USB_STORAGE_ISD200" = no; # ISD-200 USB/ATA Bridge support
  "USB_STORAGE_USBAT" = no; # USBAT/USBAT02-based storage support
  "USB_STORAGE_SDDR09" = no; # SanDisk SDDR-09 (and other SmartMedia, including DPCM) support
  "USB_STORAGE_SDDR55" = no; # SanDisk SDDR-55 SmartMedia support
  "USB_STORAGE_JUMPSHOT" = no; # Lexar Jumpshot Compact Flash Reader
  "USB_STORAGE_ALAUDA" = no; # Olympus MAUSB-10/Fuji DPC-R1 support
  "USB_STORAGE_ONETOUCH" = no; # Support OneTouch Button on Maxtor Hard Drives
  "USB_STORAGE_KARMA" = no; # Support for Rio Karma music player
  "USB_STORAGE_CYPRESS_ATACB" = no; # SAT emulation on Cypress USB/ATA Bridge with ATACB
  "USB_STORAGE_ENE_UB6250" = no; # USB ENE card reader support
  "USB_UAS" = no; # USB Attached SCSI
  "USB_MDC800" = no; # USB Mustek MDC800 Digital Camera support
  "USB_MICROTEK" = no; # Microtek X6USB scanner support
  "USBIP_CORE" = no; # USB/IP support
  "USB_CDNS_SUPPORT" = module; # Cadence USB Support
  "USB_CDNS3" = module; # Cadence USB3 Dual-Role Controller
  "USB_CDNS3_GADGET" = yes; # Cadence USB3 device controller
  "USB_CDNS3_HOST" = yes; # Cadence USB3 host controller
  "USB_CDNS3_PCI_WRAP" = module; # Cadence USB3 support on PCIe-based platforms
  "USB_CDNSP_PCI" = no; # Cadence CDNSP Dual-Role Controller
  "USB_MUSB_HDRC" = no; # Inventra Highspeed Dual Role Controller
  "USB_DWC3" = yes; # DesignWare USB3 DRD Core Support
  "USB_DWC3_ULPI" = yes; # Register ULPI PHY Interface
  "USB_DWC3_HOST" = no; # Host only mode
  "USB_DWC3_GADGET" = no; # Gadget only mode
  "USB_DWC3_DUAL_ROLE" = yes; # Dual Role mode
  "USB_DWC3_PCI" = yes; # PCIe-based Platforms
  "USB_DWC3_HAPS" = yes; # Synopsys PCIe-based HAPS Platforms
  "USB_DWC3_OF_SIMPLE" = yes; # Generic OF Simple Glue Layer
  "USB_DWC3_QCOM" = yes; # Qualcomm Platform
  "USB_DWC3_RTK" = yes; # Realtek DWC3 Platform Driver
  "USB_DWC2" = no; # DesignWare USB2 DRD Core Support
  "USB_CHIPIDEA" = no; # ChipIdea Highspeed Dual Role Controller
  "USB_ISP1760" = no; # NXP ISP 1760/1761/1763 support
  "USB_SERIAL" = module; # USB Serial Converter support
  "USB_SERIAL_GENERIC" = no; # USB Generic Serial Driver
  "USB_SERIAL_SIMPLE" = no; # USB Serial Simple Driver
  "USB_SERIAL_AIRCABLE" = no; # USB AIRcable Bluetooth Dongle Driver
  "USB_SERIAL_ARK3116" = no; # USB ARK Micro 3116 USB Serial Driver
  "USB_SERIAL_BELKIN" = no; # USB Belkin and Peracom Single Port Serial Driver
  "USB_SERIAL_CH341" = no; # USB Winchiphead CH341 Single Port Serial Driver
  "USB_SERIAL_WHITEHEAT" = no; # USB ConnectTech WhiteHEAT Serial Driver
  "USB_SERIAL_DIGI_ACCELEPORT" = no; # USB Digi International AccelePort USB Serial Driver
  "USB_SERIAL_CP210X" = module; # USB CP210x family of UART Bridge Controllers
  "USB_SERIAL_CYPRESS_M8" = no; # USB Cypress M8 USB Serial Driver
  "USB_SERIAL_EMPEG" = no; # USB Empeg empeg-car Mark I/II Driver
  "USB_SERIAL_FTDI_SIO" = module; # USB FTDI Single Port Serial Driver
  "USB_SERIAL_VISOR" = no; # USB Handspring Visor / Palm m50x / Sony Clie Driver
  "USB_SERIAL_IPAQ" = no; # USB PocketPC PDA Driver
  "USB_SERIAL_IR" = no; # USB IR Dongle Serial Driver
  "USB_SERIAL_EDGEPORT" = no; # USB Inside Out Edgeport Serial Driver
  "USB_SERIAL_EDGEPORT_TI" = no; # USB Inside Out Edgeport Serial Driver (TI devices)
  "USB_SERIAL_F81232" = no; # USB Fintek F81232 Single Port Serial Driver
  "USB_SERIAL_F8153X" = no; # USB Fintek F81532/534 Multi-Ports Serial Driver
  "USB_SERIAL_GARMIN" = no; # USB Garmin GPS driver
  "USB_SERIAL_IPW" = no; # USB IPWireless (3G UMTS TDD) Driver
  "USB_SERIAL_IUU" = no; # USB Infinity USB Unlimited Phoenix Driver
  "USB_SERIAL_KEYSPAN_PDA" = no; # USB Keyspan PDA / Xircom Single Port Serial Driver
  "USB_SERIAL_KEYSPAN" = no; # USB Keyspan USA-xxx Serial Driver
  "USB_SERIAL_KLSI" = no; # USB KL5KUSB105 (Palmconnect) Driver
  "USB_SERIAL_KOBIL_SCT" = no; # USB KOBIL chipcard reader
  "USB_SERIAL_MCT_U232" = no; # USB MCT Single Port Serial Driver
  "USB_SERIAL_METRO" = no; # USB Metrologic Instruments USB-POS Barcode Scanner Driver
  "USB_SERIAL_MOS7720" = no; # USB Moschip 7720 Serial Driver
  "USB_SERIAL_MOS7840" = no; # USB Moschip 7840/7820 USB Serial Driver
  "USB_SERIAL_MXUPORT" = no; # USB Moxa UPORT Serial Driver
  "USB_SERIAL_NAVMAN" = no; # USB Navman GPS device
  "USB_SERIAL_PL2303" = no; # USB Prolific 2303 Single Port Serial Driver
  "USB_SERIAL_OTI6858" = no; # USB Ours Technology Inc. OTi-6858 USB To RS232 Bridge Controller
  "USB_SERIAL_QCAUX" = no; # USB Qualcomm Auxiliary Serial Port Driver
  "USB_SERIAL_QUALCOMM" = no; # USB Qualcomm Serial modem
  "USB_SERIAL_SPCP8X5" = no; # USB SPCP8x5 USB To Serial Driver
  "USB_SERIAL_SAFE" = no; # USB Safe Serial (Encapsulated) Driver
  "USB_SERIAL_SIERRAWIRELESS" = no; # USB Sierra Wireless Driver
  "USB_SERIAL_SYMBOL" = no; # USB Symbol Barcode driver (serial mode)
  "USB_SERIAL_TI" = no; # USB TI 3410/5052 Serial Driver
  "USB_SERIAL_CYBERJACK" = no; # USB REINER SCT cyberJack pinpad/e-com chipcard reader
  "USB_SERIAL_OPTION" = module; # USB driver for GSM and CDMA modems
  "USB_SERIAL_OMNINET" = no; # USB ZyXEL omni.net LCD Plus Driver
  "USB_SERIAL_OPTICON" = no; # USB Opticon Barcode driver (serial mode)
  "USB_SERIAL_XSENS_MT" = no; # Xsens motion tracker serial interface driver
  "USB_SERIAL_WISHBONE" = no; # USB-Wishbone adapter interface driver
  "USB_SERIAL_SSU100" = no; # USB Quatech SSU-100 Single Port Serial Driver
  "USB_SERIAL_QT2" = no; # USB Quatech Serial Driver for USB 2 devices
  "USB_SERIAL_UPD78F0730" = no; # USB Renesas uPD78F0730 Single Port Serial Driver
  "USB_SERIAL_XR" = no; # USB MaxLinear/Exar USB to Serial driver
  "USB_SERIAL_DEBUG" = no; # USB Debugging Device
  "USB_EMI62" = no; # EMI 6|2m USB Audio interface support
  "USB_EMI26" = no; # EMI 2|6 USB Audio interface support
  "USB_ADUTUX" = no; # ADU devices from Ontrak Control Systems
  "USB_SEVSEG" = no; # USB 7-Segment LED Display
  "USB_LEGOTOWER" = no; # USB Lego Infrared Tower support
  "USB_LCD" = no; # USB LCD driver support
  "USB_CYPRESS_CY7C63" = no; # Cypress CY7C63xxx USB driver support
  "USB_CYTHERM" = no; # Cypress USB thermometer driver support
  "USB_IDMOUSE" = no; # Siemens ID USB Mouse Fingerprint sensor support
  "USB_APPLEDISPLAY" = no; # Apple Cinema Display support
  "USB_QCOM_EUD" = module; # QCOM Embedded USB Debugger(EUD) Driver
  "APPLE_MFI_FASTCHARGE" = no; # Fast charge control for iOS devices
  "USB_LJCA" = no; # Intel La Jolla Cove Adapter support
  "USB_SISUSBVGA" = no; # USB 2.0 SVGA dongle support (Net2280/SiS315)
  "USB_LD" = no; # USB LD driver
  "USB_TRANCEVIBRATOR" = no; # PlayStation 2 Trance Vibrator driver support
  "USB_IOWARRIOR" = no; # IO Warrior driver support
  "USB_TEST" = no; # USB testing driver
  "USB_EHSET_TEST_FIXTURE" = no; # USB EHSET Test Fixture driver
  "USB_ISIGHTFW" = no; # iSight firmware loading support
  "USB_YUREX" = no; # USB YUREX driver support
  "USB_EZUSB_FX2" = no; # Functions for loading firmware on EZUSB chips
  "USB_HUB_USB251XB" = no; # USB251XB Hub Controller Configuration Driver
  "USB_HSIC_USB3503" = no; # USB3503 HSIC to USB20 Driver
  "USB_HSIC_USB4604" = no; # USB4604 HSIC to USB20 Driver
  "USB_LINK_LAYER_TEST" = no; # USB Link Layer Test driver
  "USB_CHAOSKEY" = no; # ChaosKey random number generator driver support
  "USB_ONBOARD_DEV" = module; # Onboard USB device support
  "USB_ONBOARD_DEV_USB5744" = no; # Onboard USB Microchip usb5744 hub with SMBus support

  #### USB Physical Layer drivers
  "NOP_USB_XCEIV" = no; # NOP USB Transceiver Driver
  "USB_GPIO_VBUS" = no; # GPIO based peripheral-only VBUS sensing 'transceiver'
  "USB_ISP1301" = no; # NXP ISP1301 USB transceiver support
  "USB_ULPI" = yes; # Generic ULPI Transceiver Driver
  #### end of USB Physical Layer drivers

  "USB_GADGET" = yes; # USB Gadget Support
  "USB_GADGET_DEBUG" = no; # Debugging messages (DEVELOPMENT)
  "USB_GADGET_DEBUG_FILES" = no; # Debugging information files (DEVELOPMENT)
  "USB_GADGET_DEBUG_FS" = no; # Debugging information files in debugfs (DEVELOPMENT)
  "USB_GADGET_VBUS_DRAW" = freeform "2"; # Maximum VBUS Power usage (2-500 mA)
  "USB_GADGET_STORAGE_NUM_BUFFERS" = freeform "2"; # Number of storage pipeline buffers
  "U_SERIAL_CONSOLE" = yes; # Serial gadget console support

  ##### USB Peripheral Controller
  "USB_GR_UDC" = no; # Aeroflex Gaisler GRUSBDC USB Peripheral Controller Driver
  "USB_R8A66597" = no; # Renesas R8A66597 USB Peripheral Controller
  "USB_PXA27X" = no; # PXA 27x
  "USB_SNP_UDC_PLAT" = yes; # Synopsys USB 2.0 Device controller
  "USB_M66592" = no; # Renesas M66592 USB Peripheral Controller
  "USB_BDC_UDC" = yes; # Broadcom USB3.0 device controller IP driver(BDC)
  "USB_AMD5536UDC" = no; # AMD5536 UDC
  "USB_NET2280" = no; # NetChip NET228x / PLX USB3x8x
  "USB_GOKU" = no; # Toshiba TC86C001 'Goku-S'
  "USB_EG20T" = no; # Intel QUARK X1000/EG20T PCH/LAPIS Semiconductor IOH(ML7213/ML7831) UDC
  "USB_GADGET_XILINX" = no; # Xilinx USB Driver
  "USB_MAX3420_UDC" = no; # MAX3420 (USB-over-SPI) support
  "USB_CDNS2_UDC" = no; # Cadence USBHS Device Controller
  "USB_DUMMY_HCD" = no; # Dummy HCD (DEVELOPMENT)
  ##### end of USB Peripheral Controller

  "USB_CONFIGFS" = yes; # USB Gadget functions configurable through configfs
  "USB_CONFIGFS_SERIAL" = yes; # Generic serial bulk in/out
  "USB_CONFIGFS_ACM" = yes; # Abstract Control Model (CDC ACM)
  "USB_CONFIGFS_OBEX" = yes; # Object Exchange Model (CDC OBEX)
  "USB_CONFIGFS_NCM" = yes; # Network Control Model (CDC NCM)
  "USB_CONFIGFS_ECM" = yes; # Ethernet Control Model (CDC ECM)
  "USB_CONFIGFS_ECM_SUBSET" = yes; # Ethernet Control Model (CDC ECM) subset
  "USB_CONFIGFS_RNDIS" = yes; # RNDIS
  "USB_CONFIGFS_EEM" = yes; # Ethernet Emulation Model (EEM)
  "USB_CONFIGFS_MASS_STORAGE" = yes; # Mass storage
  "USB_CONFIGFS_F_LB_SS" = no; # Loopback and sourcesink function (for testing)
  "USB_CONFIGFS_F_FS" = yes; # Function filesystem (FunctionFS)
  "USB_CONFIGFS_F_UAC1" = no; # Audio Class 1.0
  "USB_CONFIGFS_F_UAC1_LEGACY" = no; # Audio Class 1.0 (legacy implementation)
  "USB_CONFIGFS_F_UAC2" = no; # Audio Class 2.0
  "USB_CONFIGFS_F_MIDI" = no; # MIDI function
  "USB_CONFIGFS_F_MIDI2" = no; # MIDI 2.0 function
  "USB_CONFIGFS_F_HID" = yes; # HID function
  "USB_CONFIGFS_F_UVC" = no; # USB Webcam function
  "USB_CONFIGFS_F_PRINTER" = no; # Printer function

  ##### USB Gadget precomposed configurations
  "USB_ZERO" = no; # Gadget Zero (DEVELOPMENT)
  "USB_AUDIO" = no; # Audio Gadget
  "USB_ETH" = no; # Ethernet Gadget (with CDC Ethernet support)
  "USB_G_NCM" = no; # Network Control Model (NCM) support
  "USB_GADGETFS" = no; # Gadget Filesystem
  "USB_FUNCTIONFS" = no; # Function Filesystem
  "USB_MASS_STORAGE" = no; # Mass Storage Gadget
  "USB_G_SERIAL" = no; # Serial Gadget (with CDC ACM and CDC OBEX support)
  "USB_MIDI_GADGET" = no; # MIDI Gadget
  "USB_G_PRINTER" = no; # Printer Gadget
  "USB_CDC_COMPOSITE" = no; # CDC Composite Device (Ethernet and ACM)
  "USB_G_ACM_MS" = no; # CDC Composite Device (ACM and mass storage)
  "USB_G_MULTI" = no; # Multifunction Composite Gadget
  "USB_G_HID" = no; # HID Gadget
  "USB_G_DBGP" = no; # EHCI Debug Device Gadget
  "USB_G_WEBCAM" = no; # USB Webcam Gadget
  "USB_RAW_GADGET" = no; # USB Raw Gadget
  ##### end of USB Gadget precomposed configurations

  "TYPEC" = yes; # USB Type-C Support
  "TYPEC_TCPM" = module; # USB Type-C Port Controller Manager
  "TYPEC_TCPCI" = module; # Type-C Port Controller Interface driver
  "TYPEC_RT1711H" = module; # Richtek RT1711H Type-C chip driver
  "TYPEC_MT6360" = module; # Mediatek MT6360 Type-C driver
  "TYPEC_TCPCI_MAXIM" = module; # Maxim TCPCI based Type-C chip driver
  "TYPEC_FUSB302" = no; # Fairchild FUSB302 Type-C chip driver
  "TYPEC_QCOM_PMIC" = module; # Qualcomm PMIC USB Type-C Port Controller Manager driver
  "TYPEC_UCSI" = module; # USB Type-C Connector System Software Interface driver
  "UCSI_CCG" = module; # UCSI Interface Driver for Cypress CCGx
  "UCSI_ACPI" = no; # UCSI ACPI Interface Driver
  "UCSI_STM32G0" = no; # UCSI Interface Driver for STM32G0
  "UCSI_PMIC_GLINK" = module; # UCSI Qualcomm PMIC GLINK Interface Driver
  "CROS_EC_UCSI" = module; # UCSI Driver for ChromeOS EC
  "UCSI_LENOVO_YOGA_C630" = no; # UCSI Interface Driver for Lenovo Yoga C630
  "TYPEC_TPS6598X" = module; # TI TPS6598x USB Power Delivery controller driver
  "TYPEC_ANX7411" = no; # Analogix ANX7411 Type-C DRP Port controller driver
  "TYPEC_RT1719" = no; # Richtek RT1719 Sink Only Type-C controller driver
  "TYPEC_HD3SS3220" = no; # TI HD3SS3220 Type-C DRP Port controller driver
  "TYPEC_STUSB160X" = no; # STMicroelectronics STUSB160x Type-C controller driver
  "TYPEC_WUSB3801" = no; # Willsemi WUSB3801 Type-C port controller driver

  ##### USB Type-C Multiplexer/DeMultiplexer Switch support
  "TYPEC_MUX_FSA4480" = module; # ON Semi FSA4480 Analog Audio Switch driver
  "TYPEC_MUX_GPIO_SBU" = module; # Generic GPIO based SBU mux for USB Type-C applications
  "TYPEC_MUX_PI3USB30532" = no; # Pericom PI3USB30532 Type-C cross switch driver
  "TYPEC_MUX_IT5205" = module; # ITE IT5205 Type-C USB Alt Mode Passive MUX driver
  "TYPEC_MUX_NB7VPQ904M" = module; # On Semiconductor NB7VPQ904M Type-C redriver driver
  "TYPEC_MUX_PS883X" = module; # Parade PS883x Type-C retimer driver
  "TYPEC_MUX_PTN36502" = no; # NXP PTN36502 Type-C redriver driver
  "TYPEC_MUX_TUSB1046" = no; # TI TUSB1046 Type-C crosspoint switch driver
  "TYPEC_MUX_WCD939X_USBSS" = module; # Qualcomm WCD939x USBSS Analog Audio Switch driver
  ##### end of USB Type-C Multiplexer/DeMultiplexer Switch support

  ##### USB Type-C Alternate Mode drivers
  "TYPEC_DP_ALTMODE" = module; # DisplayPort Alternate Mode driver
  "TYPEC_NVIDIA_ALTMODE" = no; # NVIDIA Alternate Mode driver
  "TYPEC_TBT_ALTMODE" = no; # Thunderbolt3 Alternate Mode driver
  ##### end of USB Type-C Alternate Mode drivers

  "USB_ROLE_SWITCH" = yes; # USB Role Switch Support
  "MMC" = yes; # MMC/SD/SDIO card support
  "PWRSEQ_EMMC" = yes; # HW reset support for eMMC
  "PWRSEQ_SD8787" = no; # HW reset support for SD8787 BT + Wifi module
  "PWRSEQ_SIMPLE" = yes; # Simple HW reset support for MMC
  "MMC_BLOCK" = yes; # MMC block device driver
  "MMC_BLOCK_MINORS" = freeform "32"; # Number of minors per block device
  "SDIO_UART" = no; # SDIO UART/GPS class support
  "MMC_TEST" = no; # MMC host test driver
  "MMC_CRYPTO" = no; # MMC Crypto Engine Support
  "MMC_DEBUG" = no; # MMC host drivers debugging
  "MMC_ARMMMCI" = yes; # ARM AMBA Multimedia Card Interface support
  "MMC_QCOM_DML" = yes; # Qualcomm Data Mover for SD Card Controller
  "MMC_STM32_SDMMC" = yes; # STMicroelectronics STM32 SDMMC Controller
  "MMC_SDHCI" = yes; # Secure Digital Host Controller Interface support
  "MMC_SDHCI_PCI" = no; # SDHCI support on PCI bus
  "MMC_SDHCI_ACPI" = yes; # SDHCI support for ACPI enumerated SDHCI controllers
  "MMC_SDHCI_PLTFM" = yes; # SDHCI platform and OF driver helper
  "MMC_SDHCI_OF_ARASAN" = no; # SDHCI OF support for the Arasan SDHCI controllers
  "MMC_SDHCI_OF_AT91" = no; # SDHCI OF support for the Atmel SDMMC controller
  "MMC_SDHCI_OF_DWCMSHC" = no; # SDHCI OF support for the Synopsys DWC MSHC
  "MMC_SDHCI_OF_MA35D1" = no; # SDHCI OF support for the MA35D1 SDHCI controller
  "MMC_SDHCI_CADENCE" = no; # SDHCI support for the Cadence SD/SDIO/eMMC controller
  "MMC_SDHCI_F_SDH30" = no; # SDHCI support for Fujitsu Semiconductor F_SDH30
  "MMC_SDHCI_MILBEAUT" = no; # SDHCI support for Socionext Milbeaut Serieas using F_SDH30
  "MMC_SDHCI_MSM" = yes; # Qualcomm SDHCI Controller Support
  "MMC_TIFM_SD" = no; # TI Flash Media MMC/SD Interface support
  "MMC_SPI" = yes; # MMC/SD/SDIO over SPI
  "MMC_CB710" = no; # ENE CB710 MMC/SD Interface support
  "MMC_VIA_SDMMC" = no; # VIA SD/MMC Card Reader Driver
  "MMC_DW" = yes; # Synopsys DesignWare Memory Card Interface
  "MMC_DW_PLTFM" = yes; # Synopsys Designware MCI Support as platform device
  "MMC_DW_BLUEFIELD" = no; # BlueField specific extensions for Synopsys DW Memory Card Interface
  "MMC_DW_EXYNOS" = no; # Exynos specific extensions for Synopsys DW Memory Card Interface
  "MMC_DW_HI3798CV200" = no; # Hi3798CV200 specific extensions for Synopsys DW Memory Card Interface
  "MMC_DW_HI3798MV200" = no; # Hi3798MV200 specific extensions for Synopsys DW Memory Card Interface
  "MMC_DW_K3" = no; # K3 specific extensions for Synopsys DW Memory Card Interface
  "MMC_DW_PCI" = no; # Synopsys Designware MCI support on PCI bus
  "MMC_VUB300" = no; # VUB300 USB to SDIO/SD/MMC Host Controller support
  "MMC_USHC" = no; # USB SD Host Controller (USHC) support
  "MMC_USDHI6ROL0" = no; # Renesas USDHI6ROL0 SD/SDIO Host Controller support
  "MMC_CQHCI" = yes; # Command Queue Host Controller Interface support
  "MMC_HSQ" = yes; # MMC Host Software Queue support
  "MMC_TOSHIBA_PCI" = no; # Toshiba Type A SD/MMC Card Interface Driver
  "MMC_MTK" = no; # MediaTek SD/MMC Card Interface support
  "MMC_SDHCI_XENON" = no; # Marvell Xenon eMMC/SD/SDIO SDHCI driver
  "SCSI_UFSHCD" = yes; # Universal Flash Storage Controller
  "SCSI_UFS_BSG" = yes; # Universal Flash Storage BSG device node
  "SCSI_UFS_CRYPTO" = yes; # UFS Crypto Engine Support
  "SCSI_UFS_HWMON" = no; # UFS Temperature Notification
  "SCSI_UFSHCD_PCI" = no; # PCI bus based UFS Controller support
  "SCSI_UFSHCD_PLATFORM" = yes; # Platform bus based UFS Controller support
  "SCSI_UFS_CDNS_PLATFORM" = module; # Cadence UFS Controller platform driver
  "SCSI_UFS_DWC_TC_PLATFORM" = no; # DesignWare platform support using a G210 Test Chip
  "SCSI_UFS_QCOM" = yes; # QCOM specific hooks to UFS controller platform driver
  "MEMSTICK" = no; # Sony MemoryStick card support
  "NEW_LEDS" = yes; # LED Support
  "LEDS_CLASS" = yes; # LED Class Support
  "LEDS_CLASS_FLASH" = yes; # LED Flash Class Support
  "LEDS_CLASS_MULTICOLOR" = module; # LED Multicolor Class Support
  "LEDS_BRIGHTNESS_HW_CHANGED" = no; # LED Class brightness_hw_changed attribute support
  "LEDS_AN30259A" = no; # LED support for Panasonic AN30259A
  "LEDS_AW200XX" = no; # LED support for Awinic AW20036/AW20054/AW20072/AW20108
  "LEDS_AW2013" = no; # LED support for Awinic AW2013
  "LEDS_BCM6328" = no; # LED Support for Broadcom BCM6328
  "LEDS_BCM6358" = no; # LED Support for Broadcom BCM6358
  "LEDS_CR0014114" = no; # LED Support for Crane CR0014114
  "LEDS_CROS_EC" = module; # LED Support for ChromeOS EC
  "LEDS_EL15203000" = no; # LED Support for Crane EL15203000
  "LEDS_LM3530" = no; # LCD Backlight driver for LM3530
  "LEDS_LM3532" = no; # LCD Backlight driver for LM3532
  "LEDS_LM3642" = no; # LED support for LM3642 Chip
  "LEDS_LM3692X" = module; # LED support for LM3692x Chips
  "LEDS_PCA9532" = module; # LED driver for PCA9532 dimmer
  "LEDS_PCA9532_GPIO" = no; # Enable GPIO support for PCA9532
  "LEDS_GPIO" = yes; # LED Support for GPIO connected LEDs
  "LEDS_LP3944" = no; # LED Support for N.S. LP3944 (Fun Light) I2C chip
  "LEDS_LP3952" = no; # LED Support for TI LP3952 2 channel LED driver
  "LEDS_LP50XX" = no; # LED Support for TI LP5036/30/24/18/12/09 LED driver chip
  "LEDS_LP55XX_COMMON" = no; # Common Driver for TI/National LP5521/5523/55231/5562/5569/8501
  "LEDS_LP8860" = no; # LED support for the TI LP8860 4 channel LED driver
  "LEDS_LP8864" = no; # LED support for the TI LP8864/LP8866 4/6 channel LED drivers
  "LEDS_PCA955X" = no; # LED Support for PCA955x I2C chips
  "LEDS_PCA963X" = no; # LED support for PCA963x I2C chip
  "LEDS_PCA995X" = no; # LED Support for PCA995x I2C chips
  "LEDS_DAC124S085" = no; # LED Support for DAC124S085 SPI DAC
  "LEDS_PWM" = yes; # PWM driven LED Support
  "LEDS_REGULATOR" = no; # REGULATOR driven LED support
  "LEDS_BD2606MVV" = no; # LED driver for BD2606MVV
  "LEDS_BD2802" = no; # LED driver for BD2802 RGB LED
  "LEDS_LT3593" = no; # LED driver for LT3593 controllers
  "LEDS_TCA6507" = no; # LED Support for TCA6507 I2C chip
  "LEDS_TLC591XX" = no; # LED driver for TLC59108 and TLC59116 controllers
  "LEDS_MAX77705" = module; # LED support for Maxim MAX77705 PMIC
  "LEDS_LM355x" = no; # LED support for LM3554 and LM3556 chips
  "LEDS_IS31FL319X" = no; # LED Support for ISSI IS31FL319x I2C LED controller family
  "LEDS_IS31FL32XX" = no; # LED support for ISSI IS31FL32XX I2C LED controller family
  "LEDS_BLINKM" = no; # LED support for the BlinkM I2C RGB LED
  "LEDS_SYSCON" = yes; # LED support for LEDs on system controllers
  "LEDS_MLXREG" = no; # LED support for the Mellanox switches management control
  "LEDS_USER" = no; # Userspace LED support
  "LEDS_SPI_BYTE" = no; # LED support for SPI LED controller with a single byte
  "LEDS_LM3697" = no; # LED driver for LM3697
  "LEDS_ST1202" = no; # LED Support for STMicroelectronics LED1202 I2C chips
  "LEDS_AAT1290" = no; # LED support for the AAT1290
  "LEDS_AS3645A" = no; # AS3645A and LM3555 LED flash controllers support
  "LEDS_KTD2692" = no; # LED support for Kinetic KTD2692 flash LED controller
  "LEDS_LM3601X" = no; # LED support for LM3601x Chips
  "LEDS_MT6360" = no; # LED Support for Mediatek MT6360 PMIC
  "LEDS_QCOM_FLASH" = module; # LED support for flash module inside Qualcomm Technologies, Inc. PMIC
  "LEDS_RT4505" = no; # LED support for RT4505 flashlight controller
  "LEDS_RT8515" = no; # LED support for Richtek RT8515 flash/torch LED
  "LEDS_SGM3140" = no; # LED support for the SGM3140
  "LEDS_SY7802" = no; # LED support for the Silergy SY7802
  "LEDS_TPS6131X" = no; # LED support for TI TPS6131x flash LED driver
  "LEDS_GROUP_MULTICOLOR" = no; # LEDs group multi-color support
  "LEDS_KTD202X" = no; # LED support for KTD202x Chips
  "LEDS_NCP5623" = no; # LED support for NCP5623
  "LEDS_PWM_MULTICOLOR" = no; # PWM driven multi-color LED Support
  "LEDS_QCOM_LPG" = module; # LED support for Qualcomm LPG
  "LEDS_TRIGGERS" = yes; # LED Trigger support
  "LEDS_TRIGGER_TIMER" = yes; # LED Timer Trigger
  "LEDS_TRIGGER_ONESHOT" = yes; # LED One-shot Trigger
  "LEDS_TRIGGER_HEARTBEAT" = yes; # LED Heartbeat Trigger
  "LEDS_TRIGGER_BACKLIGHT" = yes; # LED backlight Trigger
  "LEDS_TRIGGER_CPU" = yes; # LED CPU Trigger
  "LEDS_TRIGGER_ACTIVITY" = yes; # LED activity Trigger
  "LEDS_TRIGGER_GPIO" = no; # LED GPIO Trigger
  "LEDS_TRIGGER_DEFAULT_ON" = yes; # LED Default ON Trigger
  "LEDS_TRIGGER_TRANSIENT" = no; # LED Transient Trigger
  "LEDS_TRIGGER_CAMERA" = no; # LED Camera Flash/Torch Trigger
  "LEDS_TRIGGER_PANIC" = yes; # LED Panic Trigger
  "LEDS_TRIGGER_NETDEV" = no; # LED Netdev Trigger
  "LEDS_TRIGGER_PATTERN" = yes; # LED Pattern Trigger
  "LEDS_TRIGGER_TTY" = no; # LED Trigger for TTY devices
  "LEDS_TRIGGER_INPUT_EVENTS" = no; # LED Input events trigger
  "ACCESSIBILITY" = no; # Accessibility support
  "INFINIBAND" = no; # InfiniBand support
  "EDAC" = yes; # EDAC (Error Detection And Correction) reporting
  "EDAC_LEGACY_SYSFS" = yes; # EDAC legacy sysfs
  "EDAC_DEBUG" = no; # Debugging
  "EDAC_GHES" = yes; # Output ACPI APEI/GHES BIOS detected errors via EDAC
  "EDAC_SCRUB" = no; # EDAC scrub feature
  "EDAC_ECS" = no; # EDAC ECS (Error Check Scrub) feature
  "EDAC_MEM_REPAIR" = no; # EDAC memory repair feature
  "EDAC_THUNDERX" = no; # Cavium ThunderX EDAC
  "EDAC_XGENE" = no; # APM X-Gene SoC
  "EDAC_QCOM" = no; # QCOM EDAC Controller
  "EDAC_DMC520" = no; # ARM DMC-520 ECC
  "RTC_CLASS" = yes; # Real Time Clock
  "RTC_HCTOSYS" = yes; # Set system time from RTC on startup and resume
  "RTC_HCTOSYS_DEVICE" = freeform "rtc0"; # RTC used to set the system time
  "RTC_SYSTOHC" = yes; # Set the RTC time based on NTP synchronization
  "RTC_SYSTOHC_DEVICE" = freeform "rtc0"; # RTC used to synchronize NTP adjustment
  "RTC_DEBUG" = no; # RTC debug support
  "RTC_NVMEM" = yes; # RTC non volatile storage support
  "RTC_INTF_SYSFS" = yes; # /sys/class/rtc/rtcN (sysfs)
  "RTC_INTF_PROC" = yes; # /proc/driver/rtc (procfs for rtcN)
  "RTC_INTF_DEV" = yes; # /dev/rtcN (character devices)
  "RTC_INTF_DEV_UIE_EMUL" = no; # RTC UIE emulation on dev interface
  "RTC_DRV_TEST" = no; # Test driver/device
  "RTC_DRV_ABB5ZES3" = no; # Abracon AB-RTCMC-32.768kHz-B5ZE-S3
  "RTC_DRV_ABEOZ9" = no; # Abracon AB-RTCMC-32.768kHz-EOZ9
  "RTC_DRV_ABX80X" = no; # Abracon ABx80x
  "RTC_DRV_DS1307" = no; # Dallas/Maxim DS1307/37/38/39/40/41, ST M41T00, EPSON RX-8025, ISL12057
  "RTC_DRV_DS1374" = no; # Dallas/Maxim DS1374
  "RTC_DRV_DS1672" = no; # Dallas/Maxim DS1672
  "RTC_DRV_HYM8563" = no; # Haoyu Microelectronics HYM8563
  "RTC_DRV_MAX6900" = no; # Maxim MAX6900
  "RTC_DRV_MAX31335" = no; # Analog Devices MAX31335
  "RTC_DRV_NCT3018Y" = no; # Nuvoton NCT3018Y
  "RTC_DRV_RK808" = no; # Rockchip RK805/RK808/RK809/RK817/RK818 RTC
  "RTC_DRV_RS5C372" = no; # Ricoh R2025S/D, RS5C372A/B, RV5C386, RV5C387A
  "RTC_DRV_ISL1208" = module; # Intersil ISL1208
  "RTC_DRV_ISL12022" = no; # Intersil ISL12022
  "RTC_DRV_ISL12026" = no; # Intersil ISL12026
  "RTC_DRV_X1205" = no; # Xicor/Intersil X1205
  "RTC_DRV_PCF8523" = no; # NXP PCF8523
  "RTC_DRV_PCF85063" = module; # NXP PCF85063
  "RTC_DRV_PCF85363" = no; # NXP PCF85363
  "RTC_DRV_PCF8563" = module; # Philips PCF8563/Epson RTC8564
  "RTC_DRV_PCF8583" = no; # Philips PCF8583
  "RTC_DRV_M41T80" = no; # ST M41T62/65/M41T80/81/82/83/84/85/87 and compatible
  "RTC_DRV_BQ32K" = module; # TI BQ32000
  "RTC_DRV_TPS6594" = module; # TI TPS6594 RTC driver
  "RTC_DRV_S35390A" = no; # Seiko Instruments S-35390A
  "RTC_DRV_FM3130" = no; # Ramtron FM3130
  "RTC_DRV_RX8010" = no; # Epson RX8010SJ
  "RTC_DRV_RX8111" = no; # Epson RX8111
  "RTC_DRV_RX8581" = no; # Epson RX-8571/RX-8581
  "RTC_DRV_RX8025" = no; # Epson RX-8025SA/NB
  "RTC_DRV_EM3027" = no; # EM Microelectronic EM3027
  "RTC_DRV_RV3028" = no; # Micro Crystal RV3028
  "RTC_DRV_RV3032" = no; # Micro Crystal RV3032
  "RTC_DRV_RV8803" = no; # Micro Crystal RV8803, Epson RX8900
  "RTC_DRV_S5M" = no; # Samsung S2M/S5M series
  "RTC_DRV_SD2405AL" = no; # DFRobot SD2405AL
  "RTC_DRV_SD3078" = no; # ZXW Shenzhen whwave SD3078
  "RTC_DRV_M41T93" = no; # ST M41T93
  "RTC_DRV_M41T94" = no; # ST M41T94
  "RTC_DRV_DS1302" = no; # Dallas/Maxim DS1302
  "RTC_DRV_DS1305" = no; # Dallas/Maxim DS1305/DS1306
  "RTC_DRV_DS1343" = no; # Dallas/Maxim DS1343/DS1344
  "RTC_DRV_DS1347" = no; # Dallas/Maxim DS1347
  "RTC_DRV_DS1390" = no; # Dallas/Maxim DS1390/93/94
  "RTC_DRV_MAX6916" = no; # Maxim MAX6916
  "RTC_DRV_R9701" = no; # Epson RTC-9701JE
  "RTC_DRV_RX4581" = no; # Epson RX-4581
  "RTC_DRV_RS5C348" = no; # Ricoh RS5C348A/B
  "RTC_DRV_MAX6902" = no; # Maxim MAX6902
  "RTC_DRV_PCF2123" = no; # NXP PCF2123
  "RTC_DRV_MCP795" = no; # Microchip MCP795
  "RTC_DRV_DS3232" = no; # Dallas/Maxim DS3232/DS3234
  "RTC_DRV_PCF2127" = no; # NXP PCF2127
  "RTC_DRV_RV3029C2" = no; # Micro Crystal RV3029/3049
  "RTC_DRV_RX6110" = no; # Epson RX-6110
  "RTC_DRV_DS1286" = no; # Dallas DS1286
  "RTC_DRV_DS1511" = no; # Dallas DS1511
  "RTC_DRV_DS1553" = no; # Maxim/Dallas DS1553
  "RTC_DRV_DS1685_FAMILY" = no; # Dallas/Maxim DS1685 Family
  "RTC_DRV_DS1742" = no; # Maxim/Dallas DS1742/1743
  "RTC_DRV_DS2404" = no; # Maxim/Dallas DS2404
  "RTC_DRV_DA9063" = module; # Dialog Semiconductor DA9063/DA9062 RTC
  "RTC_DRV_EFI" = yes; # EFI RTC
  "RTC_DRV_STK17TA8" = no; # Simtek STK17TA8
  "RTC_DRV_M48T86" = no; # ST M48T86/Dallas DS12887
  "RTC_DRV_M48T35" = no; # ST M48T35
  "RTC_DRV_M48T59" = no; # ST M48T59/M48T08/M48T02
  "RTC_DRV_MSM6242" = no; # Oki MSM6242
  "RTC_DRV_RP5C01" = no; # Ricoh RP5C01
  "RTC_DRV_OPTEE" = no; # OP-TEE based RTC driver
  "RTC_DRV_ZYNQMP" = no; # Xilinx Zynq Ultrascale+ MPSoC RTC
  "RTC_DRV_CROS_EC" = yes; # Chrome OS EC RTC driver
  "RTC_DRV_PL030" = no; # ARM AMBA PL030 RTC
  "RTC_DRV_PL031" = no; # ARM AMBA PL031 RTC
  "RTC_DRV_CADENCE" = no; # Cadence RTC driver
  "RTC_DRV_FTRTC010" = no; # Faraday Technology FTRTC010 RTC
  "RTC_DRV_PM8XXX" = module; # Qualcomm PMIC8XXX RTC
  "RTC_DRV_IMX_BBM_SCMI" = yes; # NXP i.MX BBM SCMI RTC support
  "RTC_DRV_R7301" = no; # EPSON TOYOCOM RTC-7301SF/DG
  "RTC_DRV_STM32" = no; # STM32 RTC
  "RTC_DRV_RTD119X" = yes; # Realtek RTD129x RTC
  "RTC_DRV_MA35D1" = no; # Nuvoton MA35D1 RTC
  "RTC_DRV_HID_SENSOR_TIME" = no; # HID Sensor Time
  "RTC_DRV_GOLDFISH" = no; # Goldfish Real Time Clock
  "DMADEVICES" = yes; # DMA Engine support
  "DMADEVICES_DEBUG" = no; # DMA Engine debugging
  "ALTERA_MSGDMA" = no; # Altera / Intel mSGDMA Engine
  "AMBA_PL08X" = no; # ARM PrimeCell PL080 or PL081 support
  "ARM_DMA350" = no; # Arm DMA-350 support
  "BCM_SBA_RAID" = no; # Broadcom SBA RAID engine support
  "DW_AXI_DMAC" = no; # Synopsys DesignWare AXI DMA support
  "FSL_EDMA" = no; # Freescale eDMA engine support
  "FSL_QDMA" = no; # NXP Layerscape qDMA engine support
  "INTEL_IDMA64" = no; # Intel integrated DMA 64-bit support
  "MV_XOR_V2" = no; # Marvell XOR engine version 2 support
  "PL330_DMA" = no; # DMA API Driver for PL330
  "PLX_DMA" = no; # PLX ExpressLane PEX Switch DMA Engine Support
  "XILINX_DMA" = no; # Xilinx AXI DMAS Engine
  "XILINX_XDMA" = no; # Xilinx DMA/Bridge Subsystem DMA Engine
  "XILINX_ZYNQMP_DMA" = no; # Xilinx ZynqMP DMA Engine
  "XILINX_ZYNQMP_DPDMA" = no; # Xilinx DPDMA Engine
  "AMD_QDMA" = no; # AMD Queue-based DMA
  "QCOM_BAM_DMA" = yes; # QCOM BAM DMA support
  "QCOM_GPI_DMA" = module; # Qualcomm Technologies GPI DMA support
  "QCOM_HIDMA_MGMT" = yes; # Qualcomm Technologies HIDMA Management support
  "QCOM_HIDMA" = yes; # Qualcomm Technologies HIDMA Channel support
  "DW_DMAC" = no; # Synopsys DesignWare AHB DMA platform driver
  "DW_DMAC_PCI" = no; # Synopsys DesignWare AHB DMA PCI driver
  "DW_EDMA" = module; # Synopsys DesignWare eDMA controller driver
  "DW_EDMA_PCIE" = no; # Synopsys DesignWare eDMA PCIe driver
  "SF_PDMA" = no; # Sifive PDMA controller driver
  "STM32_DMA" = no; # STMicroelectronics STM32 DMA support
  "STM32_MDMA" = no; # STMicroelectronics STM32 master DMA support
  "STM32_DMA3" = no; # STMicroelectronics STM32 DMA3 support
  "ASYNC_TX_DMA" = no; # Async_tx: Offload support for the async_tx api
  "DMATEST" = no; # DMA Test client

  ### Device Drivers -> DMABUF options
  "SYNC_FILE" = yes; # Explicit Synchronization Framework
  "SW_SYNC" = no; # Sync File Validation Framework
  "UDMABUF" = yes; # userspace dmabuf misc driver
  "DMABUF_MOVE_NOTIFY" = no; # Move notify between drivers (EXPERIMENTAL)
  "DMABUF_DEBUG" = no; # DMA-BUF debug checks
  "DMABUF_SELFTESTS" = no; # Selftests for the dma-buf interfaces
  "DMABUF_HEAPS" = yes; # DMA-BUF Userland Memory Heaps
  "DMABUF_SYSFS_STATS" = no; # DMA-BUF sysfs statistics (DEPRECATED)
  "DMABUF_HEAPS_SYSTEM" = yes; # DMA-BUF System Heap
  "DMABUF_HEAPS_CMA" = yes; # DMA-BUF CMA Heap
  ### Device Drivers: end of DMABUF options

  "UIO" = no; # Userspace I/O drivers
  "VFIO" = yes; # VFIO Non-Privileged userspace driver framework
  "VFIO_GROUP" = yes; # Support for the VFIO group /dev/vfio/$group_id
  "VFIO_CONTAINER" = yes; # Support for the VFIO container /dev/vfio/vfio
  "VFIO_NOIOMMU" = no; # VFIO No-IOMMU support
  "VFIO_DEBUGFS" = no; # Export VFIO internals in DebugFS

  #### VFIO support for PCI devices
  "VFIO_PCI" = yes; # Generic VFIO support for any PCI device
  "HISI_ACC_VFIO_PCI" = no; # VFIO support for HiSilicon ACC PCI devices
  "VIRTIO_VFIO_PCI" = no; # VFIO support for VIRTIO PCI VF devices
  "NVGRACE_GPU_VFIO_PCI" = no; # VFIO support for the GPU in the NVIDIA Grace Hopper Superchip
  #### end of VFIO support for PCI devices

  #### VFIO support for platform devices
  "VFIO_PLATFORM" = no; # Generic VFIO support for any platform device
  "VFIO_AMBA" = no; # VFIO support for AMBA devices
  #### end of VFIO support for platform devices

  "VIRT_DRIVERS" = no; # Virtualization drivers
  "VIRTIO_MENU" = yes; # Virtio drivers
  "VIRTIO_PCI" = yes; # PCI driver for virtio devices
  "VIRTIO_PCI_LEGACY" = yes; # Support for legacy virtio draft 0.9.X and older devices
  "VIRTIO_BALLOON" = yes; # Virtio balloon driver
  "VIRTIO_INPUT" = no; # Virtio input driver
  "VIRTIO_MMIO" = yes; # Platform bus driver for memory mapped virtio devices
  "VIRTIO_MMIO_CMDLINE_DEVICES" = no; # Memory mapped virtio devices parameter parsing
  "VIRTIO_DEBUG" = no; # Debug facilities
  "VIRTIO_RTC" = no; # Virtio RTC driver
  "VDPA" = no; # vDPA drivers
  "VHOST_MENU" = yes; # VHOST drivers
  "VHOST_NET" = no; # Host kernel accelerator for virtio net
  "VHOST_CROSS_ENDIAN_LEGACY" = no; # Cross-endian support for vhost

  ### Device Drivers -> Microsoft Hyper-V guest support
  "HYPERV" = no; # Microsoft Hyper-V client drivers
  ### Device Drivers: end of Microsoft Hyper-V guest support

  ### Device Drivers -> Xen driver support
  "XEN_BALLOON" = yes; # Xen memory balloon driver
  "XEN_SCRUB_PAGES_DEFAULT" = yes; # Scrub pages before returning them to system by default
  "XEN_DEV_EVTCHN" = yes; # Xen /dev/xen/evtchn device
  "XEN_BACKEND" = yes; # Backend driver support
  "XENFS" = yes; # Xen filesystem
  "XEN_COMPAT_XENFS" = yes; # Create compatibility mount point /proc/xen
  "XEN_SYS_HYPERVISOR" = yes; # Create xen entries under /sys/hypervisor
  "XEN_GNTDEV" = yes; # userspace grant access device driver
  "XEN_GRANT_DEV_ALLOC" = yes; # User-space grant reference allocator driver
  "XEN_GRANT_DMA_ALLOC" = no; # Allow allocating DMA capable buffers with grant reference module
  "XEN_PCIDEV_STUB" = module; # Xen PCI-device stub driver
  "XEN_PVCALLS_FRONTEND" = no; # XEN PV Calls frontend driver
  "XEN_PVCALLS_BACKEND" = no; # XEN PV Calls backend driver
  "XEN_PRIVCMD" = yes; # Xen hypercall passthrough driver
  "XEN_VIRTIO" = no; # Xen virtio support
  ### Device Drivers: end of Xen driver support

  "GREYBUS" = module; # Greybus support
  "GREYBUS_BEAGLEPLAY" = module; # Greybus BeaglePlay driver
  "GREYBUS_ES2" = no; # Greybus ES3 USB host controller
  "COMEDI" = no; # Data acquisition support (comedi)
  "STAGING" = yes; # Staging drivers
  "RTL8723BS" = no; # Realtek RTL8723BS SDIO Wireless LAN NIC driver

  #### IIO staging drivers

  ##### IIO staging drivers -> Accelerometers
  "ADIS16203" = no; # Analog Devices ADIS16203 Programmable 360 Degrees Inclinometer
  ##### IIO staging drivers: end of Accelerometers

  ##### IIO staging drivers -> Analog to digital converters
  "AD7816" = no; # Analog Devices AD7816/7/8 temperature sensor and ADC driver
  ##### IIO staging drivers: end of Analog to digital converters

  ##### IIO staging drivers -> Analog digital bi-direction converters
  "ADT7316" = no; # Analog Devices ADT7316/7/8 ADT7516/7/9 temperature sensor, ADC and DAC driver
  ##### IIO staging drivers: end of Analog digital bi-direction converters

  ##### IIO staging drivers -> Direct Digital Synthesis
  "AD9832" = no; # Analog Devices ad9832/5 driver
  "AD9834" = no; # Analog Devices AD9833/4/7/8 driver
  ##### IIO staging drivers: end of Direct Digital Synthesis

  ##### IIO staging drivers -> Network Analyzer, Impedance Converters
  "AD5933" = no; # Analog Devices AD5933, AD5934 driver
  ##### IIO staging drivers: end of Network Analyzer, Impedance Converters
  #### end of IIO staging drivers

  "FB_SM750" = no; # Silicon Motion SM750 framebuffer support
  "STAGING_MEDIA" = yes; # Media staging drivers
  "VIDEO_MAX96712" = module; # Maxim MAX96712 Quad GMSL2 Deserializer support
  "STAGING_MEDIA_DEPRECATED" = no; # Media staging drivers (DEPRECATED)
  "FB_TFT" = no; # Support for small TFT LCD display modules
  "GREYBUS_AUDIO" = no; # Greybus Audio Class driver
  "GREYBUS_BOOTROM" = no; # Greybus Bootrom Class driver
  "GREYBUS_FIRMWARE" = no; # Greybus Firmware Download Class driver
  "GREYBUS_HID" = no; # Greybus HID Class driver
  "GREYBUS_LIGHT" = no; # Greybus LED Class driver
  "GREYBUS_LOG" = no; # Greybus Debug Log Class driver
  "GREYBUS_LOOPBACK" = no; # Greybus Loopback Class driver
  "GREYBUS_POWER" = no; # Greybus Powersupply Class driver
  "GREYBUS_RAW" = no; # Greybus Raw Class driver
  "GREYBUS_VIBRATOR" = no; # Greybus Vibrator Motor Class driver
  "GREYBUS_BRIDGED_PHY" = no; # Greybus Bridged PHY Class drivers
  "XIL_AXIS_FIFO" = no; # Xilinx AXI-Stream FIFO IP core driver
  "VME_BUS" = no; # VME bridge support
  "GPIB" = no; # Linux GPIB drivers
  "GOLDFISH" = no; # Platform support for Goldfish virtual devices
  "CHROME_PLATFORMS" = yes; # Platform support for Chrome hardware
  "CHROMEOS_ACPI" = no; # ChromeOS specific ACPI extensions
  "CHROMEOS_TBMC" = no; # ChromeOS Tablet Switch Controller
  "CHROMEOS_OF_HW_PROBER" = yes; # ChromeOS Device Tree Hardware Prober
  "CROS_EC" = yes; # ChromeOS Embedded Controller
  "CROS_EC_I2C" = yes; # ChromeOS Embedded Controller (I2C)
  "CROS_EC_RPMSG" = module; # ChromeOS Embedded Controller (rpmsg)
  "CROS_EC_SPI" = yes; # ChromeOS Embedded Controller (SPI)
  "CROS_EC_UART" = no; # ChromeOS Embedded Controller (UART)
  "CROS_KBD_LED_BACKLIGHT" = module; # Backlight LED support for Chrome OS keyboards
  "CROS_EC_CHARDEV" = module; # ChromeOS EC miscdevice
  "CROS_EC_LIGHTBAR" = yes; # Chromebook Pixel's lightbar support
  "CROS_EC_VBC" = yes; # ChromeOS EC vboot context support
  "CROS_EC_DEBUGFS" = yes; # Export ChromeOS EC internals in DebugFS
  "CROS_EC_SENSORHUB" = yes; # ChromeOS EC MEMS Sensor Hub
  "CROS_EC_SYSFS" = yes; # ChromeOS EC control and information through sysfs
  "CROS_EC_TYPEC" = module; # ChromeOS EC Type-C Connector Control
  "CROS_HPS_I2C" = no; # ChromeOS HPS device
  "CROS_USBPD_NOTIFY" = yes; # ChromeOS Type-C power delivery event notifier
  "CHROMEOS_PRIVACY_SCREEN" = no; # ChromeOS Privacy Screen support
  "CROS_TYPEC_SWITCH" = module; # ChromeOS EC Type-C Switch Control
  "MELLANOX_PLATFORM" = no; # Platform support for Mellanox hardware
  "SURFACE_PLATFORMS" = no; # Microsoft Surface Platform-Specific Device Drivers
  "ARM64_PLATFORM_DEVICES" = yes; # ARM64 Platform-Specific Device Drivers
  "EC_ACER_ASPIRE1" = no; # Acer Aspire 1 Embedded Controller driver
  "EC_HUAWEI_GAOKUN" = no; # Huawei Matebook E Go Embedded Controller driver
  "EC_LENOVO_YOGA_C630" = module; # Lenovo Yoga C630 Embedded Controller driver
  "COMMON_CLK" = yes; # Common Clock Framework

  #### Clock driver for ARM Reference designs
  "CLK_ICST" = no; # Clock driver for ARM Reference designs ICST
  "CLK_SP810" = no; # Clock driver for ARM SP810 System Controller
  "CLK_VEXPRESS_OSC" = yes; # Clock driver for Versatile Express OSC clock generators
  #### end of Clock driver for ARM Reference designs

  "LMK04832" = no; # Ti LMK04832 JESD204B Compliant Clock Jitter Cleaner
  "COMMON_CLK_MAX9485" = no; # Maxim 9485 Programmable Clock Generator
  "COMMON_CLK_RK808" = no; # Clock driver for RK805/RK808/RK809/RK817/RK818
  "COMMON_CLK_SCMI" = yes; # Clock driver controlled via SCMI interface
  "COMMON_CLK_SCPI" = yes; # Clock driver controlled via SCPI interface
  "COMMON_CLK_SI5341" = no; # Clock driver for SiLabs 5341 and 5340 A/B/C/D devices
  "COMMON_CLK_SI5351" = no; # Clock driver for SiLabs 5351A/B/C
  "COMMON_CLK_SI514" = no; # Clock driver for SiLabs 514 devices
  "COMMON_CLK_SI544" = no; # Clock driver for SiLabs 544 devices
  "COMMON_CLK_SI570" = no; # Clock driver for SiLabs 570 and compatible devices
  "COMMON_CLK_CDCE706" = no; # Clock driver for TI CDCE706 clock synthesizer
  "COMMON_CLK_CDCE925" = no; # Clock driver for TI CDCE913/925/937/949 devices
  "COMMON_CLK_CS2000_CP" = no; # Clock driver for CS2000 Fractional-N Clock Synthesizer & Clock Multiplier
  "COMMON_CLK_EN7523" = yes; # Clock driver for Airoha EN7523 SoC system clocks
  "COMMON_CLK_S2MPS11" = no; # Clock driver for S2MPS1X/S5M8767 MFD
  "COMMON_CLK_AXI_CLKGEN" = no; # AXI clkgen driver
  "COMMON_CLK_XGENE" = no; # Clock driver for APM XGene SoC
  "COMMON_CLK_PWM" = yes; # Clock driver for PWMs used as clock outputs
  "COMMON_CLK_RS9_PCIE" = yes; # Clock driver for Renesas 9-series PCIe clock generators
  "COMMON_CLK_SI521XX" = no; # Clock driver for SkyWorks Si521xx PCIe clock generators
  "COMMON_CLK_VC3" = yes; # Clock driver for Renesas VersaClock 3 devices
  "COMMON_CLK_VC5" = no; # Clock driver for IDT VersaClock 5,6 devices
  "COMMON_CLK_VC7" = no; # Clock driver for Renesas Versaclock 7 devices
  "COMMON_CLK_FIXED_MMIO" = no; # Clock driver for Memory Mapped Fixed values
  "COMMON_CLK_NUVOTON" = yes; # Nuvoton clock controller common support
  "CLK_MA35D1" = yes; # Nuvoton MA35D1 clock controller support
  "COMMON_CLK_QCOM" = yes; # Support for Qualcomm's clock controllers
  "CLK_X1E80100_CAMCC" = module; # X1E80100 Camera Clock Controller
  "CLK_X1E80100_DISPCC" = module; # X1E80100 Display Clock Controller
  "CLK_X1E80100_GCC" = yes; # X1E80100 Global Clock Controller
  "CLK_X1E80100_GPUCC" = module; # X1E80100 Graphics Clock Controller
  "CLK_X1E80100_TCSRCC" = yes; # X1E80100 TCSR Clock Controller
  "CLK_X1P42100_GPUCC" = no; # X1P42100 Graphics Clock Controller
  "CLK_QCM2290_GPUCC" = module; # QCM2290 Graphics Clock Controller
  "QCOM_A53PLL" = yes; # MSM8916 A53 PLL
  "QCOM_A7PLL" = no; # A7 PLL driver for SDX55 and SDX65
  "QCOM_CLK_APCS_MSM8916" = yes; # MSM8916 APCS Clock Controller
  "QCOM_CLK_APCC_MSM8996" = yes; # MSM8996 CPU Clock Controller
  "QCOM_CLK_RPM" = no; # RPM based Clock Controller
  "QCOM_CLK_SMD_RPM" = yes; # RPM over SMD based Clock Controller
  "QCOM_CLK_RPMH" = yes; # RPMh Clock Driver
  "IPQ_APSS_PLL" = yes; # IPQ APSS PLL
  "IPQ_APSS_6018" = yes; # IPQ APSS Clock Controller
  "IPQ_CMN_PLL" = module; # IPQ CMN PLL Clock Controller
  "IPQ_GCC_4019" = no; # IPQ4019 Global Clock Controller
  "IPQ_GCC_5018" = yes; # IPQ5018 Global Clock Controller
  "IPQ_GCC_5332" = yes; # IPQ5332 Global Clock Controller
  "IPQ_GCC_5424" = yes; # IPQ5424 Global Clock Controller
  "IPQ_GCC_6018" = yes; # IPQ6018 Global Clock Controller
  "IPQ_GCC_8074" = yes; # IPQ8074 Global Clock Controller
  "IPQ_GCC_9574" = yes; # IPQ9574 Global Clock Controller
  "IPQ_NSSCC_9574" = module; # IPQ9574 NSS Clock Controller
  "IPQ_NSSCC_QCA8K" = no; # QCA8K(QCA8386 or QCA8084) NSS Clock Controller
  "MSM_GCC_8916" = yes; # MSM8916 Global Clock Controller
  "MSM_GCC_8917" = no; # MSM8917/QM215 Global Clock Controller
  "MSM_GCC_8939" = no; # MSM8939 Global Clock Controller
  "MSM_GCC_8953" = no; # MSM8953 Global Clock Controller
  "MSM_GCC_8976" = no; # MSM8956/76 Global Clock Controller
  "MSM_MMCC_8994" = module; # MSM8994 Multimedia Clock Controller
  "MSM_GCC_8994" = yes; # MSM8994 Global Clock Controller
  "MSM_GCC_8996" = yes; # MSM8996 Global Clock Controller
  "MSM_MMCC_8996" = module; # MSM8996 Multimedia Clock Controller
  "MSM_GCC_8998" = yes; # MSM8998 Global Clock Controller
  "MSM_GPUCC_8998" = no; # MSM8998 Graphics Clock Controller
  "MSM_MMCC_8998" = module; # MSM8998 Multimedia Clock Controller
  "QCM_GCC_2290" = yes; # QCM2290 Global Clock Controller
  "QCM_DISPCC_2290" = module; # QCM2290 Display Clock Controller
  "QCS_GCC_404" = yes; # QCS404 Global Clock Controller
  "SA_CAMCC_8775P" = module; # SA8775P Camera Clock Controller
  "QCS_GCC_8300" = yes; # QCS8300 Global Clock Controller
  "QCS_GCC_615" = yes; # QCS615 Global Clock Controller
  "SC_CAMCC_7180" = no; # SC7180 Camera Clock Controller
  "SC_CAMCC_7280" = module; # SC7280 Camera Clock Controller
  "SC_CAMCC_8280XP" = module; # SC8280XP Camera Clock Controller
  "SA_DISPCC_8775P" = module; # SA8775P Display Clock Controller
  "SC_DISPCC_7180" = no; # SC7180 Display Clock Controller
  "SC_DISPCC_7280" = module; # SC7280 Display Clock Controller
  "SC_DISPCC_8280XP" = module; # SC8280XP Display Clock Controller
  "SA_GCC_8775P" = yes; # SA8775 Global Clock Controller
  "SA_GPUCC_8775P" = module; # SA8775P Graphics clock controller
  "SAR_GCC_2130P" = no; # SAR2130P Global Clock Controller
  "SAR_GPUCC_2130P" = no; # SAR2130P Graphics clock controller
  "SC_GCC_7180" = yes; # SC7180 Global Clock Controller
  "SC_GCC_7280" = yes; # SC7280 Global Clock Controller
  "SC_GCC_8180X" = yes; # SC8180X Global Clock Controller
  "SC_GCC_8280XP" = module; # SC8280XP Global Clock Controller
  "SC_GPUCC_7180" = no; # SC7180 Graphics Clock Controller
  "SC_GPUCC_7280" = module; # SC7280 Graphics Clock Controller
  "SC_GPUCC_8280XP" = module; # SC8280XP Graphics Clock Controller
  "SC_LPASSCC_7280" = no; # SC7280 Low Power Audio Subsystem (LPASS) Clock Controller
  "SC_LPASSCC_8280XP" = module; # SC8280 Low Power Audio Subsystem (LPASS) Clock Controller
  "SC_LPASS_CORECC_7180" = no; # SC7180 LPASS Core Clock Controller
  "SC_LPASS_CORECC_7280" = module; # SC7280 LPASS Core & Audio Clock Controller
  "SC_VIDEOCC_7180" = no; # SC7180 Video Clock Controller
  "SC_VIDEOCC_7280" = module; # SC7280 Video Clock Controller
  "SDM_CAMCC_845" = module; # SDM845 Camera Clock Controller
  "SDM_GCC_660" = no; # SDM660 Global Clock Controller
  "SDM_MMCC_660" = no; # SDM660 Multimedia Clock Controller
  "SDM_GPUCC_660" = no; # SDM660 Graphics Clock Controller
  "QCS_TURING_404" = no; # QCS404 Turing Clock Controller
  "QCS_Q6SSTOP_404" = no; # QCS404 Q6SSTOP Clock Controller
  "QDU_GCC_1000" = yes; # QDU1000/QRU1000 Global Clock Controller
  "QDU_ECPRICC_1000" = no; # QDU1000/QRU1000 ECPRI Clock Controller
  "SDM_GCC_845" = yes; # SDM845/SDM670 Global Clock Controller
  "SDM_GPUCC_845" = yes; # SDM845 Graphics Clock Controller
  "SDM_VIDEOCC_845" = yes; # SDM845 Video Clock Controller
  "SDM_DISPCC_845" = yes; # SDM845 Display Clock Controller
  "SDM_LPASSCC_845" = module; # SDM845 Low Power Audio Subsystem (LPAAS) Clock Controller
  "SDX_GCC_75" = yes; # SDX75 Global Clock Controller
  "SM_CAMCC_4450" = no; # SM4450 Camera Clock Controller
  "SM_CAMCC_6350" = no; # SM6350 Camera Clock Controller
  "SM_CAMCC_7150" = no; # SM7150 Camera Clock Controller
  "SM_CAMCC_8150" = no; # SM8150 Camera Clock Controller
  "SM_CAMCC_8250" = module; # SM8250 Camera Clock Controller
  "SM_CAMCC_8450" = no; # SM8450 Camera Clock Controller
  "SM_CAMCC_8550" = no; # SM8550 Camera Clock Controller
  "SM_CAMCC_8650" = no; # SM8650 Camera Clock Controller
  "SM_DISPCC_4450" = no; # SM4450 Display Clock Controller
  "SM_DISPCC_6115" = yes; # SM6115 Display Clock Controller
  "SM_DISPCC_8250" = yes; # SM8150/SM8250/SM8350 Display Clock Controller
  "SM_DISPCC_8450" = module; # SM8450 Display Clock Controller
  "SM_DISPCC_8550" = module; # SM8550 Display Clock Controller
  "SM_DISPCC_8750" = module; # SM8750 Display Clock Controller
  "SM_GCC_4450" = yes; # SM4450 Global Clock Controller
  "SM_GCC_6115" = yes; # SM6115 and SM4250 Global Clock Controller
  "SM_GCC_6125" = no; # SM6125 Global Clock Controller
  "SM_GCC_6350" = no; # SM6350 Global Clock Controller
  "SM_GCC_6375" = no; # SM6375 Global Clock Controller
  "SM_GCC_7150" = no; # SM7150 Global Clock Controller
  "SM_GCC_8150" = yes; # SM8150 Global Clock Controller
  "SM_GCC_8250" = yes; # SM8250 Global Clock Controller
  "SM_GCC_8350" = yes; # SM8350 Global Clock Controller
  "SM_GCC_8450" = yes; # SM8450 Global Clock Controller
  "SM_GCC_8550" = yes; # SM8550 Global Clock Controller
  "SM_GCC_8650" = yes; # SM8650 Global Clock Controller
  "SM_GCC_8750" = yes; # SM8750 Global Clock Controller
  "SM_GPUCC_4450" = no; # SM4450 Graphics Clock Controller
  "SM_GPUCC_6115" = yes; # SM6115 Graphics Clock Controller
  "SM_GPUCC_6125" = no; # SM6125 Graphics Clock Controller
  "SM_GPUCC_6375" = no; # SM6375 Graphics Clock Controller
  "SM_GPUCC_6350" = no; # SM6350 Graphics Clock Controller
  "SM_GPUCC_8150" = yes; # SM8150 Graphics Clock Controller
  "SM_GPUCC_8250" = yes; # SM8250 Graphics Clock Controller
  "SM_GPUCC_8350" = module; # SM8350 Graphics Clock Controller
  "SM_GPUCC_8450" = module; # SM8450 Graphics Clock Controller
  "SM_GPUCC_8550" = module; # SM8550 Graphics Clock Controller
  "SM_GPUCC_8650" = module; # SM8650 Graphics Clock Controller
  "SM_LPASSCC_6115" = no; # SM6115 Low Power Audio Subsystem (LPASS) Clock Controller
  "SM_TCSRCC_8550" = yes; # SM8550 TCSR Clock Controller
  "SM_TCSRCC_8650" = yes; # SM8650 TCSR Clock Controller
  "SM_TCSRCC_8750" = module; # SM8750 TCSR Clock Controller
  "SA_VIDEOCC_8775P" = module; # SA8775P Video Clock Controller
  "SM_VIDEOCC_7150" = no; # SM7150 Video Clock Controller
  "SM_VIDEOCC_8150" = no; # SM8150 Video Clock Controller
  "SM_VIDEOCC_8250" = yes; # SM8250 Video Clock Controller
  "SM_VIDEOCC_8350" = no; # SM8350 Video Clock Controller
  "SM_VIDEOCC_8550" = module; # SM8550 Video Clock Controller
  "SPMI_PMIC_CLKDIV" = no; # SPMI PMIC clkdiv Support
  "QCOM_HFPLL" = yes; # High-Frequency PLL (HFPLL) Clock Controller
  "KPSS_XCC" = no; # KPSS Clock Controller
  "CLK_GFM_LPASS_SM8250" = module; # SM8250 GFM LPASS Clocks
  "SM_VIDEOCC_8450" = no; # SM8450 Video Clock Controller
  "COMMON_CLK_STM32MP" = yes; # Clock support for common STM32MP clocks
  "COMMON_CLK_STM32MP257" = yes; # Clock driver for stm32mp25x clocks
  "XILINX_VCU" = no; # Xilinx VCU logicoreIP Init
  "COMMON_CLK_XLNX_CLKWZRD" = no; # Xilinx Clocking Wizard
  "HWSPINLOCK" = yes; # Hardware Spinlock drivers
  "HWSPINLOCK_QCOM" = yes; # Qualcomm Hardware Spinlock device

  ### Device Drivers -> Clock Source drivers
  "CLKSRC_STM32_LP" = yes; # Low power clocksource for STM32 SoCs
  "ARM_ARCH_TIMER_EVTSTREAM" = yes; # Enable ARM architected timer event stream generation by default
  "FSL_ERRATUM_A008585" = yes; # Workaround for Freescale/NXP Erratum A-008585
  "HISILICON_ERRATUM_161010101" = yes; # Workaround for Hisilicon Erratum 161010101
  "ARM64_ERRATUM_858921" = yes; # Workaround for Cortex-A73 erratum 858921
  "ARM_TIMER_SP804" = yes; # Support for Dual Timer SP804 module
  ### Device Drivers: end of Clock Source drivers

  "MAILBOX" = yes; # Mailbox Hardware Support
  "ARM_MHU" = yes; # ARM MHU Mailbox
  "ARM_MHU_V2" = no; # ARM MHUv2 Mailbox
  "ARM_MHU_V3" = no; # ARM MHUv3 Mailbox
  "PLATFORM_MHU" = yes; # Platform MHU Mailbox
  "PL320_MBOX" = no; # ARM PL320 Mailbox
  "PCC" = yes; # Platform Communication Channel Driver
  "ALTERA_MBOX" = no; # Altera Mailbox
  "MAILBOX_TEST" = no; # Mailbox Test Client
  "QCOM_APCS_IPC" = yes; # Qualcomm APCS IPC driver
  "QCOM_CPUCP_MBOX" = no; # Qualcomm Technologies, Inc. CPUCP mailbox driver
  "QCOM_IPCC" = yes; # Qualcomm Technologies, Inc. IPCC driver
  "IOMMU_SUPPORT" = yes; # IOMMU Hardware Support

  #### Generic IOMMU Pagetable Support
  "IOMMU_IO_PGTABLE_LPAE" = yes; # ARMv7/v8 Long Descriptor Format
  "IOMMU_IO_PGTABLE_LPAE_SELFTEST" = no; # LPAE selftests
  "IOMMU_IO_PGTABLE_ARMV7S" = yes; # ARMv7/v8 Short Descriptor Format
  "IOMMU_IO_PGTABLE_ARMV7S_SELFTEST" = no; # ARMv7s selftests
  "IOMMU_IO_PGTABLE_DART" = no; # Apple DART Formats
  #### end of Generic IOMMU Pagetable Support

  "IOMMU_DEBUGFS" = no; # Export IOMMU internals in DebugFS
  "IOMMU_DEFAULT_DMA_STRICT" = yes; # Translated - Strict
  "IOMMU_DEFAULT_DMA_LAZY" = no; # Translated - Lazy
  "IOMMU_DEFAULT_PASSTHROUGH" = no; # Passthrough
  "ARM_SMMU" = yes; # ARM Ltd. System MMU (SMMU) Support
  "ARM_SMMU_LEGACY_DT_BINDINGS" = no; # Support the legacy "mmu-masters" devicetree bindings
  "ARM_SMMU_MMU_500_CPRE_ERRATA" = yes; # Enable errata workaround for CPRE in SMMU reset path
  "ARM_SMMU_QCOM_DEBUG" = no; # ARM SMMU QCOM implementation defined debug support
  "ARM_SMMU_V3" = yes; # ARM Ltd. System MMU Version 3 (SMMUv3) Support
  "ARM_SMMU_V3_SVA" = no; # Shared Virtual Addressing support for the ARM SMMUv3
  "TEGRA241_CMDQV" = no; # NVIDIA Tegra241 CMDQ-V extension support for ARM SMMUv3
  "QCOM_IOMMU" = yes; # Qualcomm IOMMU Support
  "IOMMUFD" = no; # IOMMU Userspace API
  "VIRTIO_IOMMU" = no; # Virtio IOMMU driver

  ### Device Drivers -> Remoteproc drivers
  "REMOTEPROC" = yes; # Support for Remote Processor subsystem
  "REMOTEPROC_CDEV" = yes; # Remoteproc character device interface
  "QCOM_Q6V5_ADSP" = module; # Qualcomm Technology Inc ADSP Peripheral Image Loader
  "QCOM_Q6V5_MSS" = module; # Qualcomm Hexagon V5 self-authenticating modem subsystem support
  "QCOM_Q6V5_PAS" = module; # Qualcomm Hexagon v5 Peripheral Authentication Service support
  "QCOM_Q6V5_WCSS" = no; # Qualcomm Hexagon based WCSS Peripheral Image Loader
  "QCOM_SYSMON" = module; # Qualcomm sysmon driver
  "QCOM_WCNSS_PIL" = module; # Qualcomm WCNSS Peripheral Image Loader
  "STM32_RPROC" = no; # STM32 remoteproc support
  ### Device Drivers: end of Remoteproc drivers

  ### Device Drivers -> Rpmsg drivers
  "RPMSG_CHAR" = yes; # RPMSG device interface
  "RPMSG_CTRL" = module; # RPMSG control interface
  "RPMSG_NS" = yes; # RPMSG name service announcement
  "RPMSG_QCOM_GLINK_RPM" = yes; # Qualcomm RPM Glink driver
  "RPMSG_QCOM_GLINK_SMEM" = module; # Qualcomm SMEM Glink driver
  "RPMSG_QCOM_SMD" = yes; # Qualcomm Shared Memory Driver (SMD)
  "RPMSG_VIRTIO" = yes; # Virtio RPMSG bus driver
  ### Device Drivers: end of Rpmsg drivers

  "SOUNDWIRE" = module; # SoundWire support
  "SOUNDWIRE_AMD" = no; # AMD SoundWire Manager driver
  "SOUNDWIRE_INTEL" = no; # Intel SoundWire Master driver
  "SOUNDWIRE_QCOM" = module; # Qualcomm SoundWire Master driver

  ### Device Drivers -> SOC (System On Chip) specific Drivers

  #### Device Drivers -> SOC (System On Chip) specific Drivers -> NXP/Freescale QorIQ SoC drivers
  "QUICC_ENGINE" = no; # QUICC Engine (QE) framework support
  "FSL_RCPM" = no; # Freescale RCPM support
  #### Device Drivers -> SOC (System On Chip) specific Drivers: end of NXP/Freescale QorIQ SoC drivers

  #### Device Drivers -> SOC (System On Chip) specific Drivers -> fujitsu SoC drivers
  "A64FX_DIAG" = no; # A64FX diag driver
  #### Device Drivers -> SOC (System On Chip) specific Drivers: end of fujitsu SoC drivers

  #### Device Drivers -> SOC (System On Chip) specific Drivers -> Enable LiteX SoC Builder specific drivers
  "LITEX_SOC_CONTROLLER" = no; # Enable LiteX SoC Controller driver
  #### Device Drivers -> SOC (System On Chip) specific Drivers: end of Enable LiteX SoC Builder specific drivers

  "WPCM450_SOC" = no; # Nuvoton WPCM450 SoC driver

  #### Device Drivers -> SOC (System On Chip) specific Drivers -> Qualcomm SoC drivers
  "QCOM_AOSS_QMP" = yes; # Qualcomm AOSS Driver
  "QCOM_COMMAND_DB" = yes; # Qualcomm Command DB
  "QCOM_GENI_SE" = yes; # QCOM GENI Serial Engine Driver
  "QCOM_GSBI" = yes; # QCOM General Serial Bus Interface
  "QCOM_LLCC" = yes; # Qualcomm Technologies, Inc. LLCC driver
  "QCOM_OCMEM" = yes; # Qualcomm On Chip Memory (OCMEM) driver
  "QCOM_PD_MAPPER" = no; # Qualcomm Protection Domain Mapper
  "QCOM_PMIC_PDCHARGER_ULOG" = no; # Qualcomm PMIC PDCharger ULOG driver
  "QCOM_PMIC_GLINK" = module; # Qualcomm PMIC GLINK driver
  "QCOM_RAMP_CTRL" = no; # Qualcomm Ramp Controller driver
  "QCOM_RMTFS_MEM" = yes; # Qualcomm Remote Filesystem memory driver
  "QCOM_RPM_MASTER_STATS" = no; # Qualcomm RPM Master stats
  "QCOM_RPMH" = yes; # Qualcomm RPM-Hardened (RPMH) Communication
  "QCOM_SMEM" = yes; # Qualcomm Shared Memory Manager (SMEM)
  "QCOM_SMD_RPM" = yes; # Qualcomm Resource Power Manager (RPM) over SMD
  "QCOM_SMP2P" = yes; # Qualcomm Shared Memory Point to Point support
  "QCOM_SMSM" = yes; # Qualcomm Shared Memory State Machine
  "QCOM_SOCINFO" = yes; # Qualcomm socinfo driver
  "QCOM_SPM" = module; # Qualcomm Subsystem Power Manager (SPM)
  "QCOM_STATS" = module; # Qualcomm Technologies, Inc. (QTI) Sleep stats driver
  "QCOM_WCNSS_CTRL" = yes; # Qualcomm WCNSS control driver
  "QCOM_APR" = yes; # Qualcomm APR/GPR Bus (Asynchronous/Generic Packet Router)
  "QCOM_ICC_BWMON" = module; # QCOM Interconnect Bandwidth Monitor driver
  "QCOM_PBS" = module; # PBS trigger support for Qualcomm Technologies, Inc. PMICS
  #### Device Drivers -> SOC (System On Chip) specific Drivers: end of Qualcomm SoC drivers

  "SOC_TI" = yes; # TI SOC drivers support
  ### Device Drivers: end of SOC (System On Chip) specific Drivers

  ### Device Drivers -> PM Domains
  "ARM_SCMI_PERF_DOMAIN" = yes; # SCMI performance domain driver
  "ARM_SCMI_POWER_DOMAIN" = yes; # SCMI power domain driver
  "ARM_SCPI_POWER_DOMAIN" = yes; # SCPI power domain driver

  #### Device Drivers -> PM Domains -> Qualcomm PM Domains
  "QCOM_CPR" = yes; # QCOM Core Power Reduction (CPR) support
  "QCOM_RPMHPD" = yes; # Qualcomm RPMh Power domain driver
  "QCOM_RPMPD" = yes; # Qualcomm RPM Power domain driver
  #### Device Drivers -> PM Domains: end of Qualcomm PM Domains
  ### Device Drivers: end of PM Domains

  "PM_DEVFREQ" = yes; # Generic Dynamic Voltage and Frequency Scaling (DVFS) support
  "DEVFREQ_GOV_SIMPLE_ONDEMAND" = yes; # Simple Ondemand
  "DEVFREQ_GOV_PERFORMANCE" = no; # Performance
  "DEVFREQ_GOV_POWERSAVE" = no; # Powersave
  "DEVFREQ_GOV_USERSPACE" = yes; # Userspace
  "DEVFREQ_GOV_PASSIVE" = module; # Passive
  "PM_DEVFREQ_EVENT" = no; # DEVFREQ-Event device Support
  "EXTCON" = yes; # External Connector Class (extcon) support
  "EXTCON_ADC_JACK" = no; # ADC Jack extcon support
  "EXTCON_FSA9480" = no; # FSA9480 EXTCON Support
  "EXTCON_GPIO" = no; # GPIO extcon support
  "EXTCON_LC824206XA" = no; # LC824206XA extcon Support
  "EXTCON_MAX3355" = no; # Maxim MAX3355 USB OTG EXTCON Support
  "EXTCON_PTN5150" = no; # NXP PTN5150 CC LOGIC USB EXTCON support
  "EXTCON_QCOM_SPMI_MISC" = no; # Qualcomm USB extcon support
  "EXTCON_RT8973A" = no; # Richtek RT8973A EXTCON support
  "EXTCON_SM5502" = no; # Silicon Mitus SM5502/SM5504/SM5703 EXTCON support
  "EXTCON_USB_GPIO" = yes; # USB GPIO extcon support
  "EXTCON_USBC_CROS_EC" = yes; # ChromeOS Embedded Controller EXTCON support
  "EXTCON_USBC_TUSB320" = no; # TI TUSB320 USB-C extcon support
  "EXTCON_RTK_TYPE_C" = no; # Realtek RTD SoC extcon Type-C Driver
  "MEMORY" = yes; # Memory Controller drivers
  "ARM_PL172_MPMC" = no; # ARM PL172 MPMC driver
  "STM32_FMC2_EBI" = no; # Support for FMC2 External Bus Interface on STM32MP SoCs
  "IIO" = yes; # Industrial I/O support
  "IIO_BUFFER" = yes; # Enable buffer support within IIO
  "IIO_BUFFER_CB" = no; # IIO callback buffer used for push in-kernel interfaces
  "IIO_BUFFER_DMA" = no; # Industrial I/O DMA buffer infrastructure
  "IIO_BUFFER_DMAENGINE" = no; # Industrial I/O DMA buffer integration with DMAEngine
  "IIO_BUFFER_HW_CONSUMER" = no; # Industrial I/O HW buffering
  "IIO_KFIFO_BUF" = module; # Industrial I/O buffering based on kfifo
  "IIO_TRIGGERED_BUFFER" = module; # Industrial I/O triggered buffer support
  "IIO_CONFIGFS" = no; # Enable IIO configuration via configfs
  "IIO_TRIGGER" = yes; # Enable triggered sampling support
  "IIO_CONSUMERS_PER_TRIGGER" = freeform "2"; # Maximum number of consumers per trigger
  "IIO_SW_DEVICE" = no; # Enable software IIO device support
  "IIO_SW_TRIGGER" = no; # Enable software triggers support
  "IIO_TRIGGERED_EVENT" = no; # Enable triggered events support

  #### Accelerometers
  "ADIS16201" = no; # Analog Devices ADIS16201 Dual-Axis Digital Inclinometer and Accelerometer
  "ADIS16209" = no; # Analog Devices ADIS16209 Dual-Axis Digital Inclinometer and Accelerometer
  "ADXL313_I2C" = no; # Analog Devices ADXL313 3-Axis Digital Accelerometer I2C Driver
  "ADXL313_SPI" = no; # Analog Devices ADXL313 3-Axis Digital Accelerometer SPI Driver
  "ADXL345_I2C" = no; # Analog Devices ADXL345 3-Axis Digital Accelerometer I2C Driver
  "ADXL345_SPI" = no; # Analog Devices ADXL345 3-Axis Digital Accelerometer SPI Driver
  "ADXL355_I2C" = no; # Analog Devices ADXL355 3-Axis Digital Accelerometer I2C Driver
  "ADXL355_SPI" = no; # Analog Devices ADXL355 3-Axis Digital Accelerometer SPI Driver
  "ADXL367_SPI" = no; # Analog Devices ADXL367 3-Axis Accelerometer SPI Driver
  "ADXL367_I2C" = no; # Analog Devices ADXL367 3-Axis Accelerometer I2C Driver
  "ADXL372_SPI" = no; # Analog Devices ADXL372 3-Axis Accelerometer SPI Driver
  "ADXL372_I2C" = no; # Analog Devices ADXL372 3-Axis Accelerometer I2C Driver
  "ADXL380_SPI" = no; # Analog Devices ADXL380 3-Axis Accelerometer SPI Driver
  "ADXL380_I2C" = no; # Analog Devices ADXL380 3-Axis Accelerometer I2C Driver
  "BMA180" = no; # Bosch BMA023/BMA1x0/BMA250 3-Axis Accelerometer Driver
  "BMA220" = no; # Bosch BMA220 3-Axis Accelerometer Driver
  "BMA400" = no; # Bosch BMA400 3-Axis Accelerometer Driver
  "BMC150_ACCEL" = no; # Bosch BMC150 Accelerometer Driver
  "BMI088_ACCEL" = no; # Bosch BMI088 Accelerometer Driver
  "DA280" = no; # MiraMEMS DA280 3-axis 14-bit digital accelerometer driver
  "DA311" = no; # MiraMEMS DA311 3-axis 12-bit digital accelerometer driver
  "DMARD06" = no; # Domintech DMARD06 Digital Accelerometer Driver
  "DMARD09" = no; # Domintech DMARD09 3-axis Accelerometer Driver
  "DMARD10" = no; # Domintech DMARD10 3-axis Accelerometer Driver
  "FXLS8962AF_I2C" = no; # NXP FXLS8962AF/FXLS8964AF Accelerometer I2C Driver
  "FXLS8962AF_SPI" = no; # NXP FXLS8962AF/FXLS8964AF Accelerometer SPI Driver
  "HID_SENSOR_ACCEL_3D" = module; # HID Accelerometers 3D
  "IIO_CROS_EC_ACCEL_LEGACY" = no; # ChromeOS EC Legacy Accelerometer Sensor
  "IIO_ST_ACCEL_3AXIS" = no; # STMicroelectronics accelerometers 3-Axis Driver
  "IIO_KX022A_SPI" = no; # Kionix KX022A tri-axis digital accelerometer SPI interface
  "IIO_KX022A_I2C" = no; # Kionix KX022A tri-axis digital accelerometer I2C interface
  "KXSD9" = no; # Kionix KXSD9 Accelerometer Driver
  "KXCJK1013" = no; # Kionix 3-Axis Accelerometer Driver
  "MC3230" = no; # mCube MC3230 Digital Accelerometer Driver
  "MMA7455_I2C" = no; # Freescale MMA7455L/MMA7456L Accelerometer I2C Driver
  "MMA7455_SPI" = no; # Freescale MMA7455L/MMA7456L Accelerometer SPI Driver
  "MMA7660" = no; # Freescale MMA7660FC 3-Axis Accelerometer Driver
  "MMA8452" = no; # Freescale / NXP MMA8452Q and similar Accelerometers Driver
  "MMA9551" = no; # Freescale MMA9551L Intelligent Motion-Sensing Platform Driver
  "MMA9553" = no; # Freescale MMA9553L Intelligent Pedometer Platform Driver
  "MSA311" = no; # MEMSensing Digital 3-Axis Accelerometer Driver
  "MXC4005" = no; # Memsic MXC4005XC 3-Axis Accelerometer Driver
  "MXC6255" = no; # Memsic MXC6255 Orientation Sensing Accelerometer Driver
  "SCA3000" = no; # VTI SCA3000 series accelerometers
  "SCA3300" = no; # Murata SCA3300 3-Axis Accelerometer Driver
  "STK8312" = no; # Sensortek STK8312 3-Axis Accelerometer Driver
  "STK8BA50" = no; # Sensortek STK8BA50 3-Axis Accelerometer Driver
  #### end of Accelerometers

  #### Analog to digital converters
  "AD4000" = no; # Analog Devices AD4000 ADC Driver
  "AD4030" = no; # Analog Devices AD4030 ADC Driver
  "AD4130" = no; # Analog Device AD4130 ADC Driver
  "AD4695" = no; # Analog Device AD4695 ADC Driver
  "AD4851" = no; # Analog Device AD4851 DAS Driver
  "AD7091R5" = no; # Analog Devices AD7091R5 ADC Driver
  "AD7091R8" = no; # Analog Devices AD7091R8 ADC Driver
  "AD7124" = no; # Analog Devices AD7124 and similar sigma-delta ADCs driver
  "AD7173" = no; # Analog Devices AD7173 driver
  "AD7191" = no; # Analog Devices AD7191 ADC driver
  "AD7192" = no; # Analog Devices AD7192 and similar ADC driver
  "AD7266" = no; # Analog Devices AD7265/AD7266 ADC driver
  "AD7280" = no; # Analog Devices AD7280A Lithium Ion Battery Monitoring System
  "AD7291" = no; # Analog Devices AD7291 ADC driver
  "AD7292" = no; # Analog Devices AD7292 ADC driver
  "AD7298" = no; # Analog Devices AD7298 ADC driver
  "AD7380" = no; # Analog Devices AD7380 ADC driver
  "AD7476" = no; # Analog Devices AD7476 1-channel ADCs driver and other similar devices from AD and TI
  "AD7606_IFACE_PARALLEL" = no; # Analog Devices AD7606 ADC driver with parallel interface support
  "AD7606_IFACE_SPI" = no; # Analog Devices AD7606 ADC driver with spi interface support
  "AD7625" = no; # Analog Devices AD7625/AD7626 High Speed ADC driver
  "AD7766" = no; # Analog Devices AD7766/AD7767 ADC driver
  "AD7768_1" = no; # Analog Devices AD7768-1 ADC driver
  "AD7779" = no; # Analog Devices AD7779 ADC driver
  "AD7780" = no; # Analog Devices AD7780 and similar ADCs driver
  "AD7791" = no; # Analog Devices AD7791 ADC driver
  "AD7793" = no; # Analog Devices AD7793 and similar ADCs driver
  "AD7887" = no; # Analog Devices AD7887 ADC driver
  "AD7923" = no; # Analog Devices AD7923 and similar ADCs driver
  "AD7944" = no; # Analog Devices AD7944 and similar ADCs driver
  "AD7949" = no; # Analog Devices AD7949 and similar ADCs driver
  "AD799X" = no; # Analog Devices AD799x ADC driver
  "AD9467" = no; # Analog Devices AD9467 High Speed ADC driver
  "CC10001_ADC" = no; # Cosmic Circuits 10001 ADC driver
  "ENVELOPE_DETECTOR" = no; # Envelope detector using a DAC and a comparator
  "GEHC_PMC_ADC" = no; # GE HealthCare PMC ADC driver
  "HI8435" = no; # Holt Integrated Circuits HI-8435 threshold detector
  "HX711" = no; # AVIA HX711 ADC for weight cells
  "INA2XX_ADC" = no; # Texas Instruments INA2xx Power Monitors IIO driver
  "LTC2309" = no; # Linear Technology LTC2309 ADC driver
  "LTC2471" = no; # Linear Technology LTC2471 and LTC2473 ADC driver
  "LTC2485" = no; # Linear Technology LTC2485 ADC driver
  "LTC2496" = no; # Linear Technology LTC2496 ADC driver
  "LTC2497" = no; # Linear Technology LTC2497 ADC driver
  "MAX1027" = no; # Maxim max1027 ADC driver
  "MAX11100" = no; # Maxim max11100 ADC driver
  "MAX1118" = no; # Maxim max1117/max1118/max1119 ADCs driver
  "MAX11205" = no; # Maxim max11205 ADC driver
  "MAX11410" = no; # Analog Devices MAX11410 ADC driver
  "MAX1241" = no; # Maxim max1241 ADC driver
  "MAX1363" = no; # Maxim max1363 ADC driver
  "MAX34408" = no; # Maxim max34408/max344089 ADC driver
  "MAX9611" = no; # Maxim max9611/max9612 ADC driver
  "MCP320X" = no; # Microchip Technology MCP3x01/02/04/08 and MCP3550/1/3
  "MCP3422" = no; # Microchip Technology MCP3421/2/3/4/5/6/7/8 driver
  "MCP3564" = no; # Microchip Technology MCP3461/2/4/R, MCP3561/2/4/R driver
  "MCP3911" = no; # Microchip Technology MCP3911 driver
  "MEDIATEK_MT6360_ADC" = no; # Mediatek MT6360 ADC driver
  "NAU7802" = no; # Nuvoton NAU7802 ADC driver
  "NCT7201" = no; # Nuvoton Instruments NCT7201 and NCT7202 Power Monitor
  "PAC1921" = no; # Microchip Technology PAC1921 driver
  "PAC1934" = no; # Microchip Technology PAC1934 driver
  "QCOM_SPMI_RRADC" = module; # Qualcomm SPMI RRADC
  "QCOM_SPMI_IADC" = no; # Qualcomm SPMI PMIC current ADC
  "QCOM_SPMI_VADC" = yes; # Qualcomm SPMI PMIC voltage ADC
  "QCOM_SPMI_ADC5" = yes; # Qualcomm Technologies Inc. SPMI PMIC5 ADC
  "ROHM_BD79124" = no; # Rohm BD79124 ADC driver
  "RICHTEK_RTQ6056" = no; # Richtek RTQ6056 Current and Power Monitor ADC
  "SD_ADC_MODULATOR" = no; # Generic sigma delta modulator
  "STM32_ADC_CORE" = no; # STMicroelectronics STM32 adc core
  "STM32_DFSDM_CORE" = no; # STMicroelectronics STM32 DFSDM core
  "STM32_DFSDM_ADC" = no; # STMicroelectronics STM32 dfsdm adc
  "TI_ADC081C" = no; # Texas Instruments ADC081C/ADC101C/ADC121C family
  "TI_ADC0832" = no; # Texas Instruments ADC0831/ADC0832/ADC0834/ADC0838
  "TI_ADC084S021" = no; # Texas Instruments ADC084S021
  "TI_ADC108S102" = no; # Texas Instruments ADC108S102 and ADC128S102 driver
  "TI_ADC12138" = no; # Texas Instruments ADC12130/ADC12132/ADC12138
  "TI_ADC128S052" = no; # Texas Instruments ADC128S052/ADC122S021/ADC124S021
  "TI_ADC161S626" = no; # Texas Instruments ADC161S626 1-channel differential ADC
  "TI_ADS1015" = module; # Texas Instruments ADS1015 ADC
  "TI_ADS1100" = no; # Texas Instruments ADS1100 and ADS1000 ADC
  "TI_ADS1119" = no; # Texas Instruments ADS1119 ADC
  "TI_ADS124S08" = no; # Texas Instruments ADS124S08
  "TI_ADS1298" = no; # Texas Instruments ADS1298
  "TI_ADS131E08" = no; # Texas Instruments ADS131E08
  "TI_ADS7138" = no; # Texas Instruments ADS7128 and ADS7138 ADC driver
  "TI_ADS7924" = no; # Texas Instruments ADS7924 ADC
  "TI_ADS7950" = no; # Texas Instruments ADS7950 ADC driver
  "TI_ADS8344" = no; # Texas Instruments ADS8344
  "TI_ADS8688" = no; # Texas Instruments ADS8688
  "TI_LMP92064" = no; # Texas Instruments LMP92064 ADC driver
  "TI_TLC4541" = no; # Texas Instruments TLC4541 ADC driver
  "TI_TSC2046" = no; # Texas Instruments TSC2046 ADC driver
  "VF610_ADC" = no; # Freescale vf610 ADC driver
  "XILINX_XADC" = no; # Xilinx XADC driver
  #### end of Analog to digital converters

  #### Analog to digital and digital to analog converters
  "AD74115" = no; # Analog Devices AD74115H driver
  "AD74413R" = no; # Analog Devices AD74412R/AD74413R driver
  #### end of Analog to digital and digital to analog converters

  #### Analog Front Ends
  "IIO_RESCALE" = no; # IIO rescale
  #### end of Analog Front Ends

  #### Amplifiers
  "AD8366" = no; # Analog Devices AD8366 and similar Gain Amplifiers
  "ADA4250" = no; # Analog Devices ADA4250 Instrumentation Amplifier
  "HMC425" = no; # Analog Devices HMC425A and similar GPIO Gain Amplifiers
  #### end of Amplifiers

  #### Capacitance to digital converters
  "AD7150" = no; # Analog Devices ad7150/1/6 capacitive sensor driver
  "AD7746" = no; # Analog Devices AD7745, AD7746 AD7747 capacitive sensor driver
  #### end of Capacitance to digital converters

  #### Chemical Sensors
  "AOSONG_AGS02MA" = no; # Aosong AGS02MA TVOC sensor driver
  "ATLAS_PH_SENSOR" = no; # Atlas Scientific OEM SM sensors
  "ATLAS_EZO_SENSOR" = no; # Atlas Scientific EZO sensors
  "BME680" = no; # Bosch Sensortec BME680 sensor driver
  "CCS811" = no; # AMS CCS811 VOC sensor
  "ENS160" = no; # ScioSense ENS160 sensor driver
  "IAQCORE" = no; # AMS iAQ-Core VOC sensors
  "MHZ19B" = no; # Winsen MHZ19B CO2 sensor
  "PMS7003" = no; # Plantower PMS7003 particulate matter sensor
  "SCD30_CORE" = no; # SCD30 carbon dioxide sensor driver
  "SCD4X" = no; # SCD4X carbon dioxide sensor driver
  "SEN0322" = no; # SEN0322 oxygen sensor
  "SENSIRION_SGP30" = no; # Sensirion SGPxx gas sensors
  "SENSIRION_SGP40" = no; # Sensirion SGP40 gas sensor
  "SPS30_I2C" = no; # SPS30 particulate matter sensor I2C driver
  "SPS30_SERIAL" = no; # SPS30 particulate matter sensor serial driver
  "SENSEAIR_SUNRISE_CO2" = no; # Senseair Sunrise 006-0-0007 CO2 sensor
  "VZ89X" = no; # SGX Sensortech MiCS VZ89X VOC sensor
  #### end of Chemical Sensors

  "IIO_CROS_EC_SENSORS_CORE" = module; # ChromeOS EC Sensors Core
  "IIO_CROS_EC_SENSORS" = module; # ChromeOS EC Contiguous Sensors
  "IIO_CROS_EC_SENSORS_LID_ANGLE" = no; # ChromeOS EC Sensor for lid angle

  #### Hid Sensor IIO Common
  "HID_SENSOR_IIO_COMMON" = module; # Common modules for all HID Sensor IIO drivers
  "HID_SENSOR_IIO_TRIGGER" = module; # Common module (trigger) for all HID Sensor IIO drivers
  #### end of Hid Sensor IIO Common

  #### IIO SCMI Sensors
  "IIO_SCMI" = no; # IIO SCMI
  #### end of IIO SCMI Sensors

  #### SSP Sensor Common
  "IIO_SSP_SENSORHUB" = no; # Samsung Sensorhub driver
  #### end of SSP Sensor Common

  #### Digital to analog converters
  "AD3530R" = no; # Analog Devices AD3530R and Similar DACs driver
  "AD3552R_HS" = no; # Analog Devices AD3552R DAC High Speed driver
  "AD3552R" = no; # Analog Devices AD3552R DAC driver
  "AD5064" = no; # Analog Devices AD5064 and similar multi-channel DAC driver
  "AD5360" = no; # Analog Devices AD5360/61/62/63/70/71/73 DAC driver
  "AD5380" = no; # Analog Devices AD5380/81/82/83/84/90/91/92 DAC driver
  "AD5421" = no; # Analog Devices AD5421 DAC driver
  "AD5446" = no; # Analog Devices AD5446 and similar single channel DACs driver
  "AD5449" = no; # Analog Devices AD5449 and similar DACs driver
  "AD5592R" = no; # Analog Devices AD5592R ADC/DAC driver
  "AD5593R" = no; # Analog Devices AD5593R ADC/DAC driver
  "AD5504" = no; # Analog Devices AD5504/AD5501 DAC SPI driver
  "AD5624R_SPI" = no; # Analog Devices AD5624/44/64R DAC spi driver
  "AD9739A" = no; # Analog Devices AD9739A RF DAC spi driver
  "LTC2688" = no; # Analog Devices LTC2688 DAC spi driver
  "AD5686_SPI" = no; # Analog Devices AD5686 and similar multi-channel DACs (SPI)
  "AD5696_I2C" = no; # Analog Devices AD5696 and similar multi-channel DACs (I2C)
  "AD5755" = no; # Analog Devices AD5755/AD5755-1/AD5757/AD5735/AD5737 DAC driver
  "AD5758" = no; # Analog Devices AD5758 DAC driver
  "AD5761" = no; # Analog Devices AD5761/61R/21/21R DAC driver
  "AD5764" = no; # Analog Devices AD5764/64R/44/44R DAC driver
  "AD5766" = no; # Analog Devices AD5766/AD5767 DAC driver
  "AD5770R" = no; # Analog Devices AD5770R IDAC driver
  "AD5791" = no; # Analog Devices AD5760/AD5780/AD5781/AD5790/AD5791 DAC SPI driver
  "AD7293" = no; # Analog Devices AD7293 Power Amplifier Current Controller
  "AD7303" = no; # Analog Devices AD7303 DAC driver
  "AD8460" = no; # Analog Devices AD8460 DAC driver
  "AD8801" = no; # Analog Devices AD8801/AD8803 DAC driver
  "BD79703" = no; # ROHM Semiconductor BD79703 DAC driver
  "DPOT_DAC" = no; # DAC emulation using a DPOT
  "DS4424" = no; # Maxim Integrated DS4422/DS4424 DAC driver
  "LTC1660" = no; # Linear Technology LTC1660/LTC1665 DAC SPI driver
  "LTC2632" = no; # Linear Technology LTC2632-12/10/8 and similar DAC spi driver
  "LTC2664" = no; # Analog Devices LTC2664 and LTC2672 DAC SPI driver
  "M62332" = no; # Mitsubishi M62332 DAC driver
  "MAX517" = no; # Maxim MAX517/518/519/520/521 DAC driver
  "MAX5522" = no; # Maxim MAX5522 DAC driver
  "MAX5821" = no; # Maxim MAX5821 DAC driver
  "MCP4725" = no; # MCP4725/6 DAC driver
  "MCP4728" = no; # MCP4728 DAC driver
  "MCP4821" = no; # MCP4801/02/11/12/21/22 DAC driver
  "MCP4922" = no; # MCP4902, MCP4912, MCP4922 DAC driver
  "STM32_DAC" = no; # STMicroelectronics STM32 DAC
  "TI_DAC082S085" = no; # Texas Instruments 8/10/12-bit 2/4-channel DAC driver
  "TI_DAC5571" = no; # Texas Instruments 8/10/12/16-bit 1/2/4-channel DAC driver
  "TI_DAC7311" = no; # Texas Instruments 8/10/12-bit 1-channel DAC driver
  "TI_DAC7612" = no; # Texas Instruments 12-bit 2-channel DAC driver
  "VF610_DAC" = no; # Vybrid vf610 DAC driver
  #### end of Digital to analog converters

  #### Filters
  "ADMV8818" = no; # Analog Devices ADMV8818 High-Pass and Low-Pass Filter
  #### end of Filters

  #### Frequency Synthesizers DDS/PLL

  ##### Frequency Synthesizers DDS/PLL -> Clock Generator/Distribution
  "AD9523" = no; # Analog Devices AD9523 Low Jitter Clock Generator
  ##### Frequency Synthesizers DDS/PLL: end of Clock Generator/Distribution

  ##### Frequency Synthesizers DDS/PLL -> Phase-Locked Loop (PLL) frequency synthesizers
  "ADF4350" = no; # Analog Devices ADF4350/ADF4351 Wideband Synthesizers
  "ADF4371" = no; # Analog Devices ADF4371/ADF4372 Wideband Synthesizers
  "ADF4377" = no; # Analog Devices ADF4377 Microwave Wideband Synthesizer
  "ADMFM2000" = no; # Analog Devices ADMFM2000 Dual Microwave Down Converter
  "ADMV1013" = no; # Analog Devices ADMV1013 Microwave Upconverter
  "ADMV1014" = no; # Analog Devices ADMV1014 Microwave Downconverter
  "ADMV4420" = no; # Analog Devices ADMV4420 K Band Downconverter
  "ADRF6780" = no; # Analog Devices ADRF6780 Microwave Upconverter
  ##### Frequency Synthesizers DDS/PLL: end of Phase-Locked Loop (PLL) frequency synthesizers
  #### end of Frequency Synthesizers DDS/PLL

  #### Digital gyroscope sensors
  "ADIS16080" = no; # Analog Devices ADIS16080/100 Yaw Rate Gyroscope with SPI driver
  "ADIS16130" = no; # Analog Devices ADIS16130 High Precision Angular Rate Sensor driver
  "ADIS16136" = no; # Analog devices ADIS16136 and similar gyroscopes driver
  "ADIS16260" = no; # Analog Devices ADIS16260 Digital Gyroscope Sensor SPI driver
  "ADXRS290" = no; # Analog Devices ADXRS290 Dual-Axis MEMS Gyroscope SPI driver
  "ADXRS450" = no; # Analog Devices ADXRS450/3 Digital Output Gyroscope SPI driver
  "BMG160" = no; # BOSCH BMG160 Gyro Sensor
  "FXAS21002C" = no; # NXP FXAS21002C Gyro Sensor
  "HID_SENSOR_GYRO_3D" = module; # HID Gyroscope 3D
  "MPU3050_I2C" = no; # Invensense MPU3050 devices on I2C
  "IIO_ST_GYRO_3AXIS" = no; # STMicroelectronics gyroscopes 3-Axis Driver
  "ITG3200" = no; # InvenSense ITG3200 Digital 3-Axis Gyroscope I2C driver
  #### end of Digital gyroscope sensors

  #### Health Sensors

  ##### Health Sensors -> Heart Rate Monitors
  "AFE4403" = no; # TI AFE4403 Heart Rate Monitor
  "AFE4404" = no; # TI AFE4404 heart rate and pulse oximeter sensor
  "MAX30100" = no; # MAX30100 heart rate and pulse oximeter sensor
  "MAX30102" = no; # MAX30102 heart rate and pulse oximeter sensor
  ##### Health Sensors: end of Heart Rate Monitors
  #### end of Health Sensors

  #### Humidity sensors
  "AM2315" = no; # Aosong AM2315 relative humidity and temperature sensor
  "DHT11" = no; # DHT11 (and compatible sensors) driver
  "ENS210" = no; # ENS210 temperature and humidity sensor
  "HDC100X" = no; # TI HDC100x relative humidity and temperature sensor
  "HDC2010" = no; # TI HDC2010 relative humidity and temperature sensor
  "HDC3020" = no; # TI HDC3020 relative humidity and temperature sensor
  "HID_SENSOR_HUMIDITY" = module; # HID Environmental humidity sensor
  "HTS221" = no; # STMicroelectronics HTS221 sensor Driver
  "HTU21" = no; # Measurement Specialties HTU21 humidity & temperature sensor
  "SI7005" = no; # SI7005 relative humidity and temperature sensor
  "SI7020" = no; # Si7013/20/21 Relative Humidity and Temperature Sensors
  #### end of Humidity sensors

  #### Inertial measurement units
  "ADIS16400" = no; # Analog Devices ADIS16400 and similar IMU SPI driver
  "ADIS16460" = no; # Analog Devices ADIS16460 and similar IMU driver
  "ADIS16475" = no; # Analog Devices ADIS16475 and similar IMU driver
  "ADIS16480" = no; # Analog Devices ADIS16480 and similar IMU driver
  "ADIS16550" = no; # Analog Devices ADIS16550 and similar IMU driver
  "BMI160_I2C" = no; # Bosch BMI160 I2C driver
  "BMI160_SPI" = no; # Bosch BMI160 SPI driver
  "BMI270_I2C" = no; # Bosch BMI270 I2C driver
  "BMI270_SPI" = no; # Bosch BMI270 SPI driver
  "BMI323_I2C" = no; # Bosch BMI323 I2C driver
  "BMI323_SPI" = no; # Bosch BMI323 SPI driver
  "BOSCH_BNO055_SERIAL" = no; # Bosch BNO055 attached via UART
  "BOSCH_BNO055_I2C" = no; # Bosch BNO055 attached via I2C bus
  "FXOS8700_I2C" = no; # NXP FXOS8700 I2C driver
  "FXOS8700_SPI" = no; # NXP FXOS8700 SPI driver
  "KMX61" = no; # Kionix KMX61 6-axis accelerometer and magnetometer
  "INV_ICM42600_I2C" = no; # InvenSense ICM-426xx I2C driver
  "INV_ICM42600_SPI" = no; # InvenSense ICM-426xx SPI driver
  "INV_MPU6050_I2C" = no; # Invensense MPU6050 devices (I2C)
  "INV_MPU6050_SPI" = no; # Invensense MPU6050 devices (SPI)
  "SMI240" = no; # Bosch Sensor SMI240 Inertial Measurement Unit
  "IIO_ST_LSM6DSX" = module; # ST_LSM6DSx driver for STM 6-axis IMU MEMS sensors
  "IIO_ST_LSM6DSX_I2C" = module; # ST_LSM6DSx driver for STM 6-axis IMU MEMS sensors I2C Interface
  "IIO_ST_LSM6DSX_SPI" = module; # ST_LSM6DSx driver for STM 6-axis IMU MEMS sensors SPI Interface
  "IIO_ST_LSM9DS0" = no; # STMicroelectronics LSM9DS0 IMU driver
  #### end of Inertial measurement units

  #### Light sensors
  "ACPI_ALS" = no; # ACPI Ambient Light Sensor
  "ADJD_S311" = no; # ADJD-S311-CR999 digital color sensor
  "ADUX1020" = no; # ADUX1020 photometric sensor
  "AL3000A" = no; # AL3000a ambient light sensor
  "AL3010" = no; # AL3010 ambient light sensor
  "AL3320A" = no; # AL3320A ambient light sensor
  "APDS9160" = no; # APDS9160 combined als and proximity sensor
  "APDS9300" = no; # APDS9300 ambient light sensor
  "APDS9306" = no; # Avago APDS9306 Ambient Light Sensor
  "APDS9960" = no; # Avago APDS9960 gesture/RGB/ALS/proximity sensor
  "AS73211" = no; # AMS AS73211 XYZ color sensor and AMS AS7331 UV sensor
  "BH1745" = no; # ROHM BH1745 colour sensor
  "BH1750" = no; # ROHM BH1750 ambient light sensor
  "BH1780" = no; # ROHM BH1780 ambient light sensor
  "CM32181" = no; # CM32181 driver
  "CM3232" = no; # CM3232 ambient light sensor
  "CM3323" = no; # Capella CM3323 color light sensor
  "CM3605" = no; # Capella CM3605 ambient light and proximity sensor
  "CM36651" = no; # CM36651 driver
  "IIO_CROS_EC_LIGHT_PROX" = module; # ChromeOS EC Light and Proximity Sensors
  "GP2AP002" = no; # Sharp GP2AP002 Proximity/ALS sensor
  "GP2AP020A00F" = no; # Sharp GP2AP020A00F Proximity/ALS sensor
  "SENSORS_ISL29018" = no; # Intersil 29018 light and proximity sensor
  "SENSORS_ISL29028" = no; # Intersil ISL29028 Concurrent Light and Proximity Sensor
  "ISL29125" = no; # Intersil ISL29125 digital color light sensor
  "ISL76682" = no; # Intersil ISL76682 Light Sensor
  "HID_SENSOR_ALS" = module; # HID ALS
  "HID_SENSOR_PROX" = no; # HID PROX
  "JSA1212" = no; # JSA1212 ALS and proximity sensor driver
  "ROHM_BU27034" = no; # ROHM BU27034 ambient light sensor
  "RPR0521" = no; # ROHM RPR0521 ALS and proximity sensor driver
  "LTR390" = no; # LTR-390UV-01 ambient light and UV sensor
  "LTR501" = no; # LTR-501ALS-01 light sensor
  "LTRF216A" = no; # Liteon LTRF216A Light Sensor
  "LV0104CS" = no; # LV0104CS Ambient Light Sensor
  "MAX44000" = no; # MAX44000 Ambient and Infrared Proximity Sensor
  "MAX44009" = no; # MAX44009 Ambient Light Sensor
  "NOA1305" = no; # ON Semiconductor NOA1305 ambient light sensor
  "OPT3001" = no; # Texas Instruments OPT3001 Light Sensor
  "OPT4001" = no; # Texas Instruments OPT4001 Light Sensor
  "OPT4060" = no; # Texas Instruments OPT4060 RGBW Color Sensor
  "PA12203001" = no; # TXC PA12203001 light and proximity sensor
  "SI1133" = no; # SI1133 UV Index Sensor and Ambient Light Sensor
  "SI1145" = no; # SI1132 and SI1141/2/3/5/6/7 combined ALS, UV index and proximity sensor
  "STK3310" = no; # STK3310 ALS and proximity sensor
  "ST_UVIS25" = no; # STMicroelectronics UVIS25 sensor driver
  "TCS3414" = no; # TAOS TCS3414 digital color sensor
  "TCS3472" = no; # TAOS TCS3472 color light-to-digital converter
  "SENSORS_TSL2563" = no; # TAOS TSL2560, TSL2561, TSL2562 and TSL2563 ambient light sensors
  "TSL2583" = no; # TAOS TSL2580, TSL2581 and TSL2583 light-to-digital converters
  "TSL2591" = no; # TAOS TSL2591 ambient light sensor
  "TSL2772" = no; # TAOS TSL/TMD2x71 and TSL/TMD2x72 Family of light and proximity sensors
  "TSL4531" = no; # TAOS TSL4531 ambient light sensors
  "US5182D" = no; # UPISEMI light and proximity sensor
  "VCNL4000" = module; # VCNL4000/4010/4020/4200 combined ALS and proximity sensor
  "VCNL4035" = no; # VCNL4035 combined ALS and proximity sensor
  "VEML3235" = no; # VEML3235 ambient light sensor
  "VEML6030" = no; # VEML6030 and VEML6035 ambient light sensors
  "VEML6040" = no; # VEML6040 RGBW light sensor
  "VEML6070" = no; # VEML6070 UV A light sensor
  "VEML6075" = no; # VEML6075 UVA and UVB light sensor
  "VL6180" = no; # VL6180 ALS, range and proximity sensor
  "ZOPT2201" = no; # ZOPT2201 ALS and UV B sensor
  #### end of Light sensors

  #### Magnetometer sensors
  "AF8133J" = no; # Voltafield AF8133J 3-Axis Magnetometer
  "AK8974" = no; # Asahi Kasei AK8974 3-Axis Magnetometer
  "AK8975" = no; # Asahi Kasei AK8975 3-Axis Magnetometer
  "AK09911" = no; # Asahi Kasei AK09911 3-axis Compass
  "ALS31300" = no; # Allegro MicroSystems ALS31300 3-D Linear Hall Effect Sensor
  "BMC150_MAGN_I2C" = no; # Bosch BMC150 I2C Magnetometer Driver
  "BMC150_MAGN_SPI" = no; # Bosch BMC150 SPI Magnetometer Driver
  "MAG3110" = no; # Freescale MAG3110 3-Axis Magnetometer
  "HID_SENSOR_MAGNETOMETER_3D" = module; # HID Magenetometer 3D
  "MMC35240" = no; # MEMSIC MMC35240 3-axis magnetic sensor
  "IIO_ST_MAGN_3AXIS" = module; # STMicroelectronics magnetometers 3-Axis Driver
  "IIO_ST_MAGN_I2C_3AXIS" = module; # STMicroelectronics magnetometers 3-Axis I2C Interface
  "IIO_ST_MAGN_SPI_3AXIS" = module; # STMicroelectronics magnetometers 3-Axis SPI Interface
  "SENSORS_HMC5843_I2C" = no; # Honeywell HMC5843/5883/5883L 3-Axis Magnetometer (I2C)
  "SENSORS_HMC5843_SPI" = no; # Honeywell HMC5983 3-Axis Magnetometer (SPI)
  "SENSORS_RM3100_I2C" = no; # PNI RM3100 3-Axis Magnetometer (I2C)
  "SENSORS_RM3100_SPI" = no; # PNI RM3100 3-Axis Magnetometer (SPI)
  "SI7210" = no; # SI7210 Hall effect sensor
  "TI_TMAG5273" = no; # TI TMAG5273 Low-Power Linear 3D Hall-Effect Sensor
  "YAMAHA_YAS530" = no; # Yamaha YAS530 family of 3-Axis Magnetometers (I2C)
  #### end of Magnetometer sensors

  #### Multiplexers
  "IIO_MUX" = no; # IIO multiplexer driver
  #### end of Multiplexers

  #### Inclinometer sensors
  "HID_SENSOR_INCLINOMETER_3D" = module; # HID Inclinometer 3D
  "HID_SENSOR_DEVICE_ROTATION" = module; # HID Device Rotation
  #### end of Inclinometer sensors

  #### Triggers - standalone
  "IIO_INTERRUPT_TRIGGER" = no; # Generic interrupt trigger
  "IIO_STM32_LPTIMER_TRIGGER" = no; # STM32 Low-Power Timer Trigger
  "IIO_SYSFS_TRIGGER" = no; # SYSFS trigger
  #### end of Triggers - standalone

  #### Linear and angular position sensors
  "HID_SENSOR_CUSTOM_INTEL_HINGE" = module; # HID Hinge
  #### end of Linear and angular position sensors

  #### Digital potentiometers
  "AD5110" = no; # Analog Devices AD5110 and similar Digital Potentiometer driver
  "AD5272" = no; # Analog Devices AD5272 and similar Digital Potentiometer driver
  "DS1803" = no; # Maxim Integrated DS1803 and similar Digital Potentiometer driver
  "MAX5432" = no; # Maxim MAX5432-MAX5435 Digital Potentiometer driver
  "MAX5481" = no; # Maxim MAX5481-MAX5484 Digital Potentiometer driver
  "MAX5487" = no; # Maxim MAX5487/MAX5488/MAX5489 Digital Potentiometer driver
  "MCP4018" = no; # Microchip MCP4017/18/19 Digital Potentiometer driver
  "MCP4131" = no; # Microchip MCP413X/414X/415X/416X/423X/424X/425X/426X Digital Potentiometer driver
  "MCP4531" = no; # Microchip MCP45xx/MCP46xx Digital Potentiometer driver
  "MCP41010" = no; # Microchip MCP41xxx/MCP42xxx Digital Potentiometer driver
  "TPL0102" = no; # Texas Instruments digital potentiometer driver
  "X9250" = no; # Renesas X9250 quad controlled potentiometers
  #### end of Digital potentiometers

  #### Digital potentiostats
  "LMP91000" = no; # Texas Instruments LMP91000 potentiostat driver
  #### end of Digital potentiostats

  #### Pressure sensors
  "ABP060MG" = no; # Honeywell ABP pressure sensor driver
  "ROHM_BM1390" = no; # ROHM BM1390GLV-Z pressure sensor driver
  "BMP280" = no; # Bosch Sensortec BMP180/BMP280/BMP380/BMP580 pressure sensor driver
  "IIO_CROS_EC_BARO" = module; # ChromeOS EC Barometer Sensor
  "DLHL60D" = no; # All Sensors DLHL60D and DLHL60G low voltage digital pressure sensors
  "DPS310" = no; # Infineon DPS310 pressure and temperature sensor
  "HID_SENSOR_PRESS" = no; # HID PRESS
  "HP03" = no; # Hope RF HP03 temperature and pressure sensor driver
  "HSC030PA" = no; # Honeywell HSC/SSC TruStability pressure sensor series
  "ICP10100" = no; # InvenSense ICP-101xx pressure and temperature sensor
  "MPL115_I2C" = no; # Freescale MPL115A2 pressure sensor driver
  "MPL115_SPI" = no; # Freescale MPL115A1 pressure sensor driver
  "MPL3115" = no; # Freescale MPL3115A2 pressure sensor driver
  "MPRLS0025PA" = no; # Honeywell MPRLS0025PA (MicroPressure sensors series)
  "MS5611" = no; # Measurement Specialties MS5611 pressure sensor driver
  "MS5637" = no; # Measurement Specialties MS5637 pressure & temperature sensor
  "SDP500" = no; # Sensirion SDP500 differential pressure sensor I2C driver
  "IIO_ST_PRESS" = no; # STMicroelectronics pressure sensor Driver
  "T5403" = no; # EPCOS T5403 digital barometric pressure sensor driver
  "HP206C" = no; # HOPERF HP206C precision barometer and altimeter sensor
  "ZPA2326" = no; # Murata ZPA2326 pressure sensor driver
  #### end of Pressure sensors

  #### Lightning sensors
  "AS3935" = no; # AS3935 Franklin lightning sensor
  #### end of Lightning sensors

  #### Proximity and distance sensors
  "CROS_EC_MKBP_PROXIMITY" = no; # ChromeOS EC MKBP Proximity sensor
  "HX9023S" = no; # TYHX HX9023S SAR sensor
  "IRSD200" = no; # Murata IRS-D200 PIR sensor
  "ISL29501" = no; # Intersil ISL29501 Time Of Flight sensor
  "LIDAR_LITE_V2" = no; # PulsedLight LIDAR sensor
  "MB1232" = no; # MaxSonar I2CXL family ultrasonic sensors
  "PING" = no; # Parallax GPIO bitbanged ranger sensors
  "RFD77402" = no; # RFD77402 ToF sensor
  "SRF04" = no; # GPIO bitbanged ultrasonic ranger sensor (SRF04, MB1000)
  "SX9310" = no; # SX9310/SX9311 Semtech proximity sensor
  "SX9324" = no; # SX9324 Semtech proximity sensor
  "SX9360" = no; # SX9360 Semtech proximity sensor
  "SX9500" = no; # SX9500 Semtech proximity sensor
  "SRF08" = no; # Devantech SRF02/SRF08/SRF10 ultrasonic ranger sensor
  "VCNL3020" = no; # VCNL3020 proximity sensor
  "VL53L0X_I2C" = no; # STMicroelectronics VL53L0X ToF ranger sensor (I2C)
  "AW96103" = no; # AW96103/AW96105 Awinic proximity sensor
  #### end of Proximity and distance sensors

  #### Resolver to digital converters
  "AD2S90" = no; # Analog Devices ad2s90 driver
  "AD2S1200" = no; # Analog Devices ad2s1200/ad2s1205 driver
  "AD2S1210" = no; # Analog Devices ad2s1210 driver
  #### end of Resolver to digital converters

  #### Temperature sensors
  "LTC2983" = no; # Analog Devices Multi-Sensor Digital Temperature Measurement System
  "MAXIM_THERMOCOUPLE" = no; # Maxim thermocouple sensors
  "HID_SENSOR_TEMP" = module; # HID Environmental temperature sensor
  "MLX90614" = no; # MLX90614 contact-less infrared sensor
  "MLX90632" = no; # MLX90632 contact-less infrared sensor with medical accuracy
  "MLX90635" = no; # MLX90635 contact-less infrared sensor with medical accuracy
  "TMP006" = no; # TMP006 infrared thermopile sensor
  "TMP007" = no; # TMP007 infrared thermopile sensor with Integrated Math Engine
  "TMP117" = no; # TMP117 Digital temperature sensor with integrated NV memory
  "TSYS01" = no; # Measurement Specialties TSYS01 temperature sensor using I2C bus connection
  "TSYS02D" = no; # Measurement Specialties TSYS02D temperature sensor
  "MAX30208" = no; # Maxim MAX30208 digital temperature sensor
  "MAX31856" = no; # MAX31856 thermocouple sensor
  "MAX31865" = no; # MAX31865 RTD to Digital converter
  "MCP9600" = no; # MCP9600 thermocouple EMF converter
  #### end of Temperature sensors

  "NTB" = no; # Non-Transparent Bridge support
  "PWM" = yes; # Pulse-Width Modulation (PWM) Support
  "PWM_DEBUG" = no; # PWM lowlevel drivers additional checks and debug messages
  "PWM_ADP5585" = module; # ADP5585 PWM support
  "PWM_ATMEL_TCB" = no; # Atmel TC Block PWM support
  "PWM_CLK" = module; # Clock based PWM support
  "PWM_CROS_EC" = module; # ChromeOS EC PWM driver
  "PWM_DWC" = no; # DesignWare PWM Controller (PCI bus)
  "PWM_FSL_FTM" = no; # Freescale FlexTimer Module (FTM) PWM support
  "PWM_GPIO" = no; # GPIO PWM support
  "PWM_MC33XS2410" = no; # MC33XS2410 PWM support
  "PWM_PCA9685" = no; # NXP PCA9685 PWM driver
  "PWM_STM32_LP" = no; # STMicroelectronics STM32 PWM LP
  "PWM_XILINX" = no; # Xilinx AXI Timer PWM support

  ### Device Drivers -> IRQ chip support
  "AL_FIC" = no; # Amazon's Annapurna Labs Fabric Interrupt Controller
  "XILINX_INTC" = no; # Xilinx Interrupt Controller IP
  "STM32MP_EXTI" = yes; # STM32MP extended interrupts and event controller
  "QCOM_IRQ_COMBINER" = yes; # QCOM IRQ combiner support
  "QCOM_PDC" = yes; # QCOM PDC
  "QCOM_MPM" = yes; # QCOM MPM
  ### Device Drivers: end of IRQ chip support

  "IPACK_BUS" = no; # IndustryPack bus support
  "RESET_CONTROLLER" = yes; # Reset Controller Support
  "RESET_GPIO" = module; # GPIO reset controller
  "RESET_NUVOTON_MA35D1" = yes; # Nuvoton MA35D1 Reset Driver
  "RESET_QCOM_AOSS" = yes; # Qcom AOSS Reset Driver
  "RESET_QCOM_PDC" = module; # Qualcomm PDC Reset Driver
  "RESET_SCMI" = yes; # Reset driver controlled via ARM SCMI interface
  "RESET_TI_SYSCON" = no; # TI SYSCON Reset Driver
  "RESET_TI_TPS380X" = no; # TI TPS380x Reset Driver

  ### Device Drivers -> PHY Subsystem
  "GENERIC_PHY" = yes; # PHY Core
  "PHY_SNPS_EUSB2" = no; # SNPS eUSB2 PHY Driver
  "PHY_CAN_TRANSCEIVER" = module; # CAN transceiver PHY
  "PHY_AIROHA_PCIE" = no; # Airoha PCIe-PHY Driver
  "PHY_NXP_PTN3222" = module; # NXP PTN3222 1-port eUSB2 to USB2 redriver

  #### Device Drivers -> PHY Subsystem -> PHY drivers for Broadcom platforms
  "BCM_KONA_USB2_PHY" = no; # Broadcom Kona USB2 PHY Driver
  #### Device Drivers -> PHY Subsystem: end of PHY drivers for Broadcom platforms

  "PHY_CADENCE_TORRENT" = module; # Cadence Torrent PHY driver
  "PHY_CADENCE_DPHY" = module; # Cadence D-PHY Support
  "PHY_CADENCE_DPHY_RX" = module; # Cadence D-PHY Rx Support
  "PHY_CADENCE_SIERRA" = module; # Cadence Sierra PHY Driver
  "PHY_CADENCE_SALVO" = module; # Cadence Salvo PHY Driver
  "PHY_PXA_28NM_HSIC" = no; # Marvell USB HSIC 28nm PHY Driver
  "PHY_PXA_28NM_USB2" = no; # Marvell USB 2.0 28nm PHY Driver
  "PHY_CPCAP_USB" = no; # CPCAP PMIC USB PHY driver
  "PHY_MAPPHONE_MDM6600" = no; # Motorola Mapphone MDM6600 modem USB PHY driver
  "PHY_OCELOT_SERDES" = no; # SerDes PHY driver for Microsemi Ocelot
  "PHY_MA35_USB" = no; # Nuvoton MA35 USB2.0 PHY driver
  "PHY_QCOM_APQ8064_SATA" = no; # Qualcomm APQ8064 SATA SerDes/PHY driver
  "PHY_QCOM_EDP" = yes; # Qualcomm eDP PHY driver
  "PHY_QCOM_IPQ4019_USB" = no; # Qualcomm IPQ4019 USB PHY driver
  "PHY_QCOM_IPQ806X_SATA" = no; # Qualcomm IPQ806x SATA SerDes/PHY driver
  "PHY_QCOM_PCIE2" = module; # Qualcomm PCIe Gen2 PHY Driver
  "PHY_QCOM_QMP" = yes; # Qualcomm QMP PHY Drivers
  "PHY_QCOM_QMP_COMBO" = yes; # Qualcomm QMP Combo PHY Driver
  "PHY_QCOM_QMP_PCIE" = yes; # Qualcomm QMP PCIe PHY Driver
  "PHY_QCOM_QMP_PCIE_8996" = module; # Qualcomm QMP PCIe 8996 PHY Driver
  "PHY_QCOM_QMP_UFS" = yes; # Qualcomm QMP UFS PHY Driver
  "PHY_QCOM_QMP_USB" = yes; # Qualcomm QMP USB PHY Driver
  "PHY_QCOM_QMP_USB_LEGACY" = no; # Qualcomm QMP legacy USB PHY Driver
  "PHY_QCOM_QUSB2" = yes; # Qualcomm QUSB2 PHY Driver
  "PHY_QCOM_EUSB2_REPEATER" = module; # Qualcomm SNPS eUSB2 Repeater Driver
  "PHY_QCOM_M31_USB" = module; # Qualcomm M31 HS PHY driver support
  "PHY_QCOM_UNIPHY_PCIE_28LP" = no; # PCIE UNIPHY 28LP PHY driver
  "PHY_QCOM_USB_HS" = yes; # Qualcomm USB HS PHY module
  "PHY_QCOM_USB_SNPS_FEMTO_V2" = yes; # Qualcomm SNPS FEMTO USB HS PHY V2 module
  "PHY_QCOM_USB_HSIC" = no; # Qualcomm USB HSIC ULPI PHY module
  "PHY_QCOM_USB_HS_28NM" = module; # Qualcomm 28nm High-Speed PHY
  "PHY_QCOM_USB_SS" = module; # Qualcomm USB Super-Speed PHY driver
  "PHY_QCOM_IPQ806X_USB" = no; # Qualcomm IPQ806x DWC3 USB PHY driver
  "PHY_QCOM_SGMII_ETH" = module; # Qualcomm DWMAC SGMII SerDes/PHY driver
  "PHY_RTK_RTD_USB2PHY" = no; # Realtek RTD USB2 PHY Transceiver Driver
  "PHY_RTK_RTD_USB3PHY" = no; # Realtek RTD USB3 PHY Transceiver Driver
  "PHY_STM32_COMBOPHY" = no; # STMicroelectronics COMBOPHY driver for STM32MP25
  "PHY_STM32_USBPHYC" = no; # STMicroelectronics STM32 USB HS PHY Controller driver
  "PHY_TUSB1210" = no; # TI TUSB1210 ULPI PHY module
  ### Device Drivers: end of PHY Subsystem

  "POWERCAP" = no; # Generic powercap sysfs driver
  "MCB" = no; # MCB support

  ### Device Drivers -> Performance monitor support
  "ARM_CCI_PMU" = module; # ARM CCI PMU driver
  "ARM_CCI400_PMU" = yes; # support CCI-400
  "ARM_CCI5xx_PMU" = yes; # support CCI-500/CCI-550
  "ARM_CCN" = module; # ARM CCN driver support
  "ARM_CMN" = module; # Arm CMN-600 PMU support
  "ARM_NI" = no; # Arm NI-700 PMU support
  "ARM_PMU" = yes; # ARM PMU framework
  "ARM_SMMU_V3_PMU" = module; # ARM SMMUv3 Performance Monitors Extension
  "ARM_DSU_PMU" = module; # ARM DynamIQ Shared Unit (DSU) PMU
  "QCOM_L2_PMU" = yes; # Qualcomm Technologies L2-cache PMU
  "QCOM_L3_PMU" = yes; # Qualcomm Technologies L3-cache PMU
  "ARM_SPE_PMU" = module; # Enable support for the ARMv8.2 Statistical Profiling Extension
  "ARM_DMC620_PMU" = module; # Enable PMU support for the ARM DMC-620 memory controller
  "ALIBABA_UNCORE_DRW_PMU" = no; # Alibaba T-Head Yitian 710 DDR Sub-system Driveway PMU driver
  "HISI_PMU" = no; # HiSilicon SoC PMU drivers
  "HISI_PCIE_PMU" = no; # HiSilicon PCIE PERF PMU
  "HNS3_PMU" = no; # HNS3 PERF PMU
  "DWC_PCIE_PMU" = no; # Synopsys DesignWare PCIe PMU
  "ARM_CORESIGHT_PMU_ARCH_SYSTEM_PMU" = module; # ARM Coresight Architecture PMU
  "NVIDIA_CORESIGHT_PMU_ARCH_SYSTEM_PMU" = module; # NVIDIA Coresight Architecture PMU
  "AMPERE_CORESIGHT_PMU_ARCH_SYSTEM_PMU" = no; # Ampere Coresight Architecture PMU
  ### Device Drivers: end of Performance monitor support

  "RAS" = yes; # Reliability, Availability and Serviceability (RAS) features
  "USB4" = no; # Unified support for USB4 and Thunderbolt

  ### Device Drivers -> Android
  "ANDROID_BINDER_IPC" = yes; # Android Binder IPC Driver
  "ANDROID_BINDERFS" = no; # Android Binderfs filesystem
  "ANDROID_BINDER_DEVICES" = freeform "binder,hwbinder,vndbinder"; # Android Binder devices
  "ANDROID_BINDER_IPC_SELFTEST" = no; # Android Binder IPC Driver Selftest
  ### Device Drivers: end of Android

  "LIBNVDIMM" = no; # NVDIMM (Non-Volatile Memory Device) Support
  "DAX" = no; # DAX: direct access to differentiated memory
  "NVMEM" = yes; # NVMEM Support
  "NVMEM_SYSFS" = yes; # /sys/bus/nvmem/devices/*/nvmem (sysfs interface)

  #### Layout Types
  "NVMEM_LAYOUT_SL28_VPD" = module; # Kontron sl28 VPD layout support
  "NVMEM_LAYOUT_ONIE_TLV" = no; # ONIE tlv support
  "NVMEM_LAYOUT_U_BOOT_ENV" = no; # U-Boot environment variables layout
  #### end of Layout Types

  "NVMEM_QCOM_QFPROM" = yes; # QCOM QFPROM Support
  "NVMEM_QCOM_SEC_QFPROM" = module; # QCOM SECURE QFPROM Support
  "NVMEM_RMEM" = no; # Reserved Memory Based Driver Support
  "NVMEM_SPMI_SDAM" = module; # SPMI SDAM Support
  "NVMEM_STM32_ROMEM" = no; # STMicroelectronics STM32 factory-programmed memory support

  ### Device Drivers -> HW tracing support
  "STM" = module; # System Trace Module devices
  "STM_PROTO_BASIC" = no; # Basic STM framing protocol driver
  "STM_PROTO_SYS_T" = no; # MIPI SyS-T STM framing protocol driver
  "STM_DUMMY" = no; # Dummy STM driver
  "STM_SOURCE_CONSOLE" = no; # Kernel console over STM devices
  "STM_SOURCE_HEARTBEAT" = no; # Heartbeat over STM devices
  "STM_SOURCE_FTRACE" = no; # Copy the output from kernel Ftrace to STM engine
  "INTEL_TH" = no; # Intel(R) Trace Hub controller
  "HISI_PTT" = no; # HiSilicon PCIe Tune and Trace Device
  ### Device Drivers: end of HW tracing support

  "FPGA" = no; # FPGA Configuration Framework
  "FSI" = no; # FSI support
  "TEE" = yes; # Trusted Execution Environment support
  "OPTEE" = yes; # OP-TEE
  "OPTEE_INSECURE_LOAD_IMAGE" = no; # Load OP-TEE image as firmware

  ### Device Drivers -> Multiplexer drivers
  "MUX_ADG792A" = no; # Analog Devices ADG792A/ADG792G Multiplexers
  "MUX_ADGS1408" = no; # Analog Devices ADGS1408/ADGS1409 Multiplexers
  "MUX_GPIO" = module; # GPIO-controlled Multiplexer
  "MUX_MMIO" = module; # MMIO/Regmap register bitfield-controlled Multiplexer
  ### Device Drivers: end of Multiplexer drivers

  "SIOX" = no; # Eckelmann SIOX Support
  "SLIMBUS" = yes; # SLIMbus support
  "SLIM_QCOM_CTRL" = yes; # Qualcomm SLIMbus Manager Component
  "SLIM_QCOM_NGD_CTRL" = module; # Qualcomm SLIMbus Satellite Non-Generic Device Component
  "INTERCONNECT" = yes; # On-Chip Interconnect management support
  "INTERCONNECT_QCOM" = yes; # Qualcomm Network-on-Chip interconnect drivers
  "INTERCONNECT_QCOM_MSM8909" = no; # Qualcomm MSM8909 interconnect driver
  "INTERCONNECT_QCOM_MSM8916" = module; # Qualcomm MSM8916 interconnect driver
  "INTERCONNECT_QCOM_MSM8937" = no; # Qualcomm MSM8937 interconnect driver
  "INTERCONNECT_QCOM_MSM8939" = no; # Qualcomm MSM8939 interconnect driver
  "INTERCONNECT_QCOM_MSM8953" = no; # Qualcomm MSM8953 interconnect driver
  "INTERCONNECT_QCOM_MSM8974" = no; # Qualcomm MSM8974 interconnect driver
  "INTERCONNECT_QCOM_MSM8976" = no; # Qualcomm MSM8976 interconnect driver
  "INTERCONNECT_QCOM_MSM8996" = no; # Qualcomm MSM8996 interconnect driver
  "INTERCONNECT_QCOM_OSM_L3" = yes; # Qualcomm OSM L3 interconnect driver
  "INTERCONNECT_QCOM_QCM2290" = yes; # Qualcomm QCM2290 interconnect driver
  "INTERCONNECT_QCOM_QCS404" = no; # Qualcomm QCS404 interconnect driver
  "INTERCONNECT_QCOM_QCS615" = yes; # Qualcomm QCS615 interconnect driver
  "INTERCONNECT_QCOM_QCS8300" = yes; # Qualcomm QCS8300 interconnect driver
  "INTERCONNECT_QCOM_QDU1000" = yes; # Qualcomm QDU1000/QRU1000 interconnect driver
  "INTERCONNECT_QCOM_SA8775P" = yes; # Qualcomm SA8775P interconnect driver
  "INTERCONNECT_QCOM_SAR2130P" = no; # Qualcomm SAR2130P interconnect driver
  "INTERCONNECT_QCOM_SC7180" = yes; # Qualcomm SC7180 interconnect driver
  "INTERCONNECT_QCOM_SC7280" = yes; # Qualcomm SC7280 interconnect driver
  "INTERCONNECT_QCOM_SC8180X" = yes; # Qualcomm SC8180X interconnect driver
  "INTERCONNECT_QCOM_SC8280XP" = yes; # Qualcomm SC8280XP interconnect driver
  "INTERCONNECT_QCOM_SDM660" = no; # Qualcomm SDM660 interconnect driver
  "INTERCONNECT_QCOM_SDM670" = no; # Qualcomm SDM670 interconnect driver
  "INTERCONNECT_QCOM_SDM845" = yes; # Qualcomm SDM845 interconnect driver
  "INTERCONNECT_QCOM_SDX55" = no; # Qualcomm SDX55 interconnect driver
  "INTERCONNECT_QCOM_SDX65" = no; # Qualcomm SDX65 interconnect driver
  "INTERCONNECT_QCOM_SDX75" = yes; # Qualcomm SDX75 interconnect driver
  "INTERCONNECT_QCOM_SM6115" = yes; # Qualcomm SM6115 interconnect driver
  "INTERCONNECT_QCOM_SM6350" = no; # Qualcomm SM6350 interconnect driver
  "INTERCONNECT_QCOM_SM7150" = no; # Qualcomm SM7150 interconnect driver
  "INTERCONNECT_QCOM_SM8150" = yes; # Qualcomm SM8150 interconnect driver
  "INTERCONNECT_QCOM_SM8250" = yes; # Qualcomm SM8250 interconnect driver
  "INTERCONNECT_QCOM_SM8350" = yes; # Qualcomm SM8350 interconnect driver
  "INTERCONNECT_QCOM_SM8450" = yes; # Qualcomm SM8450 interconnect driver
  "INTERCONNECT_QCOM_SM8550" = yes; # Qualcomm SM8550 interconnect driver
  "INTERCONNECT_QCOM_SM8650" = yes; # Qualcomm SM8650 interconnect driver
  "INTERCONNECT_QCOM_SM8750" = yes; # Qualcomm SM8750 interconnect driver
  "INTERCONNECT_QCOM_X1E80100" = yes; # Qualcomm X1E80100 interconnect driver
  "COUNTER" = module; # Counter support
  "INTERRUPT_CNT" = no; # Interrupt counter driver
  "STM32_LPTIMER_CNT" = no; # STM32 LP Timer encoder counter driver
  "MOST" = no; # MOST (Media Oriented Systems Transport) support
  "PECI" = no; # PECI support
  "HTE" = yes; # Hardware Timestamping Engine (HTE) Support
  "CDX_BUS" = no; # CDX Bus driver
  ## end of Device Drivers

  ## File systems
  "VALIDATE_FS_PARSER" = no; # Validate filesystem parameter description
  "EXT2_FS" = no; # Second extended fs support (DEPRECATED)
  "EXT3_FS" = no; # The Extended 3 (ext3) filesystem
  "EXT4_FS" = yes; # The Extended 4 (ext4) filesystem
  "EXT4_USE_FOR_EXT2" = yes; # Use ext4 for ext2 file systems
  "EXT4_FS_POSIX_ACL" = yes; # Ext4 POSIX Access Control Lists
  "EXT4_FS_SECURITY" = yes; # Ext4 Security Labels
  "EXT4_DEBUG" = no; # Ext4 debugging support
  "JBD2_DEBUG" = no; # JBD2 (ext4) debugging support
  "JFS_FS" = no; # JFS filesystem support
  "XFS_FS" = module; # XFS filesystem support
  "XFS_SUPPORT_V4" = yes; # Support deprecated V4 (crc=0) format
  "XFS_SUPPORT_ASCII_CI" = yes; # Support deprecated case-insensitive ascii (ascii-ci=1) format
  "XFS_QUOTA" = no; # XFS Quota support
  "XFS_POSIX_ACL" = no; # XFS POSIX ACL support
  "XFS_RT" = no; # XFS Realtime subvolume support
  "XFS_ONLINE_SCRUB" = no; # XFS online metadata check support
  "XFS_WARN" = no; # XFS Verbose Warnings
  "XFS_DEBUG" = no; # XFS Debugging support
  "GFS2_FS" = no; # GFS2 file system support
  "OCFS2_FS" = no; # OCFS2 file system support
  "BTRFS_FS" = yes; # Btrfs filesystem support
  "BTRFS_FS_POSIX_ACL" = yes; # Btrfs POSIX Access Control Lists
  "BTRFS_FS_RUN_SANITY_TESTS" = no; # Btrfs will run sanity tests upon loading
  "BTRFS_DEBUG" = no; # Btrfs debugging support
  "BTRFS_ASSERT" = no; # Btrfs assert support
  "BTRFS_EXPERIMENTAL" = no; # Btrfs experimental features
  "BTRFS_FS_REF_VERIFY" = no; # Btrfs with the ref verify tool compiled in
  "NILFS2_FS" = no; # NILFS2 file system support
  "F2FS_FS" = yes; # F2FS filesystem support
  "F2FS_STAT_FS" = yes; # F2FS Status Information
  "F2FS_FS_XATTR" = yes; # F2FS extended attributes
  "F2FS_FS_POSIX_ACL" = yes; # F2FS Access Control Lists
  "F2FS_FS_SECURITY" = no; # F2FS Security Labels
  "F2FS_CHECK_FS" = no; # F2FS consistency checking feature
  "F2FS_FAULT_INJECTION" = no; # F2FS fault injection facility
  "F2FS_FS_COMPRESSION" = no; # F2FS compression feature
  "F2FS_IOSTAT" = yes; # F2FS IO statistics information
  "F2FS_UNFAIR_RWSEM" = no; # F2FS unfair rw_semaphore
  "BCACHEFS_FS" = no; # bcachefs filesystem support (EXPERIMENTAL)
  "EXPORTFS_BLOCK_OPS" = no; # Enable filesystem export operations for block IO
  "FS_ENCRYPTION" = yes; # FS Encryption (Per-file encryption)
  "FS_ENCRYPTION_INLINE_CRYPT" = yes; # Enable fscrypt to use inline crypto
  "FS_VERITY" = no; # FS Verity (read-only file-based authenticity protection)
  "DNOTIFY" = yes; # Dnotify support
  "INOTIFY_USER" = yes; # Inotify support for userspace
  "FANOTIFY" = yes; # Filesystem wide access notification
  "FANOTIFY_ACCESS_PERMISSIONS" = yes; # fanotify permissions checking
  "QUOTA" = yes; # Quota support
  "QUOTA_NETLINK_INTERFACE" = no; # Report quota messages through netlink interface
  "QUOTA_DEBUG" = no; # Additional quota sanity checks
  "QFMT_V1" = no; # Old quota format support
  "QFMT_V2" = yes; # Quota format vfsv0 and vfsv1 support
  "AUTOFS_FS" = yes; # Kernel automounter support (supports v3, v4 and v5)
  "FUSE_FS" = module; # FUSE (Filesystem in Userspace) support
  "CUSE" = module; # Character device in Userspace support
  "VIRTIO_FS" = no; # Virtio Filesystem
  "FUSE_PASSTHROUGH" = yes; # FUSE passthrough operations support
  "FUSE_IO_URING" = yes; # FUSE communication over io-uring
  "OVERLAY_FS" = module; # Overlay filesystem support
  "OVERLAY_FS_REDIRECT_DIR" = no; # Overlayfs: turn on redirect directory feature by default
  "OVERLAY_FS_REDIRECT_ALWAYS_FOLLOW" = yes; # Overlayfs: follow redirects even if redirects are turned off
  "OVERLAY_FS_INDEX" = no; # Overlayfs: turn on inodes index feature by default
  "OVERLAY_FS_XINO_AUTO" = no; # Overlayfs: auto enable inode number mapping
  "OVERLAY_FS_METACOPY" = no; # Overlayfs: turn on metadata only copy up feature by default
  "OVERLAY_FS_DEBUG" = no; # Overlayfs: turn on extra debugging checks

  ### File systems -> Caches
  "NETFS_STATS" = no; # Gather statistical information on local caching
  "NETFS_DEBUG" = no; # Enable dynamic debugging netfslib and FS-Cache
  "FSCACHE" = no; # General filesystem local caching manager
  ### File systems: end of Caches

  ### File systems -> CD-ROM/DVD Filesystems
  "ISO9660_FS" = no; # ISO 9660 CDROM file system support
  "UDF_FS" = module; # UDF file system support
  ### File systems: end of CD-ROM/DVD Filesystems

  ### File systems -> DOS/FAT/EXFAT/NT Filesystems
  "MSDOS_FS" = no; # MSDOS fs support
  "VFAT_FS" = yes; # VFAT (Windows-95) fs support
  "FAT_DEFAULT_CODEPAGE" = freeform "437"; # Default codepage for FAT
  "FAT_DEFAULT_IOCHARSET" = freeform "iso8859-1"; # Default iocharset for FAT
  "FAT_DEFAULT_UTF8" = yes; # Enable FAT UTF-8 option by default
  "EXFAT_FS" = module; # exFAT filesystem support
  "EXFAT_DEFAULT_IOCHARSET" = freeform "utf8"; # Default iocharset for exFAT
  "NTFS3_FS" = no; # NTFS Read-Write file system support
  "NTFS_FS" = no; # NTFS file system support
  ### File systems: end of DOS/FAT/EXFAT/NT Filesystems

  ### File systems -> Pseudo filesystems
  "PROC_FS" = yes; # /proc file system support
  "PROC_KCORE" = no; # /proc/kcore support
  "PROC_VMCORE" = yes; # /proc/vmcore support
  "PROC_VMCORE_DEVICE_DUMP" = no; # Device Hardware/Firmware Log Collection
  "PROC_CHILDREN" = yes; # Include /proc/<pid>/task/<tid>/children file
  "TMPFS" = yes; # Tmpfs virtual memory file system support (former shm fs)
  "TMPFS_POSIX_ACL" = yes; # Tmpfs POSIX Access Control Lists
  "TMPFS_XATTR" = yes; # Tmpfs extended attributes
  "TMPFS_INODE64" = no; # Use 64-bit ino_t by default in tmpfs
  "TMPFS_QUOTA" = no; # Tmpfs quota support
  "HUGETLBFS" = yes; # HugeTLB file system support
  "CONFIGFS_FS" = yes; # Userspace-driven configuration filesystem
  "EFIVAR_FS" = yes; # EFI Variable filesystem
  ### File systems: end of Pseudo filesystems

  "MISC_FILESYSTEMS" = yes; # Miscellaneous filesystems
  "ORANGEFS_FS" = no; # ORANGEFS (Powered by PVFS) support
  "ADFS_FS" = no; # ADFS file system support
  "AFFS_FS" = no; # Amiga FFS file system support
  "ECRYPT_FS" = no; # eCrypt filesystem layer support
  "HFS_FS" = no; # Apple Macintosh file system support
  "HFSPLUS_FS" = no; # Apple Extended HFS file system support
  "BEFS_FS" = no; # BeOS file system (BeFS) support (read only)
  "BFS_FS" = no; # BFS file system support
  "EFS_FS" = no; # EFS file system support (read only)
  "CRAMFS" = no; # Compressed ROM file system support (cramfs)
  "SQUASHFS" = yes; # SquashFS 4.0 - Squashed file system support
  "SQUASHFS_FILE_CACHE" = yes; # Decompress file data into an intermediate buffer
  "SQUASHFS_FILE_DIRECT" = no; # Decompress files directly into the page cache
  "SQUASHFS_CHOICE_DECOMP_BY_MOUNT" = no; # Select the parallel decompression mode during mount
  "SQUASHFS_COMPILE_DECOMP_SINGLE" = yes; # Single threaded compression
  "SQUASHFS_COMPILE_DECOMP_MULTI" = no; # Use multiple decompressors for parallel I/O
  "SQUASHFS_COMPILE_DECOMP_MULTI_PERCPU" = no; # Use percpu multiple decompressors for parallel I/O
  "SQUASHFS_XATTR" = yes; # Squashfs XATTR support
  "SQUASHFS_COMP_CACHE_FULL" = no; # Enable full caching of compressed blocks
  "SQUASHFS_ZLIB" = yes; # Include support for ZLIB compressed file systems
  "SQUASHFS_LZ4" = yes; # Include support for LZ4 compressed file systems
  "SQUASHFS_LZO" = yes; # Include support for LZO compressed file systems
  "SQUASHFS_XZ" = yes; # Include support for XZ compressed file systems
  "SQUASHFS_ZSTD" = no; # Include support for ZSTD compressed file systems
  "SQUASHFS_4K_DEVBLK_SIZE" = no; # Use 4K device block size?
  "SQUASHFS_EMBEDDED" = no; # Additional option for memory-constrained systems
  "VXFS_FS" = no; # FreeVxFS file system support (VERITAS VxFS(TM) compatible)
  "MINIX_FS" = no; # Minix file system support
  "OMFS_FS" = no; # SonicBlue Optimized MPEG File System support
  "HPFS_FS" = no; # OS/2 HPFS file system support
  "QNX4FS_FS" = no; # QNX4 file system support (read only)
  "QNX6FS_FS" = no; # QNX6 file system support (read only)
  "ROMFS_FS" = no; # ROM file system support
  "PSTORE" = yes; # Persistent store support
  "PSTORE_COMPRESS" = yes; # Pstore compression (deflate)
  "PSTORE_CONSOLE" = yes; # Log kernel console messages
  "PSTORE_PMSG" = yes; # Log user space messages
  "PSTORE_FTRACE" = no; # Persistent function tracer
  "PSTORE_RAM" = yes; # Log panic/oops to a RAM buffer
  "PSTORE_BLK" = no; # Log panic/oops to a block device
  "UFS_FS" = no; # UFS file system support (read only)
  "EROFS_FS" = no; # EROFS filesystem support
  "NETWORK_FILESYSTEMS" = yes; # Network File Systems
  "NFS_FS" = yes; # NFS client support
  "NFS_V2" = no; # NFS client support for NFS version 2
  "NFS_V3" = yes; # NFS client support for NFS version 3
  "NFS_V3_ACL" = no; # NFS client support for the NFSv3 ACL protocol extension
  "NFS_V4" = yes; # NFS client support for NFS version 4
  "NFS_SWAP" = no; # Provide swap over NFS support
  "NFS_V4_1" = yes; # NFS client support for NFSv4.1
  "NFS_V4_2" = yes; # NFS client support for NFSv4.2
  "NFS_V4_1_IMPLEMENTATION_ID_DOMAIN" = freeform "kernel.org"; # NFSv4.1 Implementation ID Domain
  "NFS_V4_1_MIGRATION" = no; # NFSv4.1 client support for migration
  "ROOT_NFS" = yes; # Root file system on NFS
  "NFS_FSCACHE" = no; # Provide NFS client caching support
  "NFS_USE_LEGACY_DNS" = no; # Use the legacy NFS DNS resolver
  "NFS_DISABLE_UDP_SUPPORT" = yes; # NFS: Disable NFS UDP protocol support
  "NFS_V4_2_READ_PLUS" = yes; # NFS: Enable support for the NFSv4.2 READ_PLUS operation
  "NFSD" = no; # NFS server support
  "RPCSEC_GSS_KRB5" = yes; # Secure RPC: Kerberos V mechanism
  "RPCSEC_GSS_KRB5_ENCTYPES_AES_SHA1" = yes; # Enable Kerberos enctypes based on AES and SHA-1
  "RPCSEC_GSS_KRB5_ENCTYPES_AES_SHA2" = no; # Enable Kerberos enctypes based on AES and SHA-2
  "SUNRPC_DEBUG" = no; # RPC: Enable dprintk debugging
  "CEPH_FS" = no; # Ceph distributed file system
  "CIFS" = yes; # SMB3 and CIFS support (advanced network filesystem)
  "CIFS_STATS2" = yes; # Extended statistics
  "CIFS_ALLOW_INSECURE_LEGACY" = yes; # Support legacy servers which use less secure dialects
  "CIFS_UPCALL" = no; # Kerberos/SPNEGO advanced session setup
  "CIFS_XATTR" = no; # CIFS extended attributes
  "CIFS_DEBUG" = yes; # Enable CIFS debugging routines
  "CIFS_DEBUG2" = no; # Enable additional CIFS debugging routines
  "CIFS_DEBUG_DUMP_KEYS" = no; # Dump encryption keys for offline decryption (Unsafe)
  "CIFS_DFS_UPCALL" = no; # DFS feature support
  "CIFS_SWN_UPCALL" = no; # SWN feature support
  "CIFS_ROOT" = no; # SMB root file system (Experimental)
  "CIFS_COMPRESSION" = no; # SMB message compression (Experimental)
  "SMB_SERVER" = no; # SMB3 server support
  "CODA_FS" = no; # Coda file system support (advanced network fs)
  "AFS_FS" = no; # Andrew File System support (AFS)
  "NLS" = yes; # Native language support
  "NLS_DEFAULT" = freeform "utf8"; # Default NLS Option
  "NLS_CODEPAGE_437" = yes; # Codepage 437 (United States, Canada)
  "NLS_CODEPAGE_737" = no; # Codepage 737 (Greek)
  "NLS_CODEPAGE_775" = no; # Codepage 775 (Baltic Rim)
  "NLS_CODEPAGE_850" = no; # Codepage 850 (Europe)
  "NLS_CODEPAGE_852" = no; # Codepage 852 (Central/Eastern Europe)
  "NLS_CODEPAGE_855" = no; # Codepage 855 (Cyrillic)
  "NLS_CODEPAGE_857" = no; # Codepage 857 (Turkish)
  "NLS_CODEPAGE_860" = no; # Codepage 860 (Portuguese)
  "NLS_CODEPAGE_861" = no; # Codepage 861 (Icelandic)
  "NLS_CODEPAGE_862" = no; # Codepage 862 (Hebrew)
  "NLS_CODEPAGE_863" = no; # Codepage 863 (Canadian French)
  "NLS_CODEPAGE_864" = no; # Codepage 864 (Arabic)
  "NLS_CODEPAGE_865" = no; # Codepage 865 (Norwegian, Danish)
  "NLS_CODEPAGE_866" = no; # Codepage 866 (Cyrillic/Russian)
  "NLS_CODEPAGE_869" = no; # Codepage 869 (Greek)
  "NLS_CODEPAGE_936" = no; # Simplified Chinese charset (CP936, GB2312)
  "NLS_CODEPAGE_950" = no; # Traditional Chinese charset (Big5)
  "NLS_CODEPAGE_932" = no; # Japanese charsets (Shift-JIS, EUC-JP)
  "NLS_CODEPAGE_949" = no; # Korean charset (CP949, EUC-KR)
  "NLS_CODEPAGE_874" = no; # Thai charset (CP874, TIS-620)
  "NLS_ISO8859_8" = no; # Hebrew charsets (ISO-8859-8, CP1255)
  "NLS_CODEPAGE_1250" = no; # Windows CP1250 (Slavic/Central European Languages)
  "NLS_CODEPAGE_1251" = no; # Windows CP1251 (Bulgarian, Belarusian)
  "NLS_ASCII" = yes; # ASCII (United States)
  "NLS_ISO8859_1" = yes; # NLS ISO 8859-1  (Latin 1; Western European Languages)
  "NLS_ISO8859_2" = no; # NLS ISO 8859-2  (Latin 2; Slavic/Central European Languages)
  "NLS_ISO8859_3" = no; # NLS ISO 8859-3  (Latin 3; Esperanto, Galician, Maltese, Turkish)
  "NLS_ISO8859_4" = no; # NLS ISO 8859-4  (Latin 4; old Baltic charset)
  "NLS_ISO8859_5" = no; # NLS ISO 8859-5  (Cyrillic)
  "NLS_ISO8859_6" = no; # NLS ISO 8859-6  (Arabic)
  "NLS_ISO8859_7" = no; # NLS ISO 8859-7  (Modern Greek)
  "NLS_ISO8859_9" = no; # NLS ISO 8859-9  (Latin 5; Turkish)
  "NLS_ISO8859_13" = no; # NLS ISO 8859-13 (Latin 7; Baltic)
  "NLS_ISO8859_14" = no; # NLS ISO 8859-14 (Latin 8; Celtic)
  "NLS_ISO8859_15" = no; # NLS ISO 8859-15 (Latin 9; Western European Languages with Euro)
  "NLS_KOI8_R" = no; # NLS KOI8-R (Russian)
  "NLS_KOI8_U" = no; # NLS KOI8-U/RU (Ukrainian, Belarusian)
  "NLS_MAC_ROMAN" = no; # Codepage macroman
  "NLS_MAC_CELTIC" = no; # Codepage macceltic
  "NLS_MAC_CENTEURO" = no; # Codepage maccenteuro
  "NLS_MAC_CROATIAN" = no; # Codepage maccroatian
  "NLS_MAC_CYRILLIC" = no; # Codepage maccyrillic
  "NLS_MAC_GAELIC" = no; # Codepage macgaelic
  "NLS_MAC_GREEK" = no; # Codepage macgreek
  "NLS_MAC_ICELAND" = no; # Codepage maciceland
  "NLS_MAC_INUIT" = no; # Codepage macinuit
  "NLS_MAC_ROMANIAN" = no; # Codepage macromanian
  "NLS_MAC_TURKISH" = no; # Codepage macturkish
  "NLS_UTF8" = yes; # NLS UTF-8
  "DLM" = no; # Distributed Lock Manager (DLM)
  "UNICODE" = no; # UTF-8 normalization and casefolding support
  ## end of File systems

  ## Security options
  "KEYS" = yes; # Enable access key retention support
  "KEYS_REQUEST_CACHE" = no; # Enable temporary caching of the last request_key() result
  "PERSISTENT_KEYRINGS" = no; # Enable register of persistent per-UID keyrings
  "BIG_KEYS" = no; # Large payload keys
  "TRUSTED_KEYS" = no; # TRUSTED KEYS
  "ENCRYPTED_KEYS" = no; # ENCRYPTED KEYS
  "KEY_DH_OPERATIONS" = yes; # Diffie-Hellman operations on retained keys
  "SECURITY_DMESG_RESTRICT" = no; # Restrict unprivileged access to the kernel syslog
  "PROC_MEM_ALWAYS_FORCE" = yes; # Traditional /proc/pid/mem behavior
  "PROC_MEM_FORCE_PTRACE" = no; # Require active ptrace() use for access override
  "PROC_MEM_NO_FORCE" = no; # Never
  "SECURITY" = yes; # Enable different security models
  "SECURITYFS" = yes; # Enable the securityfs filesystem
  "SECURITY_NETWORK" = no; # Socket and Networking Security Hooks
  "SECURITY_PATH" = no; # Security hooks for pathname based access control
  "STATIC_USERMODEHELPER" = no; # Force all usermode helper calls through a single binary
  "SECURITY_SMACK" = no; # Simplified Mandatory Access Control Kernel Support
  "SECURITY_TOMOYO" = no; # TOMOYO Linux Support
  "SECURITY_APPARMOR" = no; # AppArmor support
  "SECURITY_LOADPIN" = no; # Pin load of kernel files (modules, fw, etc) to one filesystem
  "SECURITY_YAMA" = no; # Yama support
  "SECURITY_SAFESETID" = no; # Gate setid transitions to limit CAP_SET{U/G}ID capabilities
  "SECURITY_LOCKDOWN_LSM" = no; # Basic module for enforcing kernel lockdown
  "SECURITY_LANDLOCK" = no; # Landlock support
  "SECURITY_IPE" = no; # Integrity Policy Enforcement (IPE)
  "INTEGRITY" = yes; # Integrity subsystem
  "INTEGRITY_SIGNATURE" = no; # Digital signature verification using multiple keyrings
  "INTEGRITY_AUDIT" = yes; # Enables integrity auditing support
  "IMA" = no; # Integrity Measurement Architecture(IMA)
  "EVM" = no; # EVM support
  "DEFAULT_SECURITY_DAC" = yes; # Unix Discretionary Access Controls
  "LSM" = freeform "landlock,lockdown,yama,loadpin,safesetid,ipe,bpf"; # Ordered list of enabled LSMs

  ### Security options -> Kernel hardening options

  #### Security options -> Kernel hardening options -> Memory initialization
  "INIT_STACK_NONE" = no; # no automatic stack variable initialization (weakest)
  "INIT_STACK_ALL_PATTERN" = no; # pattern-init everything (strongest)
  "INIT_STACK_ALL_ZERO" = yes; # zero-init everything (strongest and safest)
  "GCC_PLUGIN_STACKLEAK" = no; # Poison kernel stack before returning from syscalls
  "INIT_ON_ALLOC_DEFAULT_ON" = no; # Enable heap memory zeroing on allocation by default
  "INIT_ON_FREE_DEFAULT_ON" = no; # Enable heap memory zeroing on free by default
  "ZERO_CALL_USED_REGS" = no; # Enable register zeroing on function exit
  #### Security options -> Kernel hardening options: end of Memory initialization

  #### Security options -> Kernel hardening options -> Bounds checking
  "FORTIFY_SOURCE" = no; # Harden common str/mem functions against buffer overflows
  "HARDENED_USERCOPY" = no; # Harden memory copies between kernel and userspace
  #### Security options -> Kernel hardening options: end of Bounds checking

  #### Security options -> Kernel hardening options -> Hardening of kernel data structures
  "LIST_HARDENED" = no; # Check integrity of linked list manipulation
  "BUG_ON_DATA_CORRUPTION" = no; # Trigger a BUG when data corruption is detected
  #### Security options -> Kernel hardening options: end of Hardening of kernel data structures

  "RANDSTRUCT_NONE" = yes; # Disable structure layout randomization
  "RANDSTRUCT_FULL" = no; # Fully randomize structure layout
  "RANDSTRUCT_PERFORMANCE" = no; # Limit randomization of structure layout to cache-lines
  ### Security options: end of Kernel hardening options
  ## end of Security options

  "CRYPTO" = yes; # Cryptographic API

  ### Crypto core or helper
  "CRYPTO_USER" = yes; # Userspace cryptographic algorithm configuration
  "CRYPTO_SELFTESTS" = no; # Enable cryptographic self-tests
  "CRYPTO_NULL" = no; # Null algorithms
  "CRYPTO_PCRYPT" = no; # Parallel crypto engine
  "CRYPTO_CRYPTD" = no; # Software async crypto daemon
  "CRYPTO_AUTHENC" = yes; # Authenc support
  "CRYPTO_KRB5ENC" = no; # Kerberos 5 combined hash+cipher support
  "CRYPTO_BENCHMARK" = module; # Crypto benchmarking module
  ### end of Crypto core or helper

  ### Public-key cryptography
  "CRYPTO_RSA" = yes; # RSA (Rivest-Shamir-Adleman)
  "CRYPTO_DH" = yes; # DH (Diffie-Hellman)
  "CRYPTO_DH_RFC7919_GROUPS" = no; # RFC 7919 FFDHE groups
  "CRYPTO_ECDH" = module; # ECDH (Elliptic Curve Diffie-Hellman)
  "CRYPTO_ECDSA" = no; # ECDSA (Elliptic Curve Digital Signature Algorithm)
  "CRYPTO_ECRDSA" = no; # EC-RDSA (Elliptic Curve Russian Digital Signature Algorithm)
  "CRYPTO_CURVE25519" = module; # Curve25519
  ### end of Public-key cryptography

  ### Block ciphers
  "CRYPTO_AES" = yes; # AES (Advanced Encryption Standard)
  "CRYPTO_AES_TI" = no; # AES (Advanced Encryption Standard) (fixed time)
  "CRYPTO_ANUBIS" = no; # Anubis
  "CRYPTO_ARIA" = no; # ARIA
  "CRYPTO_BLOWFISH" = no; # Blowfish
  "CRYPTO_CAMELLIA" = no; # Camellia
  "CRYPTO_CAST5" = no; # CAST5 (CAST-128)
  "CRYPTO_CAST6" = no; # CAST6 (CAST-256)
  "CRYPTO_DES" = module; # DES and Triple DES EDE
  "CRYPTO_FCRYPT" = no; # FCrypt
  "CRYPTO_KHAZAD" = no; # Khazad
  "CRYPTO_SEED" = no; # SEED
  "CRYPTO_SERPENT" = no; # Serpent
  "CRYPTO_SM4_GENERIC" = module; # SM4 (ShangMi 4)
  "CRYPTO_TEA" = no; # TEA, XTEA and XETA
  "CRYPTO_TWOFISH" = no; # Twofish
  ### end of Block ciphers

  ### Length-preserving ciphers and modes
  "CRYPTO_ADIANTUM" = no; # Adiantum
  "CRYPTO_ARC4" = no; # ARC4 (Alleged Rivest Cipher 4)
  "CRYPTO_CHACHA20" = module; # ChaCha
  "CRYPTO_CBC" = yes; # CBC (Cipher Block Chaining)
  "CRYPTO_CTR" = yes; # CTR (Counter)
  "CRYPTO_CTS" = yes; # CTS (Cipher Text Stealing)
  "CRYPTO_ECB" = yes; # ECB (Electronic Codebook)
  "CRYPTO_HCTR2" = no; # HCTR2
  "CRYPTO_LRW" = no; # LRW (Liskov Rivest Wagner)
  "CRYPTO_PCBC" = no; # PCBC (Propagating Cipher Block Chaining)
  "CRYPTO_XTS" = yes; # XTS (XOR Encrypt XOR with ciphertext stealing)
  ### end of Length-preserving ciphers and modes

  ### AEAD (authenticated encryption with associated data) ciphers
  "CRYPTO_AEGIS128" = no; # AEGIS-128
  "CRYPTO_CHACHA20POLY1305" = no; # ChaCha20-Poly1305
  "CRYPTO_CCM" = yes; # CCM (Counter with Cipher Block Chaining-MAC)
  "CRYPTO_GCM" = yes; # GCM (Galois/Counter Mode) and GMAC (GCM MAC)
  "CRYPTO_SEQIV" = no; # Sequence Number IV Generator
  "CRYPTO_ECHAINIV" = yes; # Encrypted Chain IV Generator
  "CRYPTO_ESSIV" = yes; # Encrypted Salt-Sector IV Generator
  ### end of AEAD (authenticated encryption with associated data) ciphers

  ### Hashes, digests, and MACs
  "CRYPTO_BLAKE2B" = yes; # BLAKE2b
  "CRYPTO_CMAC" = yes; # CMAC (Cipher-based MAC)
  "CRYPTO_GHASH" = yes; # GHASH
  "CRYPTO_HMAC" = yes; # HMAC (Keyed-Hash MAC)
  "CRYPTO_MD4" = module; # MD4
  "CRYPTO_MD5" = yes; # MD5
  "CRYPTO_MICHAEL_MIC" = module; # Michael MIC
  "CRYPTO_RMD160" = no; # RIPEMD-160
  "CRYPTO_SHA1" = yes; # SHA-1
  "CRYPTO_SHA256" = yes; # SHA-224 and SHA-256
  "CRYPTO_SHA512" = yes; # SHA-384 and SHA-512
  "CRYPTO_SHA3" = yes; # SHA-3
  "CRYPTO_SM3_GENERIC" = module; # SM3 (ShangMi 3)
  "CRYPTO_STREEBOG" = no; # Streebog
  "CRYPTO_WP512" = no; # Whirlpool
  "CRYPTO_XCBC" = no; # XCBC-MAC (Extended Cipher Block Chaining MAC)
  "CRYPTO_XXHASH" = yes; # xxHash
  ### end of Hashes, digests, and MACs

  ### CRCs (cyclic redundancy checks)
  "CRYPTO_CRC32C" = yes; # CRC32c
  "CRYPTO_CRC32" = no; # CRC32
  ### end of CRCs (cyclic redundancy checks)

  ### Compression
  "CRYPTO_DEFLATE" = module; # Deflate
  "CRYPTO_LZO" = module; # LZO
  "CRYPTO_842" = no; # 842
  "CRYPTO_LZ4" = module; # LZ4
  "CRYPTO_LZ4HC" = no; # LZ4HC
  "CRYPTO_ZSTD" = module; # Zstd
  ### end of Compression

  ### Random number generation
  "CRYPTO_ANSI_CPRNG" = yes; # ANSI PRNG (Pseudo Random Number Generator)
  "CRYPTO_DRBG_MENU" = yes; # NIST SP800-90A DRBG (Deterministic Random Bit Generator)
  "CRYPTO_DRBG_HASH" = no; # Hash_DRBG
  "CRYPTO_DRBG_CTR" = no; # CTR_DRBG
  "CRYPTO_JITTERENTROPY" = yes; # CPU Jitter Non-Deterministic RNG (Random Number Generator)
  ### end of Random number generation

  ### Userspace interface
  "CRYPTO_USER_API_HASH" = module; # Hash algorithms
  "CRYPTO_USER_API_SKCIPHER" = module; # Symmetric key cipher algorithms
  "CRYPTO_USER_API_RNG" = module; # RNG (random number generator) algorithms
  "CRYPTO_USER_API_RNG_CAVP" = no; # Enable CAVP testing of DRBG
  "CRYPTO_USER_API_AEAD" = yes; # AEAD cipher algorithms
  "CRYPTO_USER_API_ENABLE_OBSOLETE" = yes; # Obsolete cryptographic algorithms
  ### end of Userspace interface

  ### Accelerated Cryptographic Algorithms for CPU (arm64)
  "CRYPTO_GHASH_ARM64_CE" = yes; # Hash functions: GHASH (ARMv8 Crypto Extensions)
  "CRYPTO_NHPOLY1305_NEON" = no; # Hash functions: NHPoly1305 (NEON)
  "CRYPTO_SHA1_ARM64_CE" = yes; # Hash functions: SHA-1 (ARMv8 Crypto Extensions)
  "CRYPTO_SHA512_ARM64" = module; # Hash functions: SHA-384 and SHA-512
  "CRYPTO_SHA512_ARM64_CE" = module; # Hash functions: SHA-384 and SHA-512 (ARMv8 Crypto Extensions)
  "CRYPTO_SHA3_ARM64" = module; # Hash functions: SHA-3 (ARMv8.2 Crypto Extensions)
  "CRYPTO_SM3_NEON" = no; # Hash functions: SM3 (NEON)
  "CRYPTO_SM3_ARM64_CE" = module; # Hash functions: SM3 (ARMv8.2 Crypto Extensions)
  "CRYPTO_POLYVAL_ARM64_CE" = no; # Hash functions: POLYVAL (ARMv8 Crypto Extensions)
  "CRYPTO_AES_ARM64" = no; # Ciphers: AES, modes: ECB, CBC, CTR, CTS, XCTR, XTS
  "CRYPTO_AES_ARM64_CE" = yes; # Ciphers: AES (ARMv8 Crypto Extensions)
  "CRYPTO_AES_ARM64_CE_BLK" = yes; # Ciphers: AES, modes: ECB/CBC/CTR/XTS (ARMv8 Crypto Extensions)
  "CRYPTO_AES_ARM64_NEON_BLK" = module; # Ciphers: AES, modes: ECB/CBC/CTR/XTS (NEON)
  "CRYPTO_AES_ARM64_BS" = module; # Ciphers: AES, modes: ECB/CBC/CTR/XCTR/XTS modes (bit-sliced NEON)
  "CRYPTO_SM4_ARM64_CE" = no; # Ciphers: SM4 (ARMv8.2 Crypto Extensions)
  "CRYPTO_SM4_ARM64_CE_BLK" = no; # Ciphers: SM4, modes: ECB/CBC/CTR/XTS (ARMv8 Crypto Extensions)
  "CRYPTO_SM4_ARM64_NEON_BLK" = no; # Ciphers: SM4, modes: ECB/CBC/CTR (NEON)
  "CRYPTO_AES_ARM64_CE_CCM" = yes; # AEAD cipher: AES in CCM mode (ARMv8 Crypto Extensions)
  "CRYPTO_SM4_ARM64_CE_CCM" = no; # AEAD cipher: SM4 in CCM mode (ARMv8 Crypto Extensions)
  "CRYPTO_SM4_ARM64_CE_GCM" = no; # AEAD cipher: SM4 in GCM mode (ARMv8 Crypto Extensions)
  ### end of Accelerated Cryptographic Algorithms for CPU (arm64)

  "CRYPTO_HW" = yes; # Hardware crypto devices
  "CRYPTO_DEV_ATMEL_ECC" = no; # Support for Microchip / Atmel ECC hw accelerator
  "CRYPTO_DEV_ATMEL_SHA204A" = no; # Support for Microchip / Atmel SHA accelerator and RNG
  "CRYPTO_DEV_CCP" = no; # Support for AMD Secure Processor
  "CRYPTO_DEV_NITROX_CNN55XX" = no; # Support for Cavium CNN55XX driver
  "CRYPTO_DEV_QAT_DH895xCC" = no; # Support for Intel(R) DH895xCC
  "CRYPTO_DEV_QAT_C3XXX" = no; # Support for Intel(R) C3XXX
  "CRYPTO_DEV_QAT_C62X" = no; # Support for Intel(R) C62X
  "CRYPTO_DEV_QAT_4XXX" = no; # Support for Intel(R) QAT_4XXX
  "CRYPTO_DEV_QAT_420XX" = no; # Support for Intel(R) QAT_420XX
  "CRYPTO_DEV_QAT_DH895xCCVF" = no; # Support for Intel(R) DH895xCC Virtual Function
  "CRYPTO_DEV_QAT_C3XXXVF" = no; # Support for Intel(R) C3XXX Virtual Function
  "CRYPTO_DEV_QAT_C62XVF" = no; # Support for Intel(R) C62X Virtual Function
  "CRYPTO_DEV_QCE" = yes; # Qualcomm crypto engine accelerator
  "CRYPTO_DEV_QCE_ENABLE_ALL" = yes; # All supported algorithms
  "CRYPTO_DEV_QCE_ENABLE_SKCIPHER" = no; # Symmetric-key ciphers only
  "CRYPTO_DEV_QCE_ENABLE_SHA" = no; # Hash/HMAC only
  "CRYPTO_DEV_QCE_ENABLE_AEAD" = no; # AEAD algorithms only
  "CRYPTO_DEV_QCE_SW_MAX_LEN" = freeform "512"; # Default maximum request size to use software for AES
  "CRYPTO_DEV_QCOM_RNG" = module; # Qualcomm Random Number Generator Driver
  "CRYPTO_DEV_VIRTIO" = no; # VirtIO crypto driver
  "CRYPTO_DEV_STM32_CRC" = no; # Support for STM32 crc accelerators
  "CRYPTO_DEV_STM32_HASH" = no; # Support for STM32 hash accelerators
  "CRYPTO_DEV_STM32_CRYP" = no; # Support for STM32 cryp accelerators
  "CRYPTO_DEV_SAFEXCEL" = no; # Inside Secure's SafeXcel cryptographic engine driver
  "CRYPTO_DEV_CCREE" = no; # Support for ARM TrustZone CryptoCell family of security processors
  "CRYPTO_DEV_HISI_SEC" = no; # Support for Hisilicon SEC crypto block cipher accelerator
  "CRYPTO_DEV_HISI_SEC2" = module; # Support for HiSilicon SEC2 crypto block cipher accelerator
  "CRYPTO_DEV_HISI_ZIP" = module; # Support for HiSilicon ZIP accelerator
  "CRYPTO_DEV_HISI_HPRE" = module; # Support for HISI HPRE accelerator
  "CRYPTO_DEV_HISI_TRNG" = module; # Support for HISI TRNG Driver
  "CRYPTO_DEV_AMLOGIC_GXL" = module; # Support for amlogic cryptographic offloader
  "CRYPTO_DEV_AMLOGIC_GXL_DEBUG" = no; # Enable amlogic stats
  "CRYPTO_DEV_EIP93" = no; # Support for EIP93 crypto HW accelerators
  "ASYMMETRIC_KEY_TYPE" = yes; # Asymmetric (public-key cryptographic) key type
  "ASYMMETRIC_PUBLIC_KEY_SUBTYPE" = yes; # Asymmetric public-key crypto algorithm subtype
  "X509_CERTIFICATE_PARSER" = yes; # X.509 certificate parser
  "PKCS8_PRIVATE_KEY_PARSER" = yes; # PKCS#8 private key parser
  "PKCS7_MESSAGE_PARSER" = yes; # PKCS#7 message parser
  "PKCS7_TEST_KEY" = no; # PKCS#7 testing key type
  "SIGNED_PE_FILE_VERIFICATION" = no; # Support for PE file signature verification
  "FIPS_SIGNATURE_SELFTEST" = no; # Run FIPS selftests on the X.509+PKCS7 signature verification

  ### Certificates for signature checking
  "SYSTEM_TRUSTED_KEYRING" = yes; # Provide system-wide ring of trusted keys
  "SYSTEM_EXTRA_CERTIFICATE" = no; # Reserve area for inserting a certificate without recompiling
  "SECONDARY_TRUSTED_KEYRING" = no; # Provide a keyring to which extra trustable keys may be added
  "SYSTEM_BLACKLIST_KEYRING" = no; # Provide system-wide ring of blacklisted keys
  ### end of Certificates for signature checking

  "CRYPTO_KRB5" = no; # Kerberos 5 crypto

  ## Library routines
  "RAID6_PQ_BENCHMARK" = yes; # Automatically choose fastest RAID6 PQ functions
  "PACKING" = yes; # Generic bitfield packing and unpacking
  "CORDIC" = no; # CORDIC algorithm
  "PRIME_NUMBERS" = no; # Simple prime number generator for testing
  "INDIRECT_PIO" = yes; # Access I/O in non-MMIO mode
  "TRACE_MMIO_ACCESS" = no; # Register read/write tracing
  "RANDOM32_SELFTEST" = no; # PRNG perform self test on init
  "XZ_DEC" = yes; # XZ decompression support
  "XZ_DEC_MICROLZMA" = no; # MicroLZMA decoder
  "XZ_DEC_TEST" = no; # XZ decompressor tester
  "SWIOTLB_DYNAMIC" = no; # Dynamic allocation of DMA bounce buffers
  "DMA_RESTRICTED_POOL" = yes; # DMA Restricted Pool
  "DMA_CMA" = yes; # DMA Contiguous Memory Allocator
  "DMA_NUMA_CMA" = no; # Enable separate DMA Contiguous Memory Area for NUMA Node
  "CMA_SIZE_MBYTES" = freeform "256"; # Size in Mega Bytes
  "CMA_SIZE_SEL_MBYTES" = yes; # Use mega bytes value only
  "CMA_SIZE_SEL_PERCENTAGE" = no; # Use percentage value only
  "CMA_SIZE_SEL_MIN" = no; # Use lower value (minimum)
  "CMA_SIZE_SEL_MAX" = no; # Use higher value (maximum)
  "CMA_ALIGNMENT" = freeform "8"; # Maximum PAGE_SIZE order of alignment for contiguous buffers
  "DMA_API_DEBUG" = no; # Enable debugging of DMA-API usage
  "DMA_MAP_BENCHMARK" = no; # Enable benchmarking of streaming DMA mapping
  "GLOB_SELFTEST" = no; # glob self-test on init
  "IRQ_POLL" = yes; # IRQ polling library
  "FONTS" = no; # Select compiled-in fonts
  "STACKDEPOT_MAX_FRAMES" = freeform "64"; # Maximum number of frames in trace saved in stack depot
  "LWQ_TEST" = no; # Boot-time test for lwq queuing
  ## end of Library routines

  ## Kernel hacking

  ### Kernel hacking -> printk and dmesg options
  "PRINTK_TIME" = yes; # Show timing information on printks
  "PRINTK_CALLER" = no; # Show caller information on printks
  "STACKTRACE_BUILD_ID" = no; # Show build ID information in stacktraces
  "CONSOLE_LOGLEVEL_DEFAULT" = freeform "7"; # Default console loglevel (1-15)
  "CONSOLE_LOGLEVEL_QUIET" = freeform "4"; # quiet console loglevel (1-15)
  "MESSAGE_LOGLEVEL_DEFAULT" = freeform "4"; # Default message log level (1-7)
  "BOOT_PRINTK_DELAY" = no; # Delay each boot printk message by N milliseconds
  "DYNAMIC_DEBUG" = yes; # Enable dynamic printk() support
  "DYNAMIC_DEBUG_CORE" = yes; # Enable core function of dynamic debug support
  "SYMBOLIC_ERRNAME" = yes; # Support symbolic error names in printf
  ### Kernel hacking: end of printk and dmesg options

  "DEBUG_KERNEL" = yes; # Kernel debugging
  "DEBUG_MISC" = yes; # Miscellaneous debug code

  ### Kernel hacking -> Compile-time checks and compiler options
  "DEBUG_INFO_NONE" = no; # Disable debug information
  "DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT" = yes; # Rely on the toolchain's implicit default DWARF version
  "DEBUG_INFO_DWARF4" = no; # Generate DWARF Version 4 debuginfo
  "DEBUG_INFO_DWARF5" = no; # Generate DWARF Version 5 debuginfo
  "DEBUG_INFO_REDUCED" = yes; # Reduce debugging information
  "DEBUG_INFO_COMPRESSED_NONE" = yes; # Don't compress debug information
  "DEBUG_INFO_COMPRESSED_ZLIB" = no; # Compress debugging information with zlib
  "DEBUG_INFO_SPLIT" = no; # Produce split debuginfo in .dwo files
  "GDB_SCRIPTS" = no; # Provide GDB scripts for kernel debugging
  "FRAME_WARN" = freeform "2048"; # Warn for stack frames larger than
  "STRIP_ASM_SYMS" = no; # Strip assembler-generated symbols during link
  "READABLE_ASM" = no; # Generate readable assembler code
  "HEADERS_INSTALL" = no; # Install uapi headers to usr/include
  "DEBUG_SECTION_MISMATCH" = no; # Enable full Section mismatch analysis
  "SECTION_MISMATCH_WARN_ONLY" = yes; # Make section mismatch errors non-fatal
  "FRAME_POINTER" = yes; # Compile the kernel with frame pointers
  "DEBUG_FORCE_WEAK_PER_CPU" = no; # Force weak per-cpu definitions
  ### Kernel hacking: end of Compile-time checks and compiler options

  ### Kernel hacking -> Generic Kernel Debugging Instruments
  "MAGIC_SYSRQ" = yes; # Magic SysRq key
  "MAGIC_SYSRQ_DEFAULT_ENABLE" = freeform "0x1"; # Enable magic SysRq key functions by default
  "MAGIC_SYSRQ_SERIAL" = yes; # Enable magic SysRq key over serial
  "DEBUG_FS" = yes; # Debug Filesystem
  "DEBUG_FS_ALLOW_ALL" = yes; # Access normal
  "DEBUG_FS_DISALLOW_MOUNT" = no; # Do not register debugfs as filesystem
  "DEBUG_FS_ALLOW_NONE" = no; # No access
  "KGDB" = no; # KGDB: kernel debugger
  "UBSAN" = no; # Undefined behaviour sanity checker
  ### Kernel hacking: end of Generic Kernel Debugging Instruments

  ### Kernel hacking -> Networking Debugging
  "NET_DEV_REFCNT_TRACKER" = no; # Enable net device refcount tracking
  "NET_NS_REFCNT_TRACKER" = no; # Enable networking namespace refcount tracking
  "DEBUG_NET" = no; # Add generic networking debug
  "DEBUG_NET_SMALL_RTNL" = no; # Add extra per-netns mutex inside RTNL
  ### Kernel hacking: end of Networking Debugging

  ### Kernel hacking -> Memory Debugging
  "PAGE_EXTENSION" = no; # Extend memmap on extra space for more information on page
  "DEBUG_PAGEALLOC" = no; # Debug page memory allocations
  "SLUB_DEBUG" = yes; # Enable SLUB debugging support
  "SLUB_DEBUG_ON" = no; # SLUB debugging on by default
  "PAGE_OWNER" = no; # Track page owner
  "PAGE_TABLE_CHECK" = no; # Check for invalid mappings in user page tables
  "PAGE_POISONING" = no; # Poison pages after freeing
  "DEBUG_PAGE_REF" = no; # Enable tracepoint to track down page reference manipulation
  "DEBUG_RODATA_TEST" = no; # Testcase for the marking rodata read-only
  "DEBUG_WX" = no; # Warn on W+X mappings at boot
  "PTDUMP_DEBUGFS" = no; # Export kernel pagetable layout to userspace via debugfs
  "DEBUG_KMEMLEAK" = no; # Kernel memory leak detector
  "PER_VMA_LOCK_STATS" = no; # Statistics for per-vma locks
  "DEBUG_OBJECTS" = no; # Debug object operations
  "SHRINKER_DEBUG" = no; # Enable shrinker debugging support
  "DEBUG_STACK_USAGE" = no; # Stack utilization instrumentation
  "SCHED_STACK_END_CHECK" = no; # Detect stack corruption on calls to schedule()
  "DEBUG_VFS" = no; # Debug VFS
  "DEBUG_VM" = no; # Debug VM
  "DEBUG_VM_PGTABLE" = no; # Debug arch page table for semantics compliance
  "DEBUG_VIRTUAL" = no; # Debug VM translations
  "DEBUG_PER_CPU_MAPS" = no; # Debug access to per_cpu maps
  "MEM_ALLOC_PROFILING" = no; # Enable memory allocation profiling
  "KASAN" = no; # KASAN: dynamic memory safety error detector
  "KFENCE" = no; # KFENCE: low-overhead sampling-based memory safety error detector
  ### Kernel hacking: end of Memory Debugging

  "DEBUG_SHIRQ" = no; # Debug shared IRQ handlers

  ### Kernel hacking -> Debug Oops, Lockups and Hangs
  "PANIC_ON_OOPS" = no; # Panic on Oops
  "PANIC_TIMEOUT" = freeform "0"; # panic timeout
  "SOFTLOCKUP_DETECTOR" = no; # Detect Soft Lockups
  "HARDLOCKUP_DETECTOR" = no; # Detect Hard Lockups
  "DETECT_HUNG_TASK" = no; # Detect Hung Tasks
  "WQ_WATCHDOG" = no; # Detect Workqueue Stalls
  "WQ_CPU_INTENSIVE_REPORT" = no; # Report per-cpu work items which hog CPU for too long
  "TEST_LOCKUP" = no; # Test module to generate lockups
  ### Kernel hacking: end of Debug Oops, Lockups and Hangs

  ### Kernel hacking -> Scheduler Debugging
  "SCHEDSTATS" = no; # Collect scheduler statistics
  ### Kernel hacking: end of Scheduler Debugging

  "DEBUG_PREEMPT" = no; # Debug preemptible kernel

  ### Kernel hacking -> Lock Debugging (spinlocks, mutexes, etc...)
  "PROVE_LOCKING" = no; # Lock debugging: prove locking correctness
  "LOCK_STAT" = no; # Lock usage statistics
  "DEBUG_RT_MUTEXES" = no; # RT Mutex debugging, deadlock detection
  "DEBUG_SPINLOCK" = no; # Spinlock and rw-lock debugging: basic checks
  "DEBUG_MUTEXES" = no; # Mutex debugging: basic checks
  "DEBUG_WW_MUTEX_SLOWPATH" = no; # Wait/wound mutex debugging: Slowpath testing
  "DEBUG_RWSEMS" = no; # RW Semaphore debugging: basic checks
  "DEBUG_LOCK_ALLOC" = no; # Lock debugging: detect incorrect freeing of live locks
  "DEBUG_ATOMIC_SLEEP" = no; # Sleep inside atomic section checking
  "DEBUG_LOCKING_API_SELFTESTS" = no; # Locking API boot-time self-tests
  "LOCK_TORTURE_TEST" = no; # torture tests for locking
  "WW_MUTEX_SELFTEST" = no; # Wait/wound mutex selftests
  "SCF_TORTURE_TEST" = no; # torture tests for smp_call_function*()
  "CSD_LOCK_WAIT_DEBUG" = no; # Debugging for csd_lock_wait(), called from smp_call_function*()
  ### Kernel hacking: end of Lock Debugging (spinlocks, mutexes, etc...)

  "DEBUG_IRQFLAGS" = no; # Debug IRQ flag manipulation
  "STACKTRACE" = yes; # Stack backtrace support
  "WARN_ALL_UNSEEDED_RANDOM" = no; # Warn for all uses of unseeded randomness
  "DEBUG_KOBJECT" = no; # kobject debugging

  ### Kernel hacking -> Debug kernel data structures
  "DEBUG_LIST" = no; # Debug linked list manipulation
  "DEBUG_PLIST" = no; # Debug priority linked list manipulation
  "DEBUG_SG" = no; # Debug SG table operations
  "DEBUG_NOTIFIERS" = no; # Debug notifier call chains
  "DEBUG_MAPLE_TREE" = no; # Debug maple trees
  ### Kernel hacking: end of Debug kernel data structures

  ### Kernel hacking -> RCU Debugging
  "RCU_SCALE_TEST" = no; # performance tests for RCU
  "RCU_TORTURE_TEST" = no; # torture tests for RCU
  "RCU_REF_SCALE_TEST" = no; # Scalability tests for read-side synchronization (RCU and others)
  "RCU_CPU_STALL_TIMEOUT" = freeform "21"; # RCU CPU stall timeout in seconds
  "RCU_EXP_CPU_STALL_TIMEOUT" = freeform "0"; # Expedited RCU CPU stall timeout in milliseconds
  "RCU_CPU_STALL_CPUTIME" = no; # Provide additional RCU stall debug information
  "RCU_TRACE" = yes; # Enable tracing for RCU
  "RCU_EQS_DEBUG" = no; # Provide debugging asserts for adding NO_HZ support to an arch
  ### Kernel hacking: end of RCU Debugging

  "DEBUG_WQ_FORCE_RR_CPU" = no; # Force round-robin CPU selection for unbound work items
  "CPU_HOTPLUG_STATE_CONTROL" = no; # Enable CPU hotplug state control
  "LATENCYTOP" = no; # Latency measuring infrastructure
  "FTRACE" = yes; # Tracers
  "BOOTTIME_TRACING" = no; # Boot-time Tracing support
  "FUNCTION_TRACER" = yes; # Kernel Function Tracer
  "FUNCTION_GRAPH_TRACER" = yes; # Kernel Function Graph Tracer
  "FUNCTION_GRAPH_RETVAL" = no; # Kernel Function Graph Return Value
  "FUNCTION_GRAPH_RETADDR" = no; # Kernel Function Graph Return Address
  "DYNAMIC_FTRACE" = yes; # enable/disable function tracing dynamically
  "FPROBE" = no; # Kernel Function Probe (fprobe)
  "FUNCTION_PROFILER" = no; # Kernel function profiler
  "STACK_TRACER" = no; # Trace max stack
  "IRQSOFF_TRACER" = no; # Interrupts-off Latency Tracer
  "PREEMPT_TRACER" = no; # Preemption-off Latency Tracer
  "SCHED_TRACER" = no; # Scheduling Latency Tracer
  "HWLAT_TRACER" = no; # Tracer to detect hardware latencies (like SMIs)
  "OSNOISE_TRACER" = no; # OS Noise tracer
  "TIMERLAT_TRACER" = no; # Timerlat tracer
  "FTRACE_SYSCALLS" = no; # Trace syscalls
  "TRACER_SNAPSHOT" = no; # Create a snapshot trace buffer
  "BRANCH_PROFILE_NONE" = yes; # No branch profiling
  "PROFILE_ANNOTATED_BRANCHES" = no; # Trace likely/unlikely profiler
  "PROFILE_ALL_BRANCHES" = no; # Profile all if conditionals
  "BLK_DEV_IO_TRACE" = no; # Support for tracing block IO actions
  "UPROBE_EVENTS" = yes; # Enable uprobes-based dynamic events
  "SYNTH_EVENTS" = no; # Synthetic trace events
  "USER_EVENTS" = no; # User trace events
  "HIST_TRIGGERS" = no; # Histogram triggers
  "TRACE_EVENT_INJECT" = no; # Trace event injection
  "TRACEPOINT_BENCHMARK" = no; # Add tracepoint that benchmarks tracepoints
  "RING_BUFFER_BENCHMARK" = no; # Ring buffer benchmark stress tester
  "TRACE_EVAL_MAP_FILE" = no; # Show eval mappings for trace events
  "FTRACE_RECORD_RECURSION" = no; # Record functions that recurse in function tracing
  "FTRACE_VALIDATE_RCU_IS_WATCHING" = no; # Validate RCU is on during ftrace execution
  "FTRACE_STARTUP_TEST" = no; # Perform a startup test on ftrace
  "FTRACE_SORT_STARTUP_TEST" = no; # Verify compile time sorting of ftrace functions
  "RING_BUFFER_STARTUP_TEST" = no; # Ring buffer startup self test
  "RING_BUFFER_VALIDATE_TIME_DELTAS" = no; # Verify ring buffer time stamp deltas
  "PREEMPTIRQ_DELAY_TEST" = no; # Test module to create a preempt / IRQ disable delay thread to test latency tracers
  "RV" = no; # Runtime Verification
  "SAMPLES" = no; # Sample kernel code
  "STRICT_DEVMEM" = yes; # Filter access to /dev/mem
  "IO_STRICT_DEVMEM" = no; # Filter I/O access to /dev/mem

  ### Kernel hacking -> arm64 Debugging
  "PID_IN_CONTEXTIDR" = no; # Write the current PID to the CONTEXTIDR register
  "DEBUG_EFI" = no; # UEFI debugging
  "ARM64_RELOC_TEST" = no; # Relocation testing module
  "CORESIGHT" = module; # CoreSight Tracing Support
  "CORESIGHT_LINKS_AND_SINKS" = module; # CoreSight Link and Sink drivers
  "CORESIGHT_LINK_AND_SINK_TMC" = module; # Coresight generic TMC driver
  "CORESIGHT_CATU" = module; # Coresight Address Translation Unit (CATU) driver
  "CORESIGHT_SINK_TPIU" = module; # Coresight generic TPIU driver
  "CORESIGHT_SINK_ETBV10" = module; # Coresight ETBv1.0 driver
  "CORESIGHT_SOURCE_ETM4X" = no; # CoreSight ETMv4.x / ETE driver
  "CORESIGHT_STM" = module; # CoreSight System Trace Macrocell driver
  "CORESIGHT_CTCU" = no; # CoreSight TMC Control Unit driver
  "CORESIGHT_CPU_DEBUG" = module; # CoreSight CPU Debug driver
  "CORESIGHT_CPU_DEBUG_DEFAULT_ON" = no; # Enable CoreSight CPU Debug by default
  "CORESIGHT_CTI" = module; # CoreSight Cross Trigger Interface (CTI) driver
  "CORESIGHT_CTI_INTEGRATION_REGS" = no; # Access CTI CoreSight Integration Registers
  "ULTRASOC_SMB" = no; # Ultrasoc system memory buffer drivers
  "CORESIGHT_TPDM" = no; # CoreSight Trace, Profiling & Diagnostics Monitor driver
  "CORESIGHT_TPDA" = no; # CoreSight Trace, Profiling & Diagnostics Aggregator driver
  "CORESIGHT_DUMMY" = no; # Dummy driver support
  ### Kernel hacking: end of arm64 Debugging

  ### Kernel hacking -> Kernel Testing and Coverage
  "KUNIT" = no; # KUnit - Enable support for unit tests
  "NOTIFIER_ERROR_INJECTION" = no; # Notifier error injection
  "FAULT_INJECTION" = no; # Fault-injection framework
  "KCOV" = no; # Code coverage for fuzzing
  "RUNTIME_TESTING_MENU" = yes; # Runtime Testing
  "TEST_DHRY" = no; # Dhrystone benchmark test
  "LKDTM" = no; # Linux Kernel Dump Test Tool Module
  "TEST_MIN_HEAP" = no; # Min heap test
  "TEST_DIV64" = no; # 64bit/32bit division and modulo test
  "TEST_MULDIV64" = no; # mul_u64_u64_div_u64() test
  "BACKTRACE_SELF_TEST" = no; # Self test for the backtrace code
  "TEST_REF_TRACKER" = no; # Self test for reference tracker
  "RBTREE_TEST" = no; # Red-Black tree test
  "REED_SOLOMON_TEST" = no; # Reed-Solomon library test
  "INTERVAL_TREE_TEST" = no; # Interval tree test
  "PERCPU_TEST" = no; # Per cpu operations test
  "ATOMIC64_SELFTEST" = no; # Perform an atomic64_t self-test
  "TEST_HEXDUMP" = no; # Test functions located in the hexdump module at runtime
  "TEST_KSTRTOX" = no; # Test kstrto*() family of functions at runtime
  "TEST_BITMAP" = no; # Test bitmap_*() family of functions at runtime
  "TEST_UUID" = no; # Test functions located in the uuid module at runtime
  "TEST_XARRAY" = no; # Test the XArray code at runtime
  "TEST_MAPLE_TREE" = no; # Test the Maple Tree code at runtime or module load
  "TEST_RHASHTABLE" = no; # Perform selftest on resizable hash table
  "TEST_IDA" = no; # Perform selftest on IDA functions
  "TEST_LKM" = no; # Test module loading with 'hello world' module
  "TEST_BITOPS" = no; # Test module for compilation of bitops operations
  "TEST_VMALLOC" = no; # Test module for stress/performance analysis of vmalloc allocator
  "TEST_BPF" = no; # Test BPF filter functionality
  "FIND_BIT_BENCHMARK" = no; # Test find_bit functions
  "TEST_FIRMWARE" = no; # Test firmware loading via userspace interface
  "TEST_SYSCTL" = no; # sysctl test driver
  "TEST_UDELAY" = no; # udelay test driver
  "TEST_STATIC_KEYS" = no; # Test static keys
  "TEST_DYNAMIC_DEBUG" = no; # Test DYNAMIC_DEBUG
  "TEST_KMOD" = no; # kmod stress tester
  "TEST_KALLSYMS" = no; # module kallsyms find_symbol() test
  "TEST_MEMCAT_P" = no; # Test memcat_p() helper function
  "TEST_MEMINIT" = no; # Test heap/page initialization
  "TEST_FREE_PAGES" = no; # Test freeing pages
  "TEST_FPU" = no; # Test floating point operations in kernel space
  "TEST_OBJPOOL" = no; # Test module for correctness and stress of objpool
  "MEMTEST" = yes; # Memtest
  ### Kernel hacking: end of Kernel Testing and Coverage
  ## end of Kernel hacking
  # end of Linux/arm64 6.16.0-rc2 Kernel Configuration
}
