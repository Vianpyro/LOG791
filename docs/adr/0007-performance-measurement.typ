#import "../template.typ": validation

== ADR-0007 — Deterministic and fair performance measurement

*Status:* proposed; prototype to build, grading model to settle with the instructor. \
*See also:* architecture, sections "Resource management" and "Load and performance"; ADR-0001, ADR-0002.

=== Context

An exercise may assess a solution's performance, not only its correctness. The goal is to assess the algorithm, not the language or the machine. Two obstacles stand in the way:

- *Noise.* Wall-clock time and CPU time vary with the VM's load, time stolen by the hypervisor, the cache and the processor frequency. On a shared VM, the spread reaches 5 to 30%, which is not enough to tell solutions apart.
- *Language.* The same algorithm is 10 to 100 times slower in Python than in Rust, and this factor varies with the operations. A fixed per-language multiplier therefore remains approximate.

The platform runs under gVisor (ADR-0002), in a VM where KVM is not guaranteed. `perf_event_open` is not available inside the sandbox.

=== Options considered

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Pros*], [*Cons*],
  [Wall-clock or CPU time], [No overhead; simple.], [5 to 30% noise; language-dependent.],
  [Hardware counters (`perf`)],
  [Accurate, no slowdown.],
  [Rarely exposed in a VM; unavailable under gVisor.],

  [Valgrind (`callgrind`)],
  [Deterministic instruction count.],
  [20 to 100$times$ slowdown; fragile with the JVM's JIT.],

  [QEMU user mode with an instruction-counting plugin],
  [Deterministic count; requires neither KVM nor hardware counters; 5 to 10$times$ slowdown.],
  [Compatibility with gVisor Systrap to be confirmed.],
)

=== Decision

*Measurement.* Performance is measured in *executed instructions*, under QEMU user mode (`qemu-x86_64 -plugin libinsn.so`), not in time. For each runtime to behave deterministically:

- processes are limited to a single thread;
- inputs and the random seed are fixed;
- Python uses `PYTHONHASHSEED=0`;
- the JVM uses `-Xbatch` and a fixed-size heap.

Counting is only active during the call to the student's function, thanks to a marker emitted by the harness. Reading the inputs, whose cost depends heavily on the language, is therefore excluded.

*Neutralizing the language.* A student is only compared with a reference solution *in the same language*. The main criterion is *complexity*: several input sizes are measured, then the log-log slope of the instruction differences between sizes is computed, which removes the startup cost. This slope does not depend on the language. Two grading models remain to be settled with the instructor:

- *Complexity verdict*: check that the slope does not exceed the reference's, within a tolerance. A single reference per exercise is enough.
- *Full ranking*: rank first by complexity, then by the ratio to the instruction count of the same-language reference. This requires one reference per language and per exercise.

Memory follows the same logic: the peak memory, minus the runtime's baseline, is compared with the reference's.

*Two passes.* Measurement slows execution down. It is therefore never done while the student is waiting for an answer:

- *Correctness pass*: native execution, with generous time limits. It is the only one that responds during the exam.
- *Measurement pass*: it runs after the exam and only covers the *last* submission of each student for each exercise (one unique key per student–exercise pair). The queue is drained when the server is lightly loaded. Accuracy does not depend on it; the point is to leave the CPU to live judging.

The measurement queue is a lower-priority queue in PostgreSQL (ADR-0001). No new component is added.

=== Consequences

- The execution limit of the measurement pass is an *instruction budget*. A generous wall-clock timeout remains in place as a safety net.
- Since the result is deterministic, the measurement pass can overload a machine, or run on another machine, without skewing the measurements.
- *Measurement data.* It is distinct from the tests. Large inputs are produced by an instructor-provided generator, with a seed chosen at measurement time, and the outputs are re-checked.
- *Pinned versions.* Runtime versions are pinned for a term. References are re-measured with the same images at each content release.
- *Appeals.* To be able to repeat an identical measurement, the source code, the image, the content release, the seed and the instruction count are kept.
- *Turnaround.* Computation time must be planned before grades are released: students $times$ exercises $times$ sizes $times$ duration of one measurement under QEMU.
- *Libraries.* For each exercise, the instructor specifies the allowed libraries, for example `sorted()` or `heapq`.
- *Questions to settle with the instructor:*
  - the choice of grading model;
  - whether code that does not pass all tests is measured;
  - which submission to measure if the last one fails while an earlier one passed;
  - how the result is presented to the student (for example "O(n log n), 1.8$times$ the reference").

#validation(id: "V-0007")[
  Measure an O(n²) sort and an O(n log n) sort in Python, Java and Rust, under QEMU and inside gVisor. Repeat each measurement 30 times, with and without `stress-ng` on the VM. Criteria:
  - a coefficient of variation below 0.1%;
  - a slope that separates the two sorts in all three languages;
  - ratios to the reference of the same order from one language to another.
]
