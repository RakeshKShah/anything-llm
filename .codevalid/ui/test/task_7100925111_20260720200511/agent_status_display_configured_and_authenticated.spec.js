import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAdminAgentSkillsPage,
  setupOutlookAgentScenario,
  openOutlookAgentPanel,
  getOutlookPanel,
} from "../../helpers/mock-api.js";

test("Agent status correctly displays configured and authenticated state", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_status_display_configured_and_authenticated",
    testTitle: "Agent status correctly displays configured and authenticated state",
  });

  await recorder.step("Register configured and authenticated Outlook status mocks", async () => {
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
          tenantId: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
          clientSecret: "********",
          authType: "organization",
        },
      },
    });
  });

  await recorder.step("Open Outlook agent configuration panel", async () => {
    await openOutlookAgentPanel(page);
  });

  const panel = getOutlookPanel(page);
  const idInputs = panel.getByPlaceholder("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx");
  const clientSecretInput = panel.getByPlaceholder("Your client secret...");

  await recorder.step("Verify configured and authenticated UI state", async () => {
    await expect(panel.getByText("Configured")).toBeVisible();
    await expect(panel.getByText("Authenticated")).toBeVisible();
    await expect(panel.getByRole("button", { name: "Revoke Access" })).toBeVisible();
    await expect(panel.getByRole("button", { name: "Authenticate with Microsoft" })).toHaveCount(0);
    await expect(idInputs.nth(0)).toHaveValue("11111111-2222-3333-4444-555555555555");
    await expect(idInputs.nth(1)).toHaveValue("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee");
    await expect(clientSecretInput).toHaveValue("********");
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_status_display_configured_and_authenticated");
  await recorder.save(testInfo);
});
