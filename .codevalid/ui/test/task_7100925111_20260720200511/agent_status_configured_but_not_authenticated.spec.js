import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAdminAgentSkillsPage,
  setupOutlookAgentScenario,
  openOutlookAgentPanel,
  getOutlookPanel,
} from "../../helpers/mock-api.js";

test("Agent status correctly displays configured but not authenticated state", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_status_configured_but_not_authenticated",
    testTitle: "Agent status correctly displays configured but not authenticated state",
  });

  await recorder.step("Register credentials-present but not authenticated Outlook status mocks", async () => {
    await setupAdminAgentSkillsPage(page, { defaultAgentSkills: ["outlook"] });
    await setupOutlookAgentScenario(page, {
      initialStatus: {
        success: true,
        isConfigured: false,
        hasCredentials: true,
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
  const clientIdInput = panel.getByPlaceholder("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx").first();
  const clientSecretInput = panel.getByPlaceholder("Your client secret...");

  await recorder.step("Verify auth-required state with saved credentials", async () => {
    await expect(panel.getByText("Authentication required")).toBeVisible();
    await expect(panel.getByRole("button", { name: "Authenticate with Microsoft" })).toBeVisible();
    await expect(panel.getByRole("button", { name: "Revoke Access" })).toHaveCount(0);
    await expect(clientIdInput).toHaveValue("11111111-2222-3333-4444-555555555555");
    await expect(clientSecretInput).toHaveValue("********");
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_status_configured_but_not_authenticated");
  await recorder.save(testInfo);
});
