### A restored run state may repeat a calibration profile of a dropped kind

- Location: `.claude/workflows/deliver-change.js` (`restoreCalibration`, `metricLine`).
- Why: a run state written before scout-drop may carry `metric.calib.scout` or `metric.calib.areas`; `restoreCalibration` keeps any well-formed `metric.calib.KIND`, so a resumed older run repeats it in its metric line though no start of that kind runs any more. The figure is recorded data and harms nothing, but a history row could show a profile for a phase that did not run.
- Fix: restore only the kinds `CALIBRATION` names (`m[1] in CALIBRATION`), with a tools-test case giving a saved `metric.calib.scout` that is not restored.
