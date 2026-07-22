import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAdminAgentSkillsPage,
  setupOutlookAgentScenario,
  openOutlookAgentPanel,
  getOutlookPanel,
} from "../../helpers/mock-api.js";

test("Agent configuration failed when organization auth type is selected without tenant ID", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_config_organization_auth_missing_tenant_id",
    testTitle: "Agent configuration failed when organization auth type is selected without tenant ID",
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
  const idInputs = panel.getByPlaceholder("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx");
  const clientIdInput = idInputs.first();
  const authTypeSelect = panel.locator("select");
  const clientSecretInput = panel.getByPlaceholder("Your client secret...");
  const authButton = panel.getByRole("button", {
    name: "Authenticate with Microsoft",
  });

  await recorder.step("Enter credentials except Tenant ID and switch to organization auth", async () => {
    await clientIdInput.fill("11111111-2222-3333-4444-555555555555");
    await clientSecretInput.fill("super-secret-value");
    await authTypeSelect.selectOption("organization");
  });

  await recorder.step("Verify organization auth requires tenant id before showing auth action", async () => {
    await expect(idInputs).toHaveCount(2);
    await expect(panel.getByText("Configuration required")).toBeVisible();
    await expect(authButton).toHaveCount(0);
    expect(authRequestCount).toBe(0);
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_config_organization_auth_missing_tenant_id");
  await recorder.save(testInfo);
});
