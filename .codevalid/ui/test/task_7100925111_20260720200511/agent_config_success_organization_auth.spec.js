import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAdminAgentSkillsPage,
  setupOutlookAgentScenario,
  openOutlookAgentPanel,
  getOutlookPanel,
} from "../../helpers/mock-api.js";

test("Agent configuration succeeds with organization authentication", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_config_success_organization_auth",
    testTitle: "Agent configuration succeeds with organization authentication",
  });

  let lastAuthRequestBody = null;

  await recorder.step("Register admin agents and Outlook organization auth mocks", async () => {
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
          url: "https://login.microsoftonline.com/mock-organization-auth",
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
          tenantId: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
          clientSecret: "********",
          authType: "organization",
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
  const idInputs = panel.getByPlaceholder("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx");
  const clientSecretInput = panel.getByPlaceholder("Your client secret...");
  const authTypeSelect = panel.locator("select");
  const authButton = panel.getByRole("button", {
    name: "Authenticate with Microsoft",
  });

  await recorder.step("Enter organization auth credentials", async () => {
    await authTypeSelect.selectOption("organization");
    await expect(idInputs).toHaveCount(2);
    await idInputs.nth(0).fill("11111111-2222-3333-4444-555555555555");
    await idInputs.nth(1).fill("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee");
    await clientSecretInput.fill("super-secret-value");
  });

  await recorder.step("Start Microsoft organization authentication", async () => {
    await expect(authButton).toBeVisible();
    await authButton.click();
  });

  await recorder.step("Assert organization auth request payload and redirect", async () => {
    expect(lastAuthRequestBody).toEqual({
      clientId: "11111111-2222-3333-4444-555555555555",
      tenantId: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
      clientSecret: "super-secret-value",
      authType: "organization",
    });

    const openedUrls = await page.evaluate(() => window.__openedUrls);
    expect(openedUrls).toContain("https://login.microsoftonline.com/mock-organization-auth");
    await expect(panel.getByText("Authentication required")).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_config_success_organization_auth");
  await recorder.save(testInfo);
});
