# Historical uncommitted work preserved as text patches

These five ordinary UTF-8 Git diffs preserve work that was uncommitted when development stopped. They are kept separate and are **not applied to the current v0.14 WIP or the v0.13 source projection**. Each diff was applied to its exact original changed text files in an isolated check directory; every resulting file matched its local preserved commit byte-for-byte. No game test or export was run as part of this preservation.

Use `manifest.json` for original/preserved commit labels and checksums. These local SHA labels do not imply that those commits or their complete Git history exist remotely. For recovery of the complete text state of each of the 20 checkout HEADs, use `../../docs/transfer/history/README.md` (from the repository root: `docs/transfer/history/README.md`) and its fixed first-publication baseline.

- `luanshi-save-ui.patch`: old save/UI integration source.
- `luanshi-saves.patch`: historical design edits and hunger test. The old AGENTS/design text does **not supersede** current canonical design, stop instructions or transfer status.
- `luanshi-hometown-audit.patch`: diagnostic/adversarial test scripts. Some only print diagnostics and exit zero; they are **not all reliable pass/fail CI gates**.
- `luanshi-wounds-audit.patch`: independent wound review test scripts, not raw private review reports.
- `luanshi-youth-ui.patch`: one Godot UID sidecar.

No font, binary, build package, ignored raw artifact or private report is included. Do not apply all patches together or infer test acceptance from preservation. Core story remains the owner's work; development remains stopped until the receiving workflow is authorized to continue.
