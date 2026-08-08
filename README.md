# ParameterSelector_sandbox

App Designer port of the legacy GUIDE-based `parameter_selector.m`/`.fig` tool from `AnalyzER_v2` (`C:\Users\dops0035\Documents\Research\Matlab Working\AnalyzER_v2\parameter_selector.m`).

`parameter_selector` is an interactive parameter-tuning tool: given an image ROI, a ground-truth skeleton, and the current pipeline parameters, it lets the user sweep parameter values and inspect the resulting skeleton/ROC output to pick good defaults. It's launched from the ER Network GT tab's **Prototype** button in [AnalyzERproject_sandbox](https://github.com/markfricker/AnalyzERproject) (not yet wired up — that button depends on this conversion landing first).

Status: not started. The legacy app is tightly coupled to the old `handles.param`/`handles.expt`/`handles.images` data model, which differs substantially from the current AnalyzER app's `app.parameters`/`app.images` structures, so this needs a genuine redesign rather than a line-for-line port.
