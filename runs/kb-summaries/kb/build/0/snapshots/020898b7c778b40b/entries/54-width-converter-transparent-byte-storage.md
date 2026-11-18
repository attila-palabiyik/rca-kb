# Registering the first byte in a valid-only width converter

TopModule packs pairs of valid 8-bit inputs into registered 16-bit outputs. The original first-byte storage followed data_in while valid_in was high. On the second valid input, that storage could already contain the second byte, so the output repeated it in both halves.

Replace the combinational storage with an asynchronously reset register that samples data_in at a rising edge when valid_in is high and no first byte is pending. The existing pair flag, output enable, and registered valid pulse implement the required timing. A directed Icarus simulation passed adjacent bytes, gaps with changes on the idle input bus, output hold and valid timing, and reset with a partial pair pending.

This applies to valid-only packers whose buffered input must survive until a later valid sample completes the word.
