import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAdminAgentSkillsPage,
  setupOutlookAgentScenario,
  openOutlookAgentPanel,
  getOutlookPanel,
} from "../../helpers/mock-api.js";

test("Agent configuration failed when Client ID is missing", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_config_missing_client_id",
    testTitle: "Agent configuration failed when Client ID is missing",
  });

  let authRequestCount = 0;

  await recorder.step("Register admin agents and Outlook mocks", async () => {
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
      onAuthUrlRequest: async () => {
        authRequestCount += 1;
      },
    });
  });

  await recorder.step("Open Outlook agent configuration panel", async () => {
    await openOutlookAgentPanel(page);
  });

  const panel = getOutlookPanel(page);
  const clientSecretInput = panel.getByPlaceholder("Your client secret...");
  const authButton = panel.getByRole("button", {
    name: "Authenticate with Microsoft",
  });

  await recorder.step("Leave Client ID empty and enter Client Secret", async () => {
    await expect(clientSecretInput).toBeVisible();
    await clientSecretInput.fill("super-secret-value");
  });

  await recorder.step("Verify UI blocks auth when required credentials are incomplete", async () => {
    await expect(panel.getByText("Configuration required")).toBeVisible();
    await expect(authButton).toHaveCount(0);
    expect(authRequestCount).toBe(0);
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_config_missing_client_id");
  await recorder.save(testInfo);
});
