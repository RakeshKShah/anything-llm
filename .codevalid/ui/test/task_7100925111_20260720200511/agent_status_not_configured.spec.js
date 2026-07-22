import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAdminAgentSkillsPage,
  setupOutlookAgentScenario,
  openOutlookAgentPanel,
  getOutlookPanel,
} from "../../helpers/mock-api.js";

test("Agent status correctly displays unconfigured state", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_status_not_configured",
    testTitle: "Agent status correctly displays unconfigured state",
  });

  await recorder.step("Register unconfigured Outlook status mocks", async () => {
    await setupAdminAgentSkillsPage(page, { defaultAgentSkills: ["outlook"] });
    await setupOutlookAgentScenario(page, {
      initialStatus: {
        success: true,
        isConfigured: false,
        hasCredentials: false,
        isAuthenticated: false,
        tokenExpiry: null,
        config: {
          clientId: "",
          tenantId: "",
          clientSecret: "",
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

  await recorder.step("Verify unconfigured UI state", async () => {
    await expect(panel.getByText("Configuration required")).toBeVisible();
    await expect(panel.getByRole("button", { name: "Authenticate with Microsoft" })).toHaveCount(0);
    await expect(panel.getByRole("button", { name: "Revoke Access" })).toHaveCount(0);
    await expect(clientIdInput).toHaveValue("");
    await expect(clientSecretInput).toHaveValue("");
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_status_not_configured");
  await recorder.save(testInfo);
});
