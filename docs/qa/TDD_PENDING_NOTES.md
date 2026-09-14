# Pending TDD notes — small items, held for a future revision

A running holding pen for small todos and observations that don't warrant a TDD version bump on their own. Add freely; fold into the TDD (and clear from here) only when there's a real batch of substance to write up — not one item at a time.

## Open

- **Pocket watch UI — replace digital/numeral readout with an analog clock face.** The pocket watch (Tab → Personal Effects, shipped 2026-09-14, commit `3f582c2`) currently displays day, exact twelve-hour time, and phase (Morning/Midday/Evening/Night) as text. Per the author: a digital numeral readout is anachronistic for a 1920s-set pocket watch — the fix is a proper analog clock face with hands, twelve-hour dial, showing the same underlying data the working version already computes. Purely visual; `DayClock` and the panel logic itself don't change. Same category of concern as the Stage 6 model-upgrade-pilot idea (production art standard vs. placeholder).
