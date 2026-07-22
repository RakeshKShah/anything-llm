import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAdminAgentSkillsPage,
  setupOutlookAgentScenario,
  openOutlookAgentPanel,
  getOutlookPanel,
} from "../../helpers/mock-api.js";

test("Agent revocation gracefully handles backend server error", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_revoke_handles_server_error",
    testTitle: "Agent revocation gracefully handles backend server error",
  });

  await recorder.step("Register authenticated Outlook status and failing revoke mocks", async () => {
    await setupAdminAgentSkillsPage(page, { defaultAgentSkills: ["outlook"] });
    await setupOutlookAgentScenario(page, {
      initialStatus: {
        success: true,
        isConfigured: true,
        hasCredentials: true,
        isAuthenticated: true,
        tokenExpiry: 1735689600000,
        config: {
          clientId: "11111111-2222-3333-4444-555555555555",
          tenantId: "",
          clientSecret: "********",
          authType: "common",
        },
      },
      revokeResponse: {
        status: 500,
        body: { success: false, error: "Internal Server Error" },
      },
    });
  });

  await recorder.step("Open Outlook agent configuration panel", async () => {
    await openOutlookAgentPanel(page);
  });

  const panel = getOutlookPanel(page);
  const revokeButton = panel.getByRole("button", { name: "Revoke Access" });

  await recorder.step("Attempt revoke and keep current configuration state", async () => {
    await expect(revokeButton).toBeVisible();
    await revokeButton.click();
    await expect(panel.getByText("Authenticated")).toBeVisible();
    await expect(panel.getByRole("button", { name: "Revoke Access" })).toBeVisible();
    await expect(panel.getByRole("button", { name: "Authenticate with Microsoft" })).toHaveCount(0);
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_revoke_handles_server_error");
  await recorder.save(testInfo);
});
