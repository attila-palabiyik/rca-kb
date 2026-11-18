# Align serial packer output valid with completed data

TopModule accepts serial bits and emits six-bit words with the earliest bit at bit 0. Its counter already wrapped at five on an accepted bit, but the combinational valid output asserted as soon as the counter reached five, while the output register still held the previous word. A gap after the fifth bit could stretch that premature valid indication. The registered ready output also started low, despite the explicit always-high requirement.

The fix ties ready high and registers the output word and its one-cycle valid pulse together when the sixth valid input arrives. The first five bits shift into a five-bit register. Reset discards partial words and clears the registered outputs. No alternative patch was attempted. An independent Icarus simulation passed all 64 data patterns and covered continuous input, a gap at count five, valid input on the first clock after reset release, and reset during a partial word.

For similar serial packer tasks, compare the cycle that updates the output register with the cycle that signals completion, and test a pause just before the final input. Check the explicit ready requirement independently of the existing counter logic.
