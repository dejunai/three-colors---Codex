# Temporary phone visit — 10 September 2026

Codex created `experiment/phone-visit` at Dejunai's request so a friend waiting in the ER can try the investigation. Based on `2cdfb48`, with the author's current TDD v16 replacements copied from the working tree. This is an isolated experiment, not the long-term mobile design.

Use landscape orientation. Tap the ground to walk, tap a visible interaction target to approach, and drag the scene to look. The large arrows move Walter around obstacles; Look buttons orbit the camera. Interact uses the existing nearby, unobstructed focus. Case file, Effects, and Pause are available without a keyboard. Dialogue and other panels fill the screen and scroll vertically.

Movement follows a straight line, not a navigation mesh. If Walter stops against scenery, steer with the arrows. Existing story gates and proximity checks remain in place. Touch buttons release when menus open. Separate application name isolates native saves; host the Web version in its own location. The original published Web build is unchanged.

Validation: `tests/phone_flow.gd` checks boot, overlay, movement, pause/return, and visible pointer. A Chromium touch-enabled browser smoke check loaded the Web export and accepted a touchscreen press on Begin with no console errors. This is not verification on the recipient's physical phone; iPhone/Android performance remains device-dependent.

Export separately with the Web preset. Do not export over `build/web` or replace the current public playtester URL. Current delivery folder is `D:/Documents/ChatGPT/Three Colors/phone-web`; its zip contains `index.html` and its companion assets at the root. Upload those together to a separate static-hosting location. Opening index.html directly from a phone's files is insufficient.
