import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAdminAgentSkillsPage,
  setupOutlookAgentScenario,
  openOutlookAgentPanel,
  getOutlookPanel,
} from "../../helpers/mock-api.js";

test("Agent configuration succeeds with common authentication", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_config_success_common_auth",
    testTitle: "Agent configuration succeeds with common authentication",
  });

  let lastAuthRequestBody = null;

  await recorder.step("Register admin agents and Outlook auth mocks", async () => {
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
      authUrlResponse: {
        status: 200,
        body: {
          success: true,
          url: "https://login.microsoftonline.com/mock-common-auth",
        },
      },
      statusAfterAuth: {
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
      onAuthUrlRequest: async (body) => {
        lastAuthRequestBody = body;
      },
    });
  });

  await recorder.step("Stub window.open so redirect can be asserted", async () => {
    await page.addInitScript(() => {
      window.__openedUrls = [];
      window.open = (url) => {
        window.__openedUrls.push(url);
        return null;
      };
    });
  });

  await recorder.step("Open Outlook agent configuration panel", async () => {
    await openOutlookAgentPanel(page);
  });

  const panel = getOutlookPanel(page);
  const clientIdInput = panel.getByPlaceholder("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx").first();
  const clientSecretInput = panel.getByPlaceholder("Your client secret...");
  const authTypeSelect = panel.locator("select");
  const authButton = panel.getByRole("button", {
    name: "Authenticate with Microsoft",
  });

  await recorder.step("Enter common auth credentials", async () => {
    await clientIdInput.fill("11111111-2222-3333-4444-555555555555");
    await clientSecretInput.fill("super-secret-value");
    await authTypeSelect.selectOption("common");
  });

  await recorder.step("Start Microsoft authentication", async () => {
    await expect(authButton).toBeVisible();
    await authButton.click();
  });

  await recorder.step("Assert auth request payload and redirect", async () => {
    expect(lastAuthRequestBody).toEqual({
      clientId: "11111111-2222-3333-4444-555555555555",
      tenantId: "",
      clientSecret: "super-secret-value",
      authType: "common",
    });

    const openedUrls = await page.evaluate(() => window.__openedUrls);
    expect(openedUrls).toContain("https://login.microsoftonline.com/mock-common-auth");
    await expect(panel.getByText("Authentication required")).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_config_success_common_auth");
  await recorder.save(testInfo);
});
