# Karabiner Config Notes

## Modification order

Complex modifications see keys AFTER simple modifications apply (per Karabiner docs: input event modification chaining). Device rules here swap `left_command`/`left_option` on some keyboards, so a complex rule matching a logical modifier may fire on the other physical key. Scope such rules with `device_if`/`device_unless` on the swapped `vendor_id`/`product_id` pairs.

## One-shot modifiers

Tap-for-sticky plus hold-for-modifier pattern:

- `from`/`to` the same modifier (hold behavior), `to_if_alone` with `sticky_modifier: toggle` (tap arms the one-shot).
- Never post key events (not even `vk_none`) in `to_delayed_action.to_if_canceled`; any key event consumes the pending sticky. Use a `set_variable` no-op there.
- Timeout via `to_delayed_action.to_if_invoked` with `sticky_modifier: off` plus `basic.to_delayed_action_delay_milliseconds`.
- Tap-hold for held modifier: `to_if_alone` also sets a flag variable; a preceding manipulator with `variable_if` on that flag sends the held modifier combo and clears the flag in `to_after_key_up`. All delayed-action branches (`invoked` and `canceled`) must reset the flag with `set_variable`, never a key event.

## Verify

- `python3 -c "import json,pathlib; json.loads(pathlib.Path('config/karabiner/karabiner.json').read_text())"` after edits.
- `dot -l karabiner` to relink.
- Karabiner-Elements EventViewer for behavior: sticky arming shows as virtual modifier downs, and the next key down must carry those flags.
