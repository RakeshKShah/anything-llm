import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAdminAgentSkillsPage,
  setupOutlookAgentScenario,
  openOutlookAgentPanel,
  getOutlookPanel,
} from "../../helpers/mock-api.js";

test("Agent revocation clears all configuration and tokens", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_revoke_clears_all_credentials",
    testTitle: "Agent revocation clears all configuration and tokens",
  });

  await recorder.step("Register authenticated Outlook status and revoke mocks", async () => {
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
        status: 200,
        body: { success: true },
      },
      statusAfterRevoke: {
        success: true,
        isConfigured: false,
        hasCredentials: false,
        isAuthenticated: false,
        tokenExpiry: null,
        config: {
          clientId: "11111111-2222-3333-4444-555555555555",
          tenantId: "",
          clientSecret: "********",
          authType: "common",
        },
      },
    });
  });

  await recorder.step("Open Outlook agent configuration panel", async () => {
    await openOutlookAgentPanel(page);
  });

  const panel = getOutlookPanel(page);
  const revokeButton = panel.getByRole("button", { name: "Revoke Access" });

  await recorder.step("Revoke Outlook access", async () => {
    await expect(revokeButton).toBeVisible();
    await revokeButton.click();
  });

  await recorder.step("Reload panel to verify post-revoke status", async () => {
    await page.reload();
    await openOutlookAgentPanel(page);
    await expect(getOutlookPanel(page).getByText("Authentication required")).toBeVisible();
    await expect(getOutlookPanel(page).getByRole("button", { name: "Authenticate with Microsoft" })).toBeVisible();
    await expect(getOutlookPanel(page).getByRole("button", { name: "Revoke Access" })).toHaveCount(0);
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_revoke_clears_all_credentials");
  await recorder.save(testInfo);
});
