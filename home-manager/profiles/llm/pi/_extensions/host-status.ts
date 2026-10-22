/**
 * Pi's default footer only reports folder, session, model, context and cost,
 * so the machine has to be labelled explicitly; sessions from several hosts
 * look identical otherwise.
 */

import os from "node:os";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    const theme = ctx.ui.theme;
    ctx.ui.setStatus("host", theme.fg("dim", os.hostname()));
  });
}
