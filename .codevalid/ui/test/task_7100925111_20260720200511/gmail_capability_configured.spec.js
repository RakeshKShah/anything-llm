import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAdminAgentSkillsPage,
  mockGoogleAgentSkillStatuses,
} from "../../helpers/mock-api.js";

test("gmail capability shows configured status when deploymentId and apiKey are set", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "gmail_capability_configured",
    testTitle: "Gmail capability shows configured status when deploymentId and apiKey are set",
  });

  await recorder.step("Set up admin agent skills page and Gmail configured mocks", async () => {
    await setupAdminAgentSkillsPage(page);
    await mockGoogleAgentSkillStatuses(page, {
      gmail: {
        status: 200,
        body: {
          success: true,
          isConfigured: true,
          config: {
            deploymentId: "AKfycb-gmail-deployment",
            apiKey: "********",
          },
        },
      },
      calendar: {
        status: 200,
        body: {
          success: true,
          isConfigured: false,
          config: { deploymentId: "", apiKey: "" },
        },
      },
    });
  });

  await recorder.step("Load the admin agent skills page", async () => {
    await page.goto("/settings/agents");
    await expect(page.getByRole("heading", { name: "App Integrations" })).toBeVisible();
  });

  await recorder.step("Open the Gmail skill panel", async () => {
    await page.getByText("Gmail", { exact: true }).click();
    await expect(page.getByText("Configuration", { exact: true })).toBeVisible();
  });

  await recorder.step("Verify the Gmail capability shows configured status and masked credentials", async () => {
    await expect(page.getByText("Configured", { exact: true })).toBeVisible();
    await expect(page.getByDisplayValue("AKfycb-gmail-deployment")).toBeVisible();
    await expect(page.getByDisplayValue("********")).toBeVisible();
    await expect(page.getByText(/configuration required/i)).toHaveCount(0);
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:gmail_capability_configured");
  await recorder.save(testInfo);
});
