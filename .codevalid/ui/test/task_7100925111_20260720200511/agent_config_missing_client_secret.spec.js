import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAdminAgentSkillsPage,
  setupOutlookAgentScenario,
  openOutlookAgentPanel,
  getOutlookPanel,
} from "../../helpers/mock-api.js";

test("Agent configuration failed when Client Secret is missing", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_config_missing_client_secret",
    testTitle: "Agent configuration failed when Client Secret is missing",
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
  const clientIdInput = panel.getByPlaceholder("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx").first();
  const authButton = panel.getByRole("button", {
    name: "Authenticate with Microsoft",
  });

  await recorder.step("Enter Client ID and leave Client Secret empty", async () => {
    await expect(clientIdInput).toBeVisible();
    await clientIdInput.fill("11111111-2222-3333-4444-555555555555");
  });

  await recorder.step("Verify UI blocks auth when Client Secret is missing", async () => {
    await expect(panel.getByText("Configuration required")).toBeVisible();
    await expect(authButton).toHaveCount(0);
    expect(authRequestCount).toBe(0);
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_config_missing_client_secret");
  await recorder.save(testInfo);
});
